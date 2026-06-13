import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/service/app_service.dart';
import '../../data/models/order_models.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const PaymentWebViewScreen({super.key, required this.arguments});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  static const _channel = MethodChannel('com.example.asagong_flutter/deeplink');
  late final WebViewController _controller;
  bool _isWidgetInitialized = false;
  bool _isLoading = false;

  String _clientKey = '';
  int _userNo = 0;
  late String _orderId;
  late String _orderNo;
  late int _amount;
  late String _productName;

  @override
  void initState() {
    super.initState();
    _orderId = widget.arguments['orderId'] as String? ?? '';
    _orderNo = widget.arguments['orderNo'] as String? ?? '';
    _amount = widget.arguments['amount'] as int? ?? 0;

    final rawName = widget.arguments['productName'] as String? ?? '';
    _productName = rawName.trim().isEmpty ? '상품 결제' : rawName;

    _initDeepLinkListener();
    _loadClientKeyAndInitialize();
  }

  Future<void> _loadClientKeyAndInitialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userNo = int.tryParse(prefs.getString('saved_login_idx') ?? '') ?? 0;
      _clientKey = prefs.getString('saved_toss_client_key') ?? '';

      // Fallback if client key is empty
      if (_clientKey.isEmpty) {
        _clientKey = 'test_ck_GjLJoX75zW9zdBa1yPd36w529OpV'; // Toss Payments test client key
      }

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) async {
              final url = request.url;
              debugPrint("WebView checking URL: $url");

              if (url.contains('payment-success')) {
                final uri = Uri.parse(url);
                final paymentKey = uri.queryParameters['paymentKey'] ?? '';
                final orderIdFromUrl = uri.queryParameters['orderId'] ?? _orderNo;
                final amountVal = int.tryParse(uri.queryParameters['amount'] ?? '') ?? _amount;
                
                _confirmPayment(paymentKey, orderIdFromUrl, amountVal);
                return NavigationDecision.prevent;
              } else if (url.contains('payment-fail')) {
                final uri = Uri.parse(url);
                final message = uri.queryParameters['message'] ?? '결제에 실패했습니다.';
                _finishWithFail(message);
                return NavigationDecision.prevent;
              }
              
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                try {
                  if (url.startsWith('intent://')) {
                    final parsed = _parseIntentUrl(url);
                    if (parsed != null) {
                      final schemeUrl = parsed['schemeUrl'] ?? '';
                      final packageName = parsed['package'] ?? '';
                      
                      if (schemeUrl.isNotEmpty) {
                        try {
                          await launchUrl(Uri.parse(schemeUrl), mode: LaunchMode.externalApplication);
                          return NavigationDecision.prevent;
                        } catch (_) {
                          // Fallback to play store if scheme launching fails
                        }
                      }
                      
                      if (packageName.isNotEmpty) {
                        try {
                          await launchUrl(Uri.parse('market://details?id=$packageName'), mode: LaunchMode.externalApplication);
                          return NavigationDecision.prevent;
                        } catch (_) {}
                      }
                    }
                    return NavigationDecision.prevent;
                  }

                  final decodedUrl = Uri.decodeFull(url);
                  await launchUrl(Uri.parse(decodedUrl), mode: LaunchMode.externalApplication);
                } catch (e) {
                  debugPrint('Launch custom scheme error: $e');
                }
                return NavigationDecision.prevent;
              }
              
              return NavigationDecision.navigate;
            },
            onWebResourceError: (WebResourceError error) async {
              final failingUrl = error.url;
              debugPrint("WebResourceError: code=${error.errorCode}, desc=${error.description}, url=$failingUrl");
              if (failingUrl != null && !failingUrl.startsWith('http://') && !failingUrl.startsWith('https://')) {
                try {
                  if (failingUrl.startsWith('intent://')) {
                    final parsed = _parseIntentUrl(failingUrl);
                    if (parsed != null) {
                      final schemeUrl = parsed['schemeUrl'] ?? '';
                      final packageName = parsed['package'] ?? '';
                      
                      if (schemeUrl.isNotEmpty) {
                        try {
                          await launchUrl(Uri.parse(schemeUrl), mode: LaunchMode.externalApplication);
                          return;
                        } catch (_) {}
                      }
                      if (packageName.isNotEmpty) {
                        try {
                          await launchUrl(Uri.parse('market://details?id=$packageName'), mode: LaunchMode.externalApplication);
                          return;
                        } catch (_) {}
                      }
                    }
                  } else {
                    final decodedUrl = Uri.decodeFull(failingUrl);
                    await launchUrl(Uri.parse(decodedUrl), mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  debugPrint('Launch from error url failed: $e');
                }
              }
            },
          ),
        )
        ..loadHtmlString(
          _buildHtml(),
          baseUrl: 'https://tosspayments.com',
        );

      setState(() {
        _isWidgetInitialized = true;
      });
    } catch (e) {
      debugPrint("TossPayments init error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('결제 모듈 초기화 실패: $e')),
        );
      }
    }
  }

  void _initDeepLinkListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLinkReceived') {
        final String? link = call.arguments as String?;
        if (link != null) {
          debugPrint("Received DeepLink during payment: $link");
          _handleDeepLink(link);
        }
      }
    });
    _checkInitialLink();
  }

  Future<void> _checkInitialLink() async {
    try {
      final String? initialLink = await _channel.invokeMethod<String>('getInitialLink');
      if (initialLink != null) {
        debugPrint("Received initial DeepLink during payment: $initialLink");
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint("Failed to get initial link: $e");
    }
  }

  void _handleDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      if (uri.scheme == 'asagongpay') {
        final paymentKey = uri.queryParameters['paymentKey'];
        final orderId = uri.queryParameters['orderId'] ?? uri.queryParameters['orderNo'] ?? _orderNo;
        final amountStr = uri.queryParameters['amount'];
        final amount = amountStr != null ? int.tryParse(amountStr) : _amount;

        if (paymentKey != null && paymentKey.isNotEmpty) {
          _confirmPayment(paymentKey, orderId, amount ?? _amount);
        } else {
          // If no parameters, the card app just returned us to foreground.
          // In some environments, Toss JS SDK will detect foreground and auto-complete in webview.
          // Otherwise, we can redirect webview to success page, but we need parameters.
          // Let's print a warning or load success URL if we can somehow fetch the state.
          debugPrint("Deep link returned without paymentKey.");
        }
      }
    } catch (e) {
      debugPrint("Error handling deep link: $e");
    }
  }

  Map<String, String>? _parseIntentUrl(String url) {
    try {
      if (!url.startsWith("intent://")) return null;
      final intentIndex = url.indexOf("#Intent;");
      if (intentIndex == -1) return null;

      final uriPath = url.substring(9, intentIndex);
      final paramsStr = url.substring(intentIndex + 8);
      final params = paramsStr.split(";");

      String scheme = "";
      String packageName = "";
      for (var param in params) {
        if (param.startsWith("scheme=")) {
          scheme = param.substring(7);
        } else if (param.startsWith("package=")) {
          packageName = param.substring(8);
        }
      }

      return {
        "schemeUrl": scheme.isNotEmpty ? "$scheme://$uriPath" : "",
        "package": packageName,
      };
    } catch (e) {
      return null;
    }
  }

  String _buildHtml() {
    final successUrl = "http://localhost/payment-success";
    final failUrl = "http://localhost/payment-fail";
    
    return """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://js.tosspayments.com/v1"></script>
</head>
<body>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            try {
                var tossPayments = TossPayments("$_clientKey");
                tossPayments.requestPayment('CARD', {
                    amount: $_amount,
                    orderId: '${_orderNo.replaceAll("'", "\\'")}',
                    orderName: '${_productName.replaceAll("'", "\\'")}',
                    successUrl: '$successUrl',
                    failUrl: '$failUrl',
                    appScheme: 'asagongpay',
                });
            } catch (e) {
                console.error("TossPayments error:", e);
            }
        });
    </script>
</body>
</html>
    """;
  }

  Future<void> _confirmPayment(
    String paymentKey,
    String paymentOrderId,
    int amount,
  ) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    final appService = RepositoryProvider.of<AppService>(context);

    try {
      final req = PaymentConfirmRequest(
        paymentKey: paymentKey,
        orderNo: paymentOrderId,
        amount: amount,
        userNo: _userNo,
      );

      final response = await appService.confirmPayment(req);
      if (!mounted) return;
      if (response != null && response.success == true) {
        Navigator.pop(context, {
          'status': 'SUCCESS',
          'paymentKey': paymentKey,
          'orderId': _orderId,
          'orderNo': _orderNo,
          'amount': amount,
        });
      } else {
        final errMsg = response != null ? response.message : '결제 승인 실패';
        _finishWithFail(errMsg ?? '결제 승인 실패');
      }
    } catch (e) {
      _finishWithFail('승인 요청 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _finishWithFail(String message) {
    if (mounted) {
      Navigator.pop(context, {'status': 'FAIL', 'message': message});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2E1A47),
        title: const Text(
          '결제하기',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (_isWidgetInitialized)
            WebViewWidget(controller: _controller)
          else
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF9100),
              ),
            ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF9100),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
