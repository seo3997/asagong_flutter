import 'package:equatable/equatable.dart';
import '../../data/models/login_response.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final LoginResponse loginResponse;

  const AuthAuthenticated(this.loginResponse);

  @override
  List<Object?> get props => [loginResponse];
}

class AuthUnauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthOnboardingRequired extends AuthState {
  final String provider;
  final String providerUserId;
  final String? nickname;
  final String? email;
  final String? profileUrl;

  const AuthOnboardingRequired({
    required this.provider,
    required this.providerUserId,
    this.nickname,
    this.email,
    this.profileUrl,
  });

  @override
  List<Object?> get props => [provider, providerUserId, nickname, email, profileUrl];
}
