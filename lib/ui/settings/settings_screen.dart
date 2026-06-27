import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../domain/service/app_service.dart';
import '../../data/models/op_user_vo.dart';
import '../../data/models/password_change_request.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _telnoController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSavingInfo = false;
  bool _isChangingPassword = false;
  bool _showPasswordChangeLayout = false;
  bool _pushEnabled = true;
  
  OpUserVo? _userInfo;
  String? _errorMsg;
  String? _localProfileImagePath;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _telnoController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('saved_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMsg = '로그인 토큰 정보가 없습니다. 다시 로그인해 주세요.';
        });
        return;
      }

      final appService = RepositoryProvider.of<AppService>(context);
      final info = await appService.getUserInfo(token);

      final profilePath = prefs.getString('local_profile_path');
      final pushEnabled = prefs.getBool('push_enabled') ?? true;

      if (mounted) {
        setState(() {
          _userInfo = info;
          _isLoading = false;
          _localProfileImagePath = profilePath;
          _pushEnabled = pushEnabled;
          if (info != null) {
            _nameController.text = info.userNm;
            _telnoController.text = info.cttpc;
          } else {
            _errorMsg = '사용자 정보를 불러올 수 없습니다.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = '오류가 발생했습니다: $e';
        });
      }
    }
  }

  Future<void> _saveUserInfo() async {
    final name = _nameController.text.trim();
    final telno = _telnoController.text.trim();

    if (name.isEmpty || telno.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 정보를 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isSavingInfo = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('saved_token');
      if (token == null || token.isEmpty) {
        throw Exception('토큰 정보가 없습니다.');
      }

      final appService = RepositoryProvider.of<AppService>(context);
      final updatedUser = OpUserVo(
        userNo: _userInfo!.userNo,
        userId: _userInfo!.userId,
        userNm: name,
        cttpc: telno,
        areaCode: _userInfo!.areaCode,
        areaSeCodeS: _userInfo!.areaSeCodeS,
        areaCodeNm: _userInfo!.areaCodeNm,
        areaSeCodeSNm: _userInfo!.areaSeCodeSNm,
        email: _userInfo!.email,
        memberCode: _userInfo!.memberCode,
      );

      final response = await appService.updateUser(token, updatedUser);
      if (response != null && response.result) {
        setState(() {
          _userInfo = updatedUser;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('정보가 수정되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?.message ?? '수정에 실패했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수정 중 오류 발생: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingInfo = false;
        });
      }
    }
  }

  Future<void> _executePasswordChange() async {
    final currentPw = _currentPasswordController.text;
    final newPw = _newPasswordController.text;
    final confirmPw = _confirmPasswordController.text;

    if (currentPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    if (newPw != confirmPw) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('새 비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('saved_token');
      if (token == null || token.isEmpty) {
        throw Exception('토큰 정보가 없습니다.');
      }

      final appService = RepositoryProvider.of<AppService>(context);
      final request = PasswordChangeRequest(
        currentPassword: currentPw,
        newPassword: newPw,
        confirmPassword: confirmPw,
      );

      final response = await appService.changePassword(token, request);
      if (response != null && response.result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message.isNotEmpty ? response.message : '비밀번호가 변경되었습니다.')),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _showPasswordChangeLayout = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?.message ?? '비밀번호 변경에 실패했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호 변경 중 오류 발생: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  Future<void> _togglePushNotification(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_enabled', enabled);
      setState(() {
        _pushEnabled = enabled;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(enabled ? '푸시 알림 수신이 활성화되었습니다.' : '푸시 알림 수신이 비활성화되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('설정 저장 중 오류 발생: $e')),
      );
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final localFile = File('${directory.path}/profile_image.jpg');
        await File(image.path).copy(localFile.path);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('local_profile_path', localFile.path);

        setState(() {
          _localProfileImagePath = localFile.path;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필 이미지가 변경되었습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 로드 중 오류 발생: $e')),
      );
    }
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E1A47),
          title: const Text(
            '로그아웃',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '정말 로그아웃 하시겠습니까?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                '취소',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                context.read<AuthBloc>().add(LogoutRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9100),
                foregroundColor: Colors.white,
              ),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      builder: (context, state) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFF1E1E2C),
          drawer: const AppDrawer(currentRoute: '/settings'),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2E1A47),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            title: const Text(
              '설정',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF9100),
                      ),
                    )
                  : SafeArea(
                      top: false,
                      bottom: true,
                      child: RefreshIndicator(
                        color: const Color(0xFFFF9100),
                        onRefresh: _loadUserInfo,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_errorMsg != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    _errorMsg!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              
                              // Profile Glassmorphism Card
                              if (_userInfo != null) _buildProfileCard(_userInfo!),
                              
                              const SizedBox(height: 16),

                              // Push Notifications Switch Tile
                              _buildPushSettingsTile(),

                              const SizedBox(height: 16),

                              // Collapsible Password Change Layout
                              _buildPasswordChangeCollapse(),

                              const SizedBox(height: 32),
                              
                              // Logout Button
                              ElevatedButton.icon(
                                onPressed: _showLogoutConfirmDialog,
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text(
                                  '로그아웃',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.06),
                                  foregroundColor: Colors.redAccent,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              if (state is AuthLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF9100),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(OpUserVo user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(
                        color: const Color(0xFFFF9100).withOpacity(0.6),
                        width: 3,
                      ),
                      image: _localProfileImagePath != null
                          ? DecorationImage(
                              image: FileImage(File(_localProfileImagePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _localProfileImagePath == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Color(0xFFFF9100),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9100),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white12, thickness: 1),
          const SizedBox(height: 16),
          
          _buildInfoRow('아이디', user.userId),
          _buildInfoRow(
            '주소',
            '${user.areaCodeNm} ${user.areaSeCodeSNm}'.trim().isEmpty
                ? '-'
                : '${user.areaCodeNm} ${user.areaSeCodeSNm}'.trim(),
          ),
          const SizedBox(height: 8),

          _buildEditableField(
            controller: _nameController,
            label: '이름',
            icon: Icons.person_outline,
          ),
          _buildEditableField(
            controller: _telnoController,
            label: '연락처',
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _isSavingInfo ? null : _saveUserInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9100),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSavingInfo
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    '정보 저장',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPushSettingsTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
      ),
      child: SwitchListTile(
        activeColor: const Color(0xFFFF9100),
        inactiveTrackColor: Colors.white.withOpacity(0.1),
        title: const Text(
          '푸시 알림 수신 동의',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '주문 상태 업데이트 알림을 수신합니다.',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        value: _pushEnabled,
        onChanged: _togglePushNotification,
      ),
    );
  }

  Widget _buildPasswordChangeCollapse() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: const Text(
              '비밀번호 변경',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            trailing: Icon(
              _showPasswordChangeLayout ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
            onTap: () {
              setState(() {
                _showPasswordChangeLayout = !_showPasswordChangeLayout;
              });
            },
          ),
          if (_showPasswordChangeLayout)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(color: Colors.white12, thickness: 1),
                  const SizedBox(height: 12),
                  _buildEditableField(
                    controller: _currentPasswordController,
                    label: '현재 비밀번호',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  _buildEditableField(
                    controller: _newPasswordController,
                    label: '새 비밀번호',
                    icon: Icons.lock_reset,
                    obscureText: true,
                  ),
                  _buildEditableField(
                    controller: _confirmPasswordController,
                    label: '새 비밀번호 확인',
                    icon: Icons.check_circle_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isChangingPassword ? null : _executePasswordChange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9100),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isChangingPassword
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '비밀번호 변경 실행',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFFFF9100), size: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF9100), width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.03),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
