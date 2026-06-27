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
import 'core/local_notification_service.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'ui/login/find_email_pwd_screen.dart';
import 'ui/login/terms_agree_screen.dart';
import 'ui/login/membership_screen.dart';
import 'ui/login/onboarding_screen.dart';

String? currentActiveRoomId;
Map<String, dynamic>? pendingPushData;

void checkAndHandlePendingPush() {
  final data = pendingPushData;
  if (data != null) {
    pendingPushData = null;
    debugPrint("Found pending push navigation. Processing...");
    Future.delayed(const Duration(milliseconds: 500), () {
      handlePushNavigation(data);
    });
  }
}

void handlePushNavigation(Map<String, dynamic> data) async {
  final type = data['type']?.toString();
  final targetId = data['targetId']?.toString();
  if (type == null || type.isEmpty || targetId == null || targetId.isEmpty) return;

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('saved_token');

  if (token == null || token.isEmpty) {
    debugPrint("User not logged in. Saving push navigation as pending.");
    pendingPushData = data;
    return;
  }

  final context = navigatorKey.currentContext;
  if (context == null) {
    debugPrint("Navigator context not available. Saving push navigation as pending.");
    pendingPushData = data;
    return;
  }

  // Check the current top-most route name.
  String? currentRouteName;
  navigatorKey.currentState?.popUntil((route) {
    currentRouteName = route.settings.name;
    return true; // do not pop
  });

  debugPrint("Current route name check: $currentRouteName");

  // If the current screen is Intro or Login, do not push the detail screen yet
  if (currentRouteName == '/' || currentRouteName == '/login' || currentRouteName == null) {
    debugPrint("App is currently in Intro/Login state. Saving push navigation as pending.");
    pendingPushData = data;
    return;
  }

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
        'productId': productId,
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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");

  final data = message.data;
  final title = message.notification?.title ?? data['title']?.toString() ?? '새 알림';
  final body = message.notification?.body ?? data['body']?.toString() ?? '알림 내용 없음';
  final type = data['type']?.toString();
  final targetId = data['targetId']?.toString() ??
                   data['roomId']?.toString() ??
                   data['productId']?.toString() ??
                   data['orderId']?.toString();

  // Save the notification to SharedPreferences from the background
  await saveNotificationLocally(data, title, body);

  // Display the notification banner using LocalNotificationService
  await LocalNotificationService.showNotification(
    title: title,
    body: body,
    type: type,
    targetId: targetId,
  );
}

Future<void> saveNotificationLocally(
  Map<String, dynamic> data,
  String? notificationTitle,
  String? notificationBody,
) async {
  try {
    final title = notificationTitle ?? data['title']?.toString() ?? '새 알림';
    final body = notificationBody ?? data['body']?.toString() ?? '알림 내용 없음';
    final type = data['type']?.toString() ?? 'sys';
    final targetId = data['targetId']?.toString() ??
                     data['roomId']?.toString() ??
                     data['productId']?.toString() ??
                     data['orderId']?.toString();

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
  
  // Initialize Kakao SDK
  KakaoSdk.init(nativeAppKey: '702de162af6c2ac940e8f588abf0753f');
  
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
    // 1. Configure the tap response first (before initialize) to capture app-launch notifications
    LocalNotificationService.onNotificationClick = (payload) {
      debugPrint("Local notification clicked with payload: $payload");
      if (payload != null && payload.contains('|')) {
        final parts = payload.split('|');
        if (parts.length >= 2) {
          final type = parts[0];
          final targetId = parts[1];
          handlePushNavigation({
            'type': type,
            'targetId': targetId,
          });
        }
      }
    };
    await LocalNotificationService.initialize();

    // 2. Check if the app was launched by clicking a local notification (terminated state)
    try {
      final launchDetails = await LocalNotificationService.getAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        debugPrint("App launched via local notification payload: $payload");
        if (payload != null && payload.contains('|')) {
          final parts = payload.split('|');
          if (parts.length >= 2) {
            final type = parts[0];
            final targetId = parts[1];
            Future.delayed(const Duration(milliseconds: 1500), () {
              handlePushNavigation({
                'type': type,
                'targetId': targetId,
              });
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking app launch local notification: $e");
    }

    // 1. Foreground Message received
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("FCM onMessage (Foreground): ${message.notification?.title}");
      
      final data = message.data;
      final title = message.notification?.title ?? data['title']?.toString() ?? '새 알림';
      final body = message.notification?.body ?? data['body']?.toString() ?? '알림 내용 없음';
      final type = data['type']?.toString();
      final targetId = data['targetId']?.toString() ??
                       data['roomId']?.toString() ??
                       data['productId']?.toString() ??
                       data['orderId']?.toString();

      // Suppress showing/saving if active in same chat room
      if (type == 'chat' && targetId == currentActiveRoomId && targetId != null) {
        debugPrint("User is in active chat room ($currentActiveRoomId). Suppressing push popups.");
        return;
      }

      saveNotificationLocally(
        message.data,
        message.notification?.title,
        message.notification?.body,
      );

      // Display the notification popup banner
      LocalNotificationService.showNotification(
        title: title,
        body: body,
        type: type,
        targetId: targetId,
      );
    });

    // 2. App in background -> Clicked -> Opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("FCM onMessageOpenedApp: ${message.data}");
      saveNotificationLocally(
        message.data,
        message.notification?.title,
        message.notification?.body,
      );
      handlePushNavigation(message.data);
    });

    // 3. App terminated -> Clicked -> Launched
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("FCM getInitialMessage: ${initialMessage.data}");
      saveNotificationLocally(
        initialMessage.data,
        initialMessage.notification?.title,
        initialMessage.notification?.body,
      );
      Future.delayed(const Duration(milliseconds: 1500), () {
        handlePushNavigation(initialMessage.data);
      });
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
            '/findEmailPwd': (context) => const FindEmailPwdScreen(),
            '/termsAgree': (context) => const TermsAgreeScreen(),
            '/membership': (context) => const MembershipScreen(),
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
              case '/onboarding':
                final map = args as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => OnboardingScreen(
                    provider: map['provider'] as String,
                    providerUserId: map['providerUserId'] as String,
                    email: map['email'] as String?,
                    nickname: map['nickname'] as String?,
                    profileUrl: map['profileUrl'] as String?,
                  ),
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
