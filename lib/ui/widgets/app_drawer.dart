import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

class AppDrawer extends StatefulWidget {
  final String currentRoute;
  const AppDrawer({super.key, required this.currentRoute});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _userName = '사용자';
  String _userId = '';
  String _memberCode = '';
  String _loginIdx = '';
  String? _localProfileImagePath;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('saved_login_nm') ?? '사용자';
      _userId = prefs.getString('saved_email') ?? '';
      _memberCode = prefs.getString('saved_member_code') ?? '';
      _loginIdx = prefs.getString('saved_login_idx') ?? '';
      _localProfileImagePath = prefs.getString('local_profile_path');
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasDashboard = _memberCode == Constants.roleSell || _memberCode == Constants.roleProj;

    return Drawer(
      backgroundColor: const Color(0xFF1E1E2C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header
          _buildDrawerHeader(),
          
          // Drawer Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (hasDashboard)
                  _buildDrawerItem(
                    icon: Icons.dashboard_outlined,
                    title: '대시보드',
                    route: '/dashboard',
                  ),
                _buildDrawerItem(
                  icon: Icons.shopping_basket_outlined,
                  title: '상품리스트',
                  route: '/pubHome',
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: '설정',
                  route: '/settings',
                ),
                const Divider(color: Colors.white12, height: 24, thickness: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '고객지원',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.35),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _buildWebItem(
                  icon: Icons.notifications_none_outlined,
                  title: '공지사항',
                  urlKey: 'front/board/selectPageListBoard.do?sch_bbs_se_code_m=10',
                ),
                _buildWebItem(
                  icon: Icons.help_outline_rounded,
                  title: '문의하기',
                  urlKey: 'front/board/selectPageListBoard.do?sch_bbs_se_code_m=20',
                ),
                _buildWebItem(
                  icon: Icons.policy_outlined,
                  title: '약관 및 정책',
                  urlKey: 'link/join_terms.do',
                ),
              ],
            ),
          ),
          
          // Drawer Footer / Version
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'asagong v1.0.0',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3)),
                ),
                Text(
                  _getRoleLabel(_memberCode),
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFFFF9100).withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2E1A47), // Deep Violet-Black
            Color(0xFF4A148C), // Dark Purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border: Border.all(
                color: const Color(0xFFFF9100).withOpacity(0.3),
                width: 1.5,
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
                    size: 28,
                    color: Color(0xFFFF9100),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _userId,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isSelected = widget.currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: Colors.white.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFFFF9100) : Colors.white60,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Close Drawer
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }

  Widget _buildWebItem({
    required IconData icon,
    required String title,
    required String urlKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          icon,
          color: Colors.white60,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Close Drawer
          String fullUrl = '${Constants.baseUrl}/$urlKey';
          if (title == '공지사항' || title == '문의하기') {
            fullUrl = '$fullUrl&ss_user_no=$_loginIdx';
          }
          Navigator.pushNamed(
            context,
            '/webview',
            arguments: {
              'title': title,
              'url': fullUrl,
            },
          );
        },
      ),
    );
  }

  String _getRoleLabel(String memberCode) {
    switch (memberCode) {
      case Constants.roleSell:
        return '판매자';
      case Constants.roleProj:
        return '중간센터';
      case Constants.rolePub:
        return '구매자';
      default:
        return '사용자';
    }
  }
}
