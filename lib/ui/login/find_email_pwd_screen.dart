import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/service/app_service.dart';

class FindEmailPwdScreen extends StatefulWidget {
  const FindEmailPwdScreen({super.key});

  @override
  State<FindEmailPwdScreen> createState() => _FindEmailPwdScreenState();
}

class _FindEmailPwdScreenState extends State<FindEmailPwdScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailFormKey = GlobalKey<FormState>();
  final _pwdFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneMidController = TextEditingController();
  final _phoneLastController = TextEditingController();
  final _emailController = TextEditingController();
  String _phoneFirst = '010';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneMidController.dispose();
    _phoneLastController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFindEmail() async {
    if (_emailFormKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final appService = context.read<AppService>();
      final name = _nameController.text.trim();
      final phone = '$_phoneFirst-${_phoneMidController.text.trim()}-${_phoneLastController.text.trim()}';

      try {
        final res = await appService.findEmail(name, phone);
        setState(() => _isLoading = false);

        if (res != null && res.resultString.isNotEmpty && res.resultString != "601" && res.resultString != "500") {
          _showResultDialog(
            title: '이메일 찾기 성공',
            message: '입력하신 정보로 가입된 이메일은 다음과 같습니다.\n\n${res.resultString}',
          );
        } else {
          _showResultDialog(
            title: '이메일 찾기 실패',
            message: '일치하는 이메일 정보를 찾을 수 없습니다.',
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showResultDialog(
          title: '오류',
          message: '통신 오류가 발생했습니다. 다시 시도해 주세요.',
        );
      }
    }
  }

  Future<void> _submitFindPwd() async {
    if (_pwdFormKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final appService = context.read<AppService>();
      final email = _emailController.text.trim();

      try {
        final res = await appService.findPassword(email);
        setState(() => _isLoading = false);

        // API 200: 비밀번호 재설정 메일 발송 성공
        if (res != null && res.resultString == "200") {
          _showResultDialog(
            title: '비밀번호 재설정',
            message: '요청하신 이메일($email)로 비밀번호 재설정 메일이 발송되었습니다. 재설정 후 로그인해 주세요.',
            onConfirm: () => Navigator.of(context).pop(),
          );
        } else {
          _showResultDialog(
            title: '비밀번호 재설정 실패',
            message: '일치하는 회원 정보가 없거나 재설정 메일을 발송할 수 없습니다.',
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showResultDialog(
          title: '오류',
          message: '통신 오류가 발생했습니다. 다시 시도해 주세요.',
        );
      }
    }
  }

  void _showResultDialog({required String title, required String message, VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E1A47),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onConfirm != null) onConfirm();
            },
            child: const Text(
              '확인',
              style: TextStyle(color: Color(0xFFFF9100), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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
                // Top Custom App Bar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        '이메일/비밀번호 찾기',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFFF9100),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: '이메일 찾기'),
                    Tab(text: '비밀번호 찾기'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFindEmailTab(),
                      _buildFindPwdTab(),
                    ],
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

  Widget _buildFindEmailTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'E-mail 주소를 찾기위해 아래 항목을 입력해 주세요.',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.09),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Form(
              key: _emailFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    hintText: '이름',
                    icon: Icons.person_outline,
                    validator: (val) => (val == null || val.trim().isEmpty) ? '이름을 입력해 주세요.' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Text(
                          '010',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                          keyboardType: TextInputType.number,
                          validator: (val) => (val == null || val.trim().isEmpty) ? '' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitFindEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9100),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindPwdTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            '비밀번호를 재설정하기 위해 이메일을 입력해 주세요.',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.09),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Form(
              key: _pwdFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: _emailController,
                    hintText: '이메일 주소',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitFindPwd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9100),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white60) : null,
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
