import 'package:equatable/equatable.dart';
import '../../data/models/social_auth_request.dart';
import '../../data/models/login_response.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class SocialLoginSubmitted extends AuthEvent {
  final SocialAuthRequest request;
  final String? nickname;
  final String? email;
  final String? profileUrl;

  const SocialLoginSubmitted({
    required this.request,
    this.nickname,
    this.email,
    this.profileUrl,
  });

  @override
  List<Object?> get props => [request, nickname, email, profileUrl];
}

class LoginSucceeded extends AuthEvent {
  final LoginResponse loginResponse;
  final String email;
  final String password;

  const LoginSucceeded({
    required this.loginResponse,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [loginResponse, email, password];
}

class LogoutRequested extends AuthEvent {}
