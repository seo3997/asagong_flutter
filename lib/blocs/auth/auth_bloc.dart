import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../domain/service/app_service.dart';
import '../../domain/service/app_service_provider.dart';
import '../../data/models/login_response.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AppService appService;

  AuthBloc({AppService? appService}) 
    : appService = appService ?? AppServiceProvider.getService(),
      super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<SocialLoginSubmitted>(_onSocialLoginSubmitted);
    on<LoginSucceeded>(_onLoginSucceeded);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _setupFcm(LoginResponse response) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Topic subscriptions (similar to Android's nextPage)
      final memberCode = response.memberCode;
      if (memberCode != null && memberCode.isNotEmpty) {
        await messaging.subscribeToTopic(memberCode);
        
        // 지점별 토픽 구독 (지점 권한 ROLE_PROJ 인 경우)
        if (memberCode == 'ROLE_PROJ' && response.branchInfo != null) {
          final branchTopic = 'BRANCH_${response.branchInfo!.branchId}_ROLE_PROJ';
          await messaging.subscribeToTopic(branchTopic);
        }
      }

      // 2. Token Registration (similar to PushTokenUtil.ensureTokenRegistered)
      final userId = response.loginId ?? '';
      final userNo = response.loginIdx ?? '';
      if (userId.isNotEmpty && userNo.isNotEmpty) {
        final token = await messaging.getToken();
        if (token != null && token.isNotEmpty) {
          final deviceType = Platform.isIOS ? 'IOS' : 'ANDROID';
          
          final prefs = await SharedPreferences.getInstance();
          final lastToken = prefs.getString('last_fcm_token') ?? '';
          final lastUserId = prefs.getString('last_user_id') ?? '';

          if (lastToken != token || lastUserId != userId) {
            final success = await appService.registerPushToken(
              userNo: userNo,
              userId: userId,
              pushToken: token,
              deviceType: deviceType,
            );
            if (success) {
              await prefs.setString('last_fcm_token', token);
              await prefs.setString('last_user_id', userId);
            }
          }
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _clearFcm(String memberCode, String? branchId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      if (memberCode.isNotEmpty) {
        await messaging.unsubscribeFromTopic(memberCode);
      }
      if (memberCode == 'ROLE_PROJ' && branchId != null && branchId.isNotEmpty) {
        final branchTopic = 'BRANCH_${branchId}_ROLE_PROJ';
        await messaging.unsubscribeFromTopic(branchTopic);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_fcm_token');
      await prefs.remove('last_user_id');
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('saved_email');
      final password = prefs.getString('saved_password');

      if (email != null && email.isNotEmpty && password != null && password.isNotEmpty) {
        // Run auto-login check via AppService
        final response = await appService.login(
          email: email,
          password: password,
          loginCd: 'PWD',
          appVersion: '1.0.0',
        );

        if (response != null && response.resultCode == 200 && response.token != null) {
          // Update cached token and branch details
          await prefs.setString('saved_token', response.token!);
          await prefs.setString('saved_branch_name', response.branchInfo?.branchName ?? '');
          await prefs.setString('saved_branch_id', response.branchInfo?.branchId.toString() ?? '');
          await prefs.setString('saved_login_idx', response.loginIdx ?? '');
          await prefs.setString('saved_member_code', response.memberCode ?? '');
          await prefs.setString('saved_login_nm', response.loginNm ?? '');
          await prefs.setString('saved_user_id', response.loginId ?? email);
          await prefs.setString('saved_toss_client_key', response.branchInfo?.tossClientKey ?? '');
          await prefs.setInt('saved_base_shipping_fee', response.branchInfo?.baseShippingFee ?? 0);
          await prefs.setInt('saved_free_shipping_threshold', response.branchInfo?.freeShippingThreshold ?? 0);
          
          await _setupFcm(response);
          emit(AuthAuthenticated(response));
        } else {
          // If auto login fails, clear and emit unauthenticated
          await _clearSession(prefs);
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await appService.login(
        email: event.email,
        password: event.password,
        loginCd: 'PWD',
        appVersion: '1.0.0',
      );

      if (response != null && response.resultCode == 200 && response.token != null) {
        // Persist session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', event.email);
        await prefs.setString('saved_password', event.password);
        await prefs.setString('saved_token', response.token!);
        await prefs.setString('saved_member_code', response.memberCode ?? '');
        await prefs.setString('saved_login_nm', response.loginNm ?? '');
        await prefs.setString('saved_user_id', response.loginId ?? event.email);
        await prefs.setString('saved_branch_name', response.branchInfo?.branchName ?? '');
        await prefs.setString('saved_branch_id', response.branchInfo?.branchId.toString() ?? '');
        await prefs.setString('saved_login_idx', response.loginIdx ?? '');
        await prefs.setString('saved_toss_client_key', response.branchInfo?.tossClientKey ?? '');
        await prefs.setInt('saved_base_shipping_fee', response.branchInfo?.baseShippingFee ?? 0);
        await prefs.setInt('saved_free_shipping_threshold', response.branchInfo?.freeShippingThreshold ?? 0);

        await _setupFcm(response);
        emit(AuthAuthenticated(response));
      } else {
        String errMsg = _getErrorMessage(response?.resultCode ?? 500);
        emit(AuthFailure(errMsg));
      }
    } catch (e) {
      emit(AuthFailure('네트워크 오류가 발생했습니다: $e'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final memberCode = prefs.getString('saved_member_code') ?? '';
      final branchId = prefs.getString('saved_branch_id');
      
      await _clearFcm(memberCode, branchId);
      await _clearSession(prefs);
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
    await prefs.remove('saved_token');
    await prefs.remove('saved_user_id');
    await prefs.remove('saved_member_code');
    await prefs.remove('saved_login_nm');
    await prefs.remove('saved_branch_name');
    await prefs.remove('saved_branch_id');
    await prefs.remove('saved_login_idx');
    await prefs.remove('saved_toss_client_key');
    await prefs.remove('saved_base_shipping_fee');
    await prefs.remove('saved_free_shipping_threshold');
  }

  String _getErrorMessage(int resultCode) {
    switch (resultCode) {
      case 300:
      case 301:
        return '등록되지 않은 사용자입니다.';
      case 302:
        return '회원 권한 오류입니다.';
      case 303:
        return '소셜 연동 정보가 없습니다.';
      case 304:
        return '비밀번호가 일치하지 않습니다.';
      default:
        return '로그인에 실패했습니다. (코드: $resultCode)';
    }
  }

  Future<void> _onSocialLoginSubmitted(
    SocialLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await appService.authSocial(event.request);
      if (response != null) {
        if (response.resultCode == 200 && response.token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_email', response.loginId ?? '');
          await prefs.setString('saved_password', response.loginPwd);
          await prefs.setString('saved_token', response.token!);
          await prefs.setString('saved_member_code', response.memberCode ?? '');
          await prefs.setString('saved_login_nm', response.loginNm ?? '');
          await prefs.setString('saved_user_id', response.loginId ?? '');
          await prefs.setString('saved_branch_name', response.branchInfo?.branchName ?? '');
          await prefs.setString('saved_branch_id', response.branchInfo?.branchId.toString() ?? '');
          await prefs.setString('saved_login_idx', response.loginIdx ?? '');
          await prefs.setString('saved_toss_client_key', response.branchInfo?.tossClientKey ?? '');
          await prefs.setInt('saved_base_shipping_fee', response.branchInfo?.baseShippingFee ?? 0);
          await prefs.setInt('saved_free_shipping_threshold', response.branchInfo?.freeShippingThreshold ?? 0);

          await _setupFcm(response);
          emit(AuthAuthenticated(response));
        } else if (response.resultCode == 604) {
          emit(AuthOnboardingRequired(
            provider: event.request.provider,
            providerUserId: event.request.providerUserId,
            nickname: event.nickname,
            email: event.email,
            profileUrl: event.profileUrl,
          ));
        } else {
          String errMsg = _getErrorMessage(response.resultCode);
          emit(AuthFailure(errMsg));
        }
      } else {
        emit(AuthFailure('로그인 응답이 없습니다.'));
      }
    } catch (e) {
      emit(AuthFailure('네트워크 오류가 발생했습니다: $e'));
    }
  }

  Future<void> _onLoginSucceeded(
    LoginSucceeded event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = event.loginResponse;
      if (response.token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', event.email);
        await prefs.setString('saved_password', event.password);
        await prefs.setString('saved_token', response.token!);
        await prefs.setString('saved_member_code', response.memberCode ?? '');
        await prefs.setString('saved_login_nm', response.loginNm ?? '');
        await prefs.setString('saved_user_id', response.loginId ?? event.email);
        await prefs.setString('saved_branch_name', response.branchInfo?.branchName ?? '');
        await prefs.setString('saved_branch_id', response.branchInfo?.branchId.toString() ?? '');
        await prefs.setString('saved_login_idx', response.loginIdx ?? '');
        await prefs.setString('saved_toss_client_key', response.branchInfo?.tossClientKey ?? '');
        await prefs.setInt('saved_base_shipping_fee', response.branchInfo?.baseShippingFee ?? 0);
        await prefs.setInt('saved_free_shipping_threshold', response.branchInfo?.freeShippingThreshold ?? 0);

        await _setupFcm(response);
        emit(AuthAuthenticated(response));
      } else {
        emit(AuthFailure('토큰이 비어있습니다.'));
      }
    } catch (e) {
      emit(AuthFailure('세션 저장 중 오류가 발생했습니다: $e'));
    }
  }
}
