import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    on<LogoutRequested>(_onLogoutRequested);
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
          await prefs.setString('saved_toss_client_key', response.branchInfo?.tossClientKey ?? '');
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
        await prefs.setString('saved_branch_name', response.branchInfo?.branchName ?? '');
        await prefs.setString('saved_branch_id', response.branchInfo?.branchId.toString() ?? '');
        await prefs.setString('saved_login_idx', response.loginIdx ?? '');
        await prefs.setString('saved_toss_client_key', response.branchInfo?.tossClientKey ?? '');

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
    await prefs.remove('saved_member_code');
    await prefs.remove('saved_login_nm');
    await prefs.remove('saved_branch_name');
    await prefs.remove('saved_branch_id');
    await prefs.remove('saved_login_idx');
    await prefs.remove('saved_toss_client_key');
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
}
