import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../domain/service/app_service.dart';
import '../../data/models/login_response.dart';
import '../../data/models/op_user_vo.dart';
import '../../data/models/link_social_request.dart';

class OnboardingScreen extends StatefulWidget {
  final String provider;
  final String providerUserId;
  final String? email;
  final String? nickname;
  final String? profileUrl;

  const OnboardingScreen({
    super.key,
    required this.provider,
    required this.providerUserId,
    this.email,
    this.nickname,
    this.profileUrl,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final TextEditingController _nameController;
  final _phoneMidController = TextEditingController();
  final _phoneLastController = TextEditingController();
  final _birthController = TextEditingController();

  String _phoneFirst = '010';
  int _gender = 1; // 1: Male, 2: Female
  List<BranchInfoVo> _branchList = [];
  BranchInfoVo? _selectedBranch;

  bool _isEmailChecked = false;
  bool _isLoading = false;
  bool _showRegistrationForm = false;
  String _emailStatusMessage = '';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
    _nameController = TextEditingController(text: widget.nickname ?? '');
    _fetchBranchList();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneMidController.dispose();
    _phoneLastController.dispose();
    _birthController.dispose();
    super.dispose();
  }

  Future<void> _fetchBranchList() async {
    setState(() => _isLoading = true);
    final appService = context.read<AppService>();
    try {
      final list = await appService.getBranchList();
      setState(() {
        _branchList = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkEmailDuplicate() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('이메일을 입력해 주세요.', Colors.redAccent);
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      _showSnackBar('올바른 이메일 형식이 아닙니다.', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);
    final appService = context.read<AppService>();

    try {
      final res = await appService.checkEmailDuplicate(email);

      if (res != null && res.result) {
        // Unique email -> launch Terms Agreement screen
        setState(() {
          _isLoading = false;
          _emailStatusMessage = '사용 가능한 이메일입니다. 회원가입 절차를 계속 진행합니다.';
        });

        // Open Terms Agreement
        if (mounted) {
          final agreed = await Navigator.of(context).pushNamed(
            '/termsAgree',
            arguments: {'fromOnboarding': true},
          );

          if (agreed == true) {
            setState(() {
              _isEmailChecked = true;
              _showRegistrationForm = true;
              _emailStatusMessage = '신규 가입입니다. 추가 정보를 입력해 주세요.';
            });
          }
        }
      } else {
        // Duplicate email exists -> automatically link accounts
        setState(() {
          _emailStatusMessage = '이미 가입된 이메일입니다. 소셜 계정 연결을 진행합니다.';
        });

        final userNo = res?.message ?? '';
        if (userNo.isEmpty) {
          setState(() => _isLoading = false);
          _showSnackBar('소셜 연동을 위한 회원정보를 식별할 수 없습니다.', Colors.redAccent);
          return;
        }

        final linkRes = await appService.linkSocial(
          LinkSocialRequest(
            userId: email,
            userNo: userNo,
            provider: widget.provider,
            providerUserId: widget.providerUserId,
          ),
        );
        setState(() => _isLoading = false);

        if (linkRes != null && linkRes.resultCode == 200) {
          _showSnackBar('소셜 계정 연결 및 로그인 성공!', Colors.green.shade600);
          if (mounted) {
            context.read<AuthBloc>().add(
              LoginSucceeded(
                loginResponse: linkRes,
                email: email,
                password: '',
              ),
            );
            Navigator.of(context).pushNamedAndRemoveUntil('/pubHome', (route) => false);
          }
        } else {
          _showSnackBar('소셜 계정 연결에 실패했습니다. (코드: ${linkRes?.resultCode})', Colors.redAccent);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('네트워크 오류가 발생했습니다: $e', Colors.redAccent);
    }
  }

  Future<void> _submitRegister() async {
    if (!_isEmailChecked) {
      _showSnackBar('이메일 중복 확인 및 약관 동의를 완료해 주세요.', Colors.redAccent);
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar('비밀번호가 일치하지 않습니다.', Colors.redAccent);
        return;
      }

      if (_selectedBranch == null) {
        _showSnackBar('지점을 선택해 주세요.', Colors.redAccent);
        return;
      }

      setState(() => _isLoading = true);
      final appService = context.read<AppService>();

      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final phone = '$_phoneFirst-${_phoneMidController.text.trim()}-${_phoneLastController.text.trim()}';
      final birth = _birthController.text.trim();

      final user = OpUserVo(
        userNm: name,
        email: email,
        userId: email,
        password: password,
        cttpc: phone,
        gender: _gender,
        userAge: '',
        birthDate: birth,
        areaCode: '',
        areaSeCodeS: '',
        areaSeCodeD: '',
        referrerId: '',
        userSttusCode: '10',
        memberCode: 'ROLE_PUB',
        provider: widget.provider,
        providerUserId: widget.providerUserId,
        branchId: _selectedBranch!.branchId.toString(),
      );

      try {
        final res = await appService.registerUser(user);
        setState(() => _isLoading = false);

        if (res != null && res.resultCode == 200) {
          _showSnackBar('추가 정보 입력 및 가입 성공!', Colors.green.shade600);
          if (mounted) {
            context.read<AuthBloc>().add(
              LoginSucceeded(
                loginResponse: res,
                email: email,
                password: password,
              ),
            );
            Navigator.of(context).pushNamedAndRemoveUntil('/pubHome', (route) => false);
          }
        } else {
          _showSnackBar('가입에 실패했습니다.', Colors.redAccent);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showSnackBar('통신 오류가 발생했습니다: $e', Colors.redAccent);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _onBirthChanged(String val) {
    String clean = val.replaceAll(RegExp(r'\D'), '');
    if (clean.length > 8) {
      clean = clean.substring(0, 8);
    }
    String formatted = '';
    if (clean.length > 4) {
      formatted += '${clean.substring(0, 4)}-';
      if (clean.length > 6) {
        formatted += '${clean.substring(4, 6)}-${clean.substring(6)}';
      } else {
        formatted += clean.substring(4);
      }
    } else {
      formatted = clean;
    }
    _birthController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        '추가정보등록',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1.5,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email duplication check is always required first
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _emailController,
                                    hintText: '이메일 주소',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: !_showRegistrationForm,
                                    onChanged: (val) {
                                      setState(() {
                                        _isEmailChecked = false;
                                      });
                                    },
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return '이메일을 입력해 주세요.';
                                      }
                                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(val.trim())) {
                                        return '올바른 이메일 형식이 아닙니다.';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                if (!_showRegistrationForm) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _checkEmailDuplicate,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF9100),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Text('연결/가입확인'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (_emailStatusMessage.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _emailStatusMessage,
                                style: const TextStyle(color: Color(0xFFFF9100), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 16),

                            // If email is unique and terms are agreed, show the rest of signup details
                            if (_showRegistrationForm) ...[
                              // Password
                              _buildTextField(
                                controller: _passwordController,
                                hintText: '비밀번호 (최소 4자)',
                                icon: Icons.lock_outlined,
                                obscureText: true,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return '비밀번호를 입력해 주세요.';
                                  }
                                  if (val.length < 4) {
                                    return '비밀번호는 최소 4자 이상이어야 합니다.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password Confirm
                              _buildTextField(
                                controller: _confirmPasswordController,
                                hintText: '비밀번호 확인',
                                icon: Icons.lock_clock_outlined,
                                obscureText: true,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return '비밀번호 확인을 입력해 주세요.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Name
                              _buildTextField(
                                controller: _nameController,
                                hintText: '이름',
                                icon: Icons.person_outline,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return '이름을 입력해 주세요.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Phone
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _phoneFirst,
                                        dropdownColor: const Color(0xFF2E1A47),
                                        style: const TextStyle(color: Colors.white),
                                        iconEnabledColor: Colors.white,
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _phoneFirst = newValue;
                                            });
                                          }
                                        },
                                        items: <String>['010', '011', '016', '017', '018', '019']
                                            .map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _phoneMidController,
                                      hintText: '중간번호',
                                      keyboardType: TextInputType.number,
                                      validator: (val) => (val == null || val.trim().isEmpty) ? '' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _phoneLastController,
                                      hintText: '끝번호',
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.number,
                                      validator: (val) => (val == null || val.trim().isEmpty) ? '' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Birth Date (YYYY-MM-DD)
                              _buildTextField(
                                controller: _birthController,
                                hintText: '생년월일 (YYYY-MM-DD)',
                                icon: Icons.calendar_month_outlined,
                                keyboardType: TextInputType.datetime,
                                onChanged: _onBirthChanged,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return '생년월일을 입력해 주세요.';
                                  }
                                  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(val.trim())) {
                                    return 'YYYY-MM-DD 형식으로 입력하세요.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Gender
                              const Text(
                                '성별',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<int>(
                                      title: const Text('남자', style: TextStyle(color: Colors.white)),
                                      value: 1,
                                      groupValue: _gender,
                                      activeColor: const Color(0xFFFF9100),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _gender = val);
                                      },
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<int>(
                                      title: const Text('여자', style: TextStyle(color: Colors.white)),
                                      value: 2,
                                      groupValue: _gender,
                                      activeColor: const Color(0xFFFF9100),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _gender = val);
                                      },
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Branch List Dropdown
                              const Text(
                                '지점 선택',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<BranchInfoVo>(
                                    hint: const Text('지점을 선택해 주세요.', style: TextStyle(color: Colors.white38)),
                                    value: _selectedBranch,
                                    dropdownColor: const Color(0xFF2E1A47),
                                    style: const TextStyle(color: Colors.white),
                                    iconEnabledColor: Colors.white,
                                    isExpanded: true,
                                    onChanged: (BranchInfoVo? newValue) {
                                      setState(() {
                                        _selectedBranch = newValue;
                                      });
                                    },
                                    items: _branchList.map<DropdownMenuItem<BranchInfoVo>>((BranchInfoVo value) {
                                      return DropdownMenuItem<BranchInfoVo>(
                                        value: value,
                                        child: Text(value.branchName ?? ''),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Submit Button
                              ElevatedButton(
                                onPressed: _submitRegister,
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
                                  '등록 완료',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF9100)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(color: enabled ? Colors.white : Colors.white30),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: icon != null ? Icon(icon, color: enabled ? Colors.white60 : Colors.white24) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.03)),
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
