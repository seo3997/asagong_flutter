import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/push_notification_entity.dart';

class PushNotificationRepository {
  static const String _storageKey = 'push_notifications_list';

  Future<List<PushNotificationEntity>> getNotifications(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      final list = decoded
          .map((item) => PushNotificationEntity.fromJson(item as Map<String, dynamic>))
          .where((element) => element.userId == userId)
          .toList();
      
      // Sort by createdAt descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotification(PushNotificationEntity notification) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    List<PushNotificationEntity> allNotifications = [];
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        allNotifications = decoded
            .map((item) => PushNotificationEntity.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // Generate unique ID
    int newId = 1;
    if (allNotifications.isNotEmpty) {
      newId = allNotifications.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    }

    final newNotification = notification.copyWith(id: newId);
    allNotifications.add(newNotification);

    await prefs.setString(_storageKey, jsonEncode(allNotifications.map((e) => e.toJson()).toList()));
  }

  Future<void> markRead(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) return;

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      final allNotifications = decoded
          .map((item) => PushNotificationEntity.fromJson(item as Map<String, dynamic>))
          .toList();

      final index = allNotifications.indexWhere((element) => element.id == id);
      if (index != -1) {
        allNotifications[index] = allNotifications[index].copyWith(isRead: true);
        await prefs.setString(_storageKey, jsonEncode(allNotifications.map((e) => e.toJson()).toList()));
      }
    } catch (_) {}
  }

  Future<void> markAllRead(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) return;

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      final allNotifications = decoded
          .map((item) => PushNotificationEntity.fromJson(item as Map<String, dynamic>))
          .toList();

      bool modified = false;
      for (int i = 0; i < allNotifications.length; i++) {
        if (allNotifications[i].userId == userId && !allNotifications[i].isRead) {
          allNotifications[i] = allNotifications[i].copyWith(isRead: true);
          modified = true;
        }
      }

      if (modified) {
        await prefs.setString(_storageKey, jsonEncode(allNotifications.map((e) => e.toJson()).toList()));
      }
    } catch (_) {}
  }

  Future<void> delete(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) return;

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      final allNotifications = decoded
          .map((item) => PushNotificationEntity.fromJson(item as Map<String, dynamic>))
          .toList();

      final initialLength = allNotifications.length;
      allNotifications.removeWhere((element) => element.id == id);

      if (allNotifications.length != initialLength) {
        await prefs.setString(_storageKey, jsonEncode(allNotifications.map((e) => e.toJson()).toList()));
      }
    } catch (_) {}
  }
}
