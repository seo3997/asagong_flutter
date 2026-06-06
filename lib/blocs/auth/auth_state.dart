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
