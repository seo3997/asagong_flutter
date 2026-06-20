import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Function(String?)? onNotificationClick;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (onNotificationClick != null) {
          onNotificationClick!(response.payload);
        }
      },
    );
    _isInitialized = true;
  }

  static Future<NotificationAppLaunchDetails?> getAppLaunchDetails() async {
    return await _notificationsPlugin.getNotificationAppLaunchDetails();
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? type,
    String? targetId,
  }) async {
    await initialize();

    final String channelId = _getChannelId(type);
    final String channelName = _getChannelName(type);
    final String channelDesc = _getChannelDescription(type);

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: '$type|$targetId',
    );
  }

  static String _getChannelId(String? type) {
    switch (type) {
      case 'chat':
        return 'chat_channel';
      case 'product':
        return 'product_channel';
      case 'order':
        return 'order_channel';
      default:
        return 'default_channel';
    }
  }

  static String _getChannelName(String? type) {
    switch (type) {
      case 'chat':
        return '채팅 알림';
      case 'product':
        return '상품 알림';
      case 'order':
        return '주문 알림';
      default:
        return '일반 알림';
    }
  }

  static String _getChannelDescription(String? type) {
    switch (type) {
      case 'chat':
        return '채팅 관련 알림입니다.';
      case 'product':
        return '신규 상품 관련 알림입니다.';
      case 'order':
        return '주문 관련 알림입니다.';
      default:
        return '기타 알림입니다.';
    }
  }
}
