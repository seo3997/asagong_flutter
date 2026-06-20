import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../data/models/push_notification_entity.dart';
import '../../data/repository/push_notification_repository.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final _repository = PushNotificationRepository();
  bool _isLoading = true;
  String _userId = '';
  String _memberCode = '';
  List<PushNotificationEntity> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('saved_email') ?? '';
    _memberCode = prefs.getString('saved_member_code') ?? '';

    if (_userId.isNotEmpty) {
      // Mark all as read when entering the screen
      await _repository.markAllRead(_userId);
      await _fetchList();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchList() async {
    if (_userId.isEmpty) return;
    final list = await _repository.getNotifications(_userId);
    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(int milliseconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'product':
        return Icons.shopping_bag_outlined;
      case 'order':
        return Icons.local_shipping_outlined;
      case 'sys':
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'chat':
        return const Color(0xFFFF9100);
      case 'product':
        return Colors.greenAccent;
      case 'order':
        return Colors.lightBlueAccent;
      case 'sys':
      default:
        return Colors.amberAccent;
    }
  }

  Future<void> _handleItemClick(PushNotificationEntity item) async {
    // Individual mark read
    await _repository.markRead(item.id);

    final targetId = item.targetId ?? '';
    if (mounted) {
      switch (item.type) {
        case 'chat':
          final parts = targetId.split('_');
          if (parts.length >= 3) {
            final productId = parts[0];
            final buyerId = parts[1];
            final branchId = parts[2];
            Navigator.pushNamed(
              context,
              '/chat',
              arguments: {
                'roomId': targetId,
                'buyerId': buyerId,
                'branchId': branchId,
                'productId': productId,
              },
            ).then((_) => _fetchList());
          }
          break;
        case 'product':
          Navigator.pushNamed(
            context,
            '/adDetail',
            arguments: targetId,
          ).then((_) => _fetchList());
          break;
        case 'order':
          final isSellerOrAdmin = _memberCode == Constants.roleSell ||
              _memberCode == Constants.roleProj ||
              _memberCode == Constants.roleAdmin;
          if (isSellerOrAdmin) {
            Navigator.pushNamed(
              context,
              '/orderMgtDetail',
              arguments: targetId,
            ).then((_) => _fetchList());
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('주문 상세 기능은 판매자 및 센터 전용입니다. (ID: $targetId)'),
              ),
            );
          }
          break;
        default:
          if (item.deeplink != null && item.deeplink!.isNotEmpty) {
            final uri = Uri.parse(item.deeplink!);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
          break;
      }
    }
  }

  Future<void> _deleteOne(PushNotificationEntity item) async {
    await _repository.delete(item.id);
    await _fetchList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E1A47),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '알림 리스트',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9100)),
            )
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '알림 내역이 없습니다.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: item.isRead
                            ? Colors.white.withOpacity(0.02)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: item.isRead
                              ? Colors.white.withOpacity(0.05)
                              : const Color(0xFFFF9100).withOpacity(0.2),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _getIconColor(item.type).withOpacity(0.1),
                          child: Icon(
                            _getIconForType(item.type),
                            color: _getIconColor(item.type),
                          ),
                        ),
                        title: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!item.isRead)
                              Container(
                                margin: const EdgeInsets.only(top: 6, right: 6),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF9100),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: item.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  color: item.isRead
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.body != null && item.body!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                item.body!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.55),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              _formatTimestamp(item.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          onPressed: () => _deleteOne(item),
                        ),
                        onTap: () => _handleItemClick(item),
                      ),
                    );
                  },
                ),
    );
  }
}
