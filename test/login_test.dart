import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asagong_flutter/data/models/login_response.dart';
import 'package:asagong_flutter/data/models/op_user_vo.dart';
import 'package:asagong_flutter/blocs/auth/auth_bloc.dart';
import 'package:asagong_flutter/blocs/auth/auth_event.dart';
import 'package:asagong_flutter/blocs/auth/auth_state.dart';
import 'package:asagong_flutter/domain/service/app_service.dart';
import 'package:asagong_flutter/data/repository/app_repository.dart';
import 'package:asagong_flutter/data/api/api_service.dart';

// Simple mock service for test
class MockAppService extends AppService {
  final LoginResponse? Function() onLogin;

  MockAppService({required this.onLogin})
      : super(repository: AppRepository(apiService: ApiService()));

  @override
  Future<LoginResponse?> login({
    required String email,
    required String password,
    required String loginCd,
    String regId = '',
    required String appVersion,
    String providerUserId = '',
  }) async {
    return onLogin();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Login Model Tests', () {
    test('LoginResponse parsing', () {
      final json = {
        'resultCode': 200,
        'token': 'mock-jwt-token',
        'login_idx': '10',
        'member_code': 'ROLE_SELL',
        'login_nm': 'Test User',
      };
      final response = LoginResponse.fromJson(json);
      expect(response.resultCode, 200);
      expect(response.token, 'mock-jwt-token');
      expect(response.loginNm, 'Test User');
      expect(response.memberCode, 'ROLE_SELL');
    });

    test('OpUserVo parsing', () {
      final json = {
        'userNo': 42,
        'userId': 'carrots_seller',
        'userNm': 'Farm Owner',
        'email': 'farm@carrots.com',
      };
      final user = OpUserVo.fromJson(json);
      expect(user.userNo, 42);
      expect(user.userId, 'carrots_seller');
      expect(user.userNm, 'Farm Owner');
      expect(user.email, 'farm@carrots.com');
    });
  });

  group('AuthBloc Tests', () {
    test('Successful email/password login emits AuthLoading and AuthAuthenticated and persists session', () async {
      final mockService = MockAppService(
        onLogin: () => const LoginResponse(
          resultCode: 200,
          token: 'success-token',
          memberCode: 'ROLE_SELL',
          loginNm: 'Carrot Seller',
        ),
      );

      final bloc = AuthBloc(appService: mockService);

      expect(bloc.state, AuthInitial());

      final expectedStates = [
        AuthLoading(),
        const AuthAuthenticated(LoginResponse(
          resultCode: 200,
          token: 'success-token',
          memberCode: 'ROLE_SELL',
          loginNm: 'Carrot Seller',
        )),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const LoginSubmitted(
        email: 'test@carrots.com',
        password: 'password123',
      ));

      // Wait a moment and check if values were saved in mock shared preferences
      await Future.delayed(const Duration(milliseconds: 100));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('saved_email'), 'test@carrots.com');
      expect(prefs.getString('saved_token'), 'success-token');
    });

    test('Wrong password login emits AuthLoading and AuthFailure', () async {
      final mockService = MockAppService(
        onLogin: () => const LoginResponse(
          resultCode: 304, // RESULT_PWD_ERR
        ),
      );

      final bloc = AuthBloc(appService: mockService);

      final expectedStates = [
        AuthLoading(),
        const AuthFailure('비밀번호가 일치하지 않습니다.'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const LoginSubmitted(
        email: 'test@carrots.com',
        password: 'wrongpassword',
      ));
    });

    test('AuthCheckRequested with saved credentials runs successful auto-login', () async {
      final mockService = MockAppService(
        onLogin: () => const LoginResponse(
          resultCode: 200,
          token: 'auto-login-token',
          memberCode: 'ROLE_SELL',
          loginNm: 'Carrot Seller',
        ),
      );

      // Pre-save credentials
      SharedPreferences.setMockInitialValues({
        'saved_email': 'auto@carrots.com',
        'saved_password': 'autopassword',
      });

      final bloc = AuthBloc(appService: mockService);

      final expectedStates = [
        AuthLoading(),
        const AuthAuthenticated(LoginResponse(
          resultCode: 200,
          token: 'auto-login-token',
          memberCode: 'ROLE_SELL',
          loginNm: 'Carrot Seller',
        )),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(AuthCheckRequested());
    });

    test('AuthCheckRequested with empty storage emits AuthUnauthenticated', () async {
      final mockService = MockAppService(
        onLogin: () => const LoginResponse(resultCode: 200),
      );

      final bloc = AuthBloc(appService: mockService);

      final expectedStates = [
        AuthLoading(),
        AuthUnauthenticated(),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(AuthCheckRequested());
    });
  });
}
