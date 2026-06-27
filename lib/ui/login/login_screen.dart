import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/constants.dart';
import '../../data/models/social_auth_request.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: Constants.appTestYn == 'Y' ? 'sel1@gmail.com' : '',
    );
    _passwordController = TextEditingController(
      text: Constants.appTestYn == 'Y' ? '1234' : '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        LoginSubmitted(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  Future<void> _startKakaoLogin() async {
    try {
      bool isInstalled = await isKakaoTalkInstalled();
      OAuthToken token;
      if (isInstalled) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      // Fetch user profile
      User user = await UserApi.instance.me();
      final kakaoUserId = user.id.toString();
      final nickname = user.kakaoAccount?.profile?.nickname;
      final email = user.kakaoAccount?.email;
      final profileUrl = user.kakaoAccount?.profile?.profileImageUrl;

      if (kakaoUserId.isEmpty) {
        _showErrorSnackBar('카카오 ID를 가져오지 못했습니다.');
        return;
      }

      // Submit social login
      if (mounted) {
        context.read<AuthBloc>().add(
          SocialLoginSubmitted(
            request: SocialAuthRequest(
              provider: 'KAKAO',
              providerUserId: kakaoUserId,
              accessToken: token.accessToken,
            ),
            nickname: nickname,
            email: email,
            profileUrl: profileUrl,
          ),
        );
      }
    } catch (e) {
      debugPrint('Kakao login error: $e');
      _showErrorSnackBar('카카오 로그인 중 오류가 발생했습니다: $e');
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${state.loginResponse.loginNm ?? '사용자'}님 환영합니다!',
                ),
                backgroundColor: Colors.green.shade600,
              ),
            );
            final role = state.loginResponse.memberCode;
            if (role == 'ROLE_SELL' || role == 'ROLE_PROJ') {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            } else {
              Navigator.of(context).pushReplacementNamed('/pubHome');
            }
          } else if (state is AuthOnboardingRequired) {
            Navigator.of(context).pushNamed(
              '/onboarding',
              arguments: {
                'provider': state.provider,
                'providerUserId': state.providerUserId,
                'email': state.email,
                'nickname': state.nickname,
                'profileUrl': state.profileUrl,
              },
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade600,
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Beautiful Gradient Background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6A1B9A), // Deep Purple
                      Color(0xFF4A148C), // Dark Purple
                      Color(0xFF2E1A47), // Deep Violet-Black
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Soft Glowing Background Circles
              Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -100,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE040FB).withOpacity(0.08),
                  ),
                ),
              ),
              // Main content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Logo/Icon & Header
                        const Icon(
                          Icons.eco_rounded,
                          size: 72,
                          color: Color(0xFFFF9100), // Vibrant Carrot Orange
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'asagong',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '통합 아사공 플랫폼',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Glassmorphism-style Form Card
                        Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email Input
                                _buildTextField(
                                  controller: _emailController,
                                  hintText: '이메일 주소',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return '이메일을 입력해 주세요.';
                                    }
                                    if (!RegExp(
                                      r'^[^@]+@[^@]+\.[^@]+$',
                                    ).hasMatch(val.trim())) {
                                      return '올바른 이메일 형식이 아닙니다.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password Input
                                _buildTextField(
                                  controller: _passwordController,
                                  hintText: '비밀번호',
                                  icon: Icons.lock_outlined,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white60,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return '비밀번호를 입력해 주세요.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Login Button
                                ElevatedButton(
                                  onPressed: state is AuthLoading
                                      ? null
                                      : _submitLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF9100),
                                    foregroundColor: Colors.white,
                                    shadowColor: const Color(
                                      0xFFFF9100,
                                    ).withOpacity(0.5),
                                    elevation: 8,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    '로그인',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Social Kakao Login Button
                        OutlinedButton.icon(
                          onPressed: state is AuthLoading ? null : _startKakaoLogin,
                          icon: const Icon(
                            Icons.chat_bubble,
                            color: Color(0xFF3E2723),
                            size: 18,
                          ),
                          label: const Text(
                            '카카오 계정으로 로그인',
                            style: TextStyle(
                              color: Color(0xFF3E2723),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEE500),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bottom Actions (Find Account, Register)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/findEmailPwd');
                              },
                              child: Text(
                                '이메일/비밀번호 찾기',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ),
                            Text(
                              '|',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/termsAgree');
                              },
                              child: const Text(
                                '회원가입',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Loading overlay
              if (state is AuthLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF9100)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white60),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF9100), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
