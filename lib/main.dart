import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

import 'package:flutter/services.dart';

void main() async {
  // Ensure widget binding is initialized before calling SystemChrome
  WidgetsFlutterBinding.ensureInitialized();

  // Set orientation to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize the global AppServiceProvider
  AppServiceProvider.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
