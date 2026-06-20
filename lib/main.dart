import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'domain/service/app_service.dart';
import 'domain/service/app_service_provider.dart';
import 'blocs/auth/auth_bloc.dart';
import 'ui/login/login_screen.dart';
import 'ui/intro/intro_screen.dart';
import 'ui/dashboard/dashboard_screen.dart';
import 'ui/buyer/pub_home_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/widgets/webview_screen.dart';
import 'ui/order/order_mgt_screen.dart';
import 'ui/order/order_mgt_detail_screen.dart';
import 'ui/product/ad_detail_screen.dart';
import 'ui/product/ad_review_write_screen.dart';
import 'ui/product/ad_qna_write_screen.dart';
import 'ui/order/order_screen.dart';
import 'ui/order/payment_webview_screen.dart';
import 'ui/order/order_success_screen.dart';
import 'ui/order/address_search_screen.dart';
import 'ui/chatting/chat_screen.dart';
import 'ui/notification/notification_list_screen.dart';
import 'data/repository/push_notification_repository.dart';
import 'data/models/push_notification_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/services.dart';

String? currentActiveRoomId;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  // Ensure widget binding is initialized before calling SystemChrome
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // FCM 권한 요청
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
    
    // 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // Set orientation to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize the global AppServiceProvider
  AppServiceProvider.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupPushNotifications();
  }

  Future<void> _setupPushNotifications() async {
    // 1. Foreground Message received
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("FCM onMessage (Foreground): ${message.notification?.title}");
      _saveNotificationLocally(
        message.data,
        message.notification?.title,
        message.notification?.body,
      );
    });

    // 2. App in background -> Clicked -> Opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("FCM onMessageOpenedApp: ${message.data}");
      _saveNotificationLocally(
        message.data,
        message.notification?.title,
        message.notification?.body,
      );
      _handlePushNavigation(message.data);
    });

    // 3. App terminated -> Clicked -> Launched
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("FCM getInitialMessage: ${initialMessage.data}");
      _saveNotificationLocally(
        initialMessage.data,
        initialMessage.notification?.title,
        initialMessage.notification?.body,
      );
      Future.delayed(const Duration(milliseconds: 1500), () {
        _handlePushNavigation(initialMessage.data);
      });
    }
  }

  Future<void> _saveNotificationLocally(
    Map<String, dynamic> data,
    String? notificationTitle,
    String? notificationBody,
  ) async {
    try {
      final title = notificationTitle ?? data['title']?.toString() ?? '새 알림';
      final body = notificationBody ?? data['body']?.toString() ?? '알림 내용 없음';
      final type = data['type']?.toString() ?? 'sys';
      final targetId = data['targetId']?.toString();

      if (type == 'chat' && targetId == currentActiveRoomId && targetId != null) {
        debugPrint("User is in active chat room ($currentActiveRoomId). Suppressing push save.");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('saved_email') ?? '';
      if (userId.isEmpty) return;

      final repo = PushNotificationRepository();
      
      final list = await repo.getNotifications(userId);
      final isDuplicate = list.any((n) => 
        n.type == type && 
        n.title == title && 
        n.targetId == targetId && 
        (DateTime.now().millisecondsSinceEpoch - n.createdAt < 5000)
      );

      if (isDuplicate) {
        debugPrint("FCM Duplicate local storage skip");
        return;
      }

      String? deeplink;
      if (type == 'chat') {
        deeplink = 'app://chat/room/${targetId ?? ""}';
      } else if (type == 'product') {
        deeplink = 'app://product/${targetId ?? ""}';
      } else if (type == 'order') {
        deeplink = 'app://order/${targetId ?? ""}';
      }

      final entity = PushNotificationEntity(
        id: 0,
        userId: userId,
        type: type,
        title: title,
        body: body,
        targetId: targetId,
        deeplink: deeplink,
        isRead: false,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await repo.saveNotification(entity);
      debugPrint("FCM notification saved locally");
    } catch (e) {
      debugPrint("Error saving FCM notification locally: $e");
    }
  }

  void _handlePushNavigation(Map<String, dynamic> data) async {
    final type = data['type']?.toString();
    final targetId = data['targetId']?.toString();
    if (type == null || type.isEmpty || targetId == null || targetId.isEmpty) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'chat':
        final parts = targetId.split('_');
        String productId = '';
        String buyerId = '';
        String branchId = '';
        if (parts.length >= 3) {
          productId = parts[0];
          buyerId = parts[1];
          branchId = parts[2];
        }
        Navigator.of(context).pushNamed('/chat', arguments: {
          'roomId': targetId,
          'buyerId': buyerId,
          'branchId': branchId,
          'productId': int.tryParse(productId) ?? 0,
          'type': type,
          'msg': data['msg'] ?? '',
        });
        break;

      case 'product':
        Navigator.of(context).pushNamed('/adDetail', arguments: targetId);
        break;

      case 'order':
        Navigator.of(context).pushNamed('/orderMgtDetail', arguments: targetId);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppService>(
          create: (context) => AppServiceProvider.getService(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              appService: RepositoryProvider.of<AppService>(context),
            ),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'asagong',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6A1B9A),
              primary: const Color(0xFFFF9100),
            ),
            useMaterial3: true,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const IntroScreen(),
            '/login': (context) => const LoginScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/pubHome': (context) => const PubHomeScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/webview': (context) => const WebViewScreen(),
            '/orderMgt': (context) => const OrderMgtScreen(),
            '/orderMgtDetail': (context) => const OrderMgtDetailScreen(),
            '/notificationList': (context) => const NotificationListScreen(),
          },
          onGenerateRoute: (settings) {
            final args = settings.arguments;
            switch (settings.name) {
              case '/adDetail':
                final pid = args as String;
                return MaterialPageRoute(
                  builder: (context) => AdDetailScreen(productId: pid),
                );
              case '/reviewWrite':
                final map = args as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => AdReviewWriteScreen(
                    productId: map['productId'] as int,
                    reviewId: map['reviewId'] as String?,
                    contents: map['contents'] as String?,
                    rating: map['rating'] as double?,
                    filePaths: map['filePaths'] as String?,
                  ),
                );
              case '/qnaWrite':
                final map = args as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => AdQnaWriteScreen(
                    productId: map['productId'] as int,
                    qnaId: map['qnaId'] as String?,
                    title: map['title'] as String?,
                    contents: map['contents'] as String?,
                    secretYn: map['secretYn'] as String?,
                  ),
                );
              case '/order':
                final map = args as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => OrderScreen(arguments: map),
                );
              case '/paymentWebview':
                final map = args as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => PaymentWebViewScreen(arguments: map),
                );
              case '/orderSuccess':
                final map = args as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => OrderSuccessScreen(arguments: map),
                );
              case '/chat':
                final map = args as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => ChatScreen(arguments: map),
                );
              case '/addressSearch':
                return MaterialPageRoute(
                  builder: (context) => const AddressSearchScreen(),
                );
              default:
                return null;
            }
          },
        ),
      ),
    );
  }
}
