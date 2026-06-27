import 'package:flutter/material.dart';
import '../../core/constants.dart';

class TermsAgreeScreen extends StatefulWidget {
  final bool fromOnboarding;

  const TermsAgreeScreen({
    super.key,
    this.fromOnboarding = false,
  });

  @override
  State<TermsAgreeScreen> createState() => _TermsAgreeScreenState();
}

class _TermsAgreeScreenState extends State<TermsAgreeScreen> {
  bool _agreeAll = false;
  bool _agree1 = false;
  bool _agree2 = false;

  void _updateAgreeAll(bool? checked) {
    if (checked != null) {
      setState(() {
        _agreeAll = checked;
        _agree1 = checked;
        _agree2 = checked;
      });
    }
  }

  void _updateAgreement() {
    setState(() {
      _agreeAll = _agree1 && _agree2;
    });
  }

  void _openWebView(String title, String urlSuffix) {
    final fullUrl = '${Constants.baseUrl}/$urlSuffix';
    Navigator.of(context).pushNamed('/webview', arguments: {
      'title': title,
      'url': fullUrl,
    });
  }

  void _submitAgreement() {
    if (_agree1 && _agree2) {
      if (widget.fromOnboarding) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacementNamed('/membership');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 필수 약관에 동의하셔야 가입이 진행됩니다.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if arguments were passed through route settings (when opened via named route)
    final routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isFromOnboarding = routeArgs?['fromOnboarding'] as bool? ?? widget.fromOnboarding;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6A1B9A),
                  Color(0xFF4A148C),
                  Color(0xFF2E1A47),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        '약관동의',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '아사공 플랫폼 이용을 위해\n약관에 동의해 주세요.',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Glassmorphic Card
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Agree All
                              CheckboxListTile(
                                value: _agreeAll,
                                onChanged: _updateAgreeAll,
                                activeColor: const Color(0xFFFF9100),
                                checkColor: Colors.white,
                                side: const BorderSide(color: Colors.white70, width: 1.5),
                                title: const Text(
                                  '전체 동의',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  '이용약관, 개인정보 수집 및 이용에 모두 동의합니다.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                              const Divider(color: Colors.white12, height: 24),

                              // Agree 1
                              Row(
                                children: [
                                  Checkbox(
                                    value: _agree1,
                                    onChanged: (val) {
                                      setState(() => _agree1 = val ?? false);
                                      _updateAgreement();
                                    },
                                    activeColor: const Color(0xFFFF9100),
                                    checkColor: Colors.white,
                                    side: const BorderSide(color: Colors.white70, width: 1.5),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _openWebView('이용약관', 'link/join_terms1.do'),
                                      child: const Text(
                                        '이용약관 동의 (필수)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 16),
                                    onPressed: () => _openWebView('이용약관', 'link/join_terms1.do'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Agree 2
                              Row(
                                children: [
                                  Checkbox(
                                    value: _agree2,
                                    onChanged: (val) {
                                      setState(() => _agree2 = val ?? false);
                                      _updateAgreement();
                                    },
                                    activeColor: const Color(0xFFFF9100),
                                    checkColor: Colors.white,
                                    side: const BorderSide(color: Colors.white70, width: 1.5),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _openWebView(
                                        '개인정보 수집 및 이용동의',
                                        'link/join_terms2.do',
                                      ),
                                      child: const Text(
                                        '개인정보 수집 및 이용 동의 (필수)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 16),
                                    onPressed: () => _openWebView(
                                      '개인정보 수집 및 이용동의',
                                      'link/join_terms2.do',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  '취소',
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submitAgreement,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF9100),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: const Color(0xFFFF9100).withOpacity(0.4),
                                ),
                                child: const Text(
                                  '확인',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
