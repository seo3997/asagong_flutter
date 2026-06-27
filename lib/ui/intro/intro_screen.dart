import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../domain/service/app_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Trigger app version check and then auto login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersionAndAutoLogin();
    });
  }

  Future<void> _checkVersionAndAutoLogin() async {
    final appService = context.read<AppService>();
    final osType = Theme.of(context).platform == TargetPlatform.iOS ? 'FLUTTER_IOS' : 'FLUTTER_ANDROID';
    final currentVersion = Constants.appVersion;

    try {
      final res = await appService.checkAppVersion(osType: osType, appVersion: currentVersion);
      if (res != null && res['success'] == true) {
        final updateType = res['updateType'] as String? ?? 'NONE';
        final storeUrl = res['storeUrl'] as String? ?? '';
        final updateMsg = res['updateMsg'] as String? ?? '새로운 버전이 출시되었습니다.';

        if (updateType == 'FORCE') {
          // Block navigation and show force update dialog
          if (mounted) {
            _showUpdateDialog(updateMsg, storeUrl, isForce: true);
          }
          return; // Stop here, do not trigger auto login
        } else if (updateType == 'OPTIONAL') {
          // Show optional update dialog, then trigger auto login on 'Later'
          if (mounted) {
            final proceed = await _showUpdateDialog(updateMsg, storeUrl, isForce: false);
            if (!proceed) return; // user clicked Update, which opened URL
          }
        }
      }
    } catch (e) {
      debugPrint("Version check failed, continuing: $e");
    }

    if (mounted) {
      context.read<AuthBloc>().add(AuthCheckRequested());
    }
  }

  Future<bool> _showUpdateDialog(String message, String storeUrl, {required bool isForce}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !isForce,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E1A47),
          title: const Text(
            '업데이트 알림',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            if (!isForce)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  '나중에',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
              ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext, false);
                if (storeUrl.isNotEmpty) {
                  final uri = Uri.parse(storeUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9100),
                foregroundColor: Colors.white,
              ),
              child: const Text('업데이트'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Delay navigation slightly so the splash screen feels smooth
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!mounted) return;
            if (state is AuthAuthenticated) {
              final role = state.loginResponse.memberCode;
              if (role == 'ROLE_SELL' || role == 'ROLE_PROJ') {
                Navigator.of(context).pushReplacementNamed('/dashboard');
              } else {
                Navigator.of(context).pushReplacementNamed('/pubHome');
              }
            } else if (state is AuthUnauthenticated || state is AuthFailure) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          });
        },
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/asagong_intro.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(
                        color: const Color(0xFFFF9100).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 80,
                      color: Color(0xFFFF9100),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'asagong',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2E1A47),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '로딩 중입니다...',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF2E1A47).withOpacity(0.7),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9100)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
