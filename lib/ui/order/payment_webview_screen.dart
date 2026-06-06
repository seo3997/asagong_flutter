import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/service/app_service.dart';
import '../../data/models/order_models.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const PaymentWebViewScreen({
    super.key,
    required this.arguments,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _clientKey = '';
  String? _token;
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

    _loadClientKeyAndInitialize();
  }

  Future<void> _loadClientKeyAndInitialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('saved_token');
      _userNo = int.tryParse(prefs.getString('saved_login_idx') ?? '') ?? 0;
      _clientKey = prefs.getString('saved_toss_client_key') ?? '';

      // Fallback if client key is empty
      if (_clientKey.isEmpty) {
        _clientKey = 'test_ck_GjLJoX75zW9zdBa1yPd36w529OpV'; // Toss Payments test client key
      }

      final successUrl = 'http://localhost/payment-success';
      final failUrl = 'http://localhost/payment-fail';

      final htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <script src="https://js.tosspayments.com/v1"></script>
            <style>
              body { background-color: #1E1E2C; margin: 0; padding: 0; display: flex; justify-content: center; align-items: center; height: 100vh; color: white; font-family: sans-serif; }
            </style>
        </head>
        <body>
            <div id="status">결제 창을 여는 중...</div>
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
                        });
                    } catch (e) {
                        console.error("TossPayments error:", e);
                        document.getElementById("status").innerText = "오류: " + e.message;
                    }
                });
            </script>
        </body>
        </html>
      """;

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF1E1E2C))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              _handleUrl(url);
            },
            onNavigationRequest: (request) {
              final url = request.url;
              if (_isRedirectUrl(url)) {
                _handleUrl(url);
                return NavigationDecision.prevent;
              }

              // Deep link external apps (Card apps, Shinhan Pay, KB Pay, etc.)
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                setState(() {
                  _isLoading = true;
                });
                _launchExternalApp(url);
                return NavigationDecision.prevent;
              }

              return NavigationDecision.navigate;
            },
            onWebResourceError: (error) {
              final failingUrl = error.url ?? '';
              if (failingUrl.isNotEmpty && !failingUrl.startsWith('http://') && !failingUrl.startsWith('https://')) {
                setState(() {
                  _isLoading = true;
                });
                _launchExternalApp(failingUrl);
              }
            },
            onPageFinished: (_) {
              // Note: Do not force _isLoading to false here if we are redirecting to card apps,
              // but standard page finishes should resolve loading.
              setState(() {
                _isLoading = false;
              });
            },
          ),
        )
        ..loadHtmlString(htmlContent, baseUrl: 'https://tosspayments.com');

      final platform = _controller.platform;
      if (platform is AndroidWebViewController) {
        await AndroidWebViewCookieManager(
          const PlatformWebViewCookieManagerCreationParams(),
        ).setAcceptThirdPartyCookies(platform, true);
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isRedirectUrl(String url) {
    return url.contains('payment-success') || url.contains('payment-fail');
  }

  void _handleUrl(String url) {
    if (url.contains('payment-success')) {
      final uri = Uri.parse(url);
      final paymentKey = uri.queryParameters['paymentKey'] ?? '';
      final orderNoFromUrl = uri.queryParameters['orderId'] ?? _orderNo;
      final amountFromUrl = int.tryParse(uri.queryParameters['amount'] ?? '') ?? _amount;

      _confirmPayment(paymentKey, orderNoFromUrl, amountFromUrl);
    } else if (url.contains('payment-fail')) {
      final uri = Uri.parse(url);
      final message = uri.queryParameters['message'] ?? '결제에 실패했습니다.';
      _finishWithFail(message);
    }
  }

  Map<String, String>? _parseIntentUrl(String url) {
    try {
      if (!url.startsWith('intent://')) return null;
      final intentIndex = url.indexOf('#Intent;');
      if (intentIndex == -1) return null;
      
      final uriPath = url.substring(9, intentIndex);
      final paramsStr = url.substring(intentIndex + 8);
      final params = paramsStr.split(';');
      
      String scheme = '';
      String package = '';
      for (var param in params) {
        if (param.startsWith('scheme=')) {
          scheme = param.substring(7);
        } else if (param.startsWith('package=')) {
          package = param.substring(8);
        }
      }
      
      return {
        'schemeUrl': scheme.isNotEmpty ? '$scheme://$uriPath' : '',
        'package': package,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> _launchExternalApp(String url) async {
    try {
      // 1. intent:// scheme parsing
      if (url.startsWith('intent://')) {
        final parsed = _parseIntentUrl(url);
        if (parsed != null) {
          final schemeUrl = parsed['schemeUrl'] ?? '';
          final package = parsed['package'] ?? '';
          
          if (schemeUrl.isNotEmpty) {
            try {
              // Direct launch attempt without canLaunchUrl check
              final success = await launchUrl(Uri.parse(schemeUrl), mode: LaunchMode.externalApplication);
              if (success) return;
            } catch (_) {}
          }
          
          // Fallback to Google Play market if direct launch fails or scheme is empty
          if (package.isNotEmpty) {
            try {
              final marketUri = Uri.parse('market://details?id=$package');
              await launchUrl(marketUri, mode: LaunchMode.externalApplication);
              return;
            } catch (_) {}
          }
        }
        return;
      }
      
      // 2. Direct launch for normal custom schemes (kakaotalk://, wooripay://, etc.)
      final uri = Uri.parse(uriStringDecode(url));
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // Optional: If direct custom scheme fails, try parsing fallback market or ignore
      }
    } catch (e) {
      debugPrint("Failed to launch external app: $e");
    }
  }

  // Decodes url encoded character safety helper
  String uriStringDecode(String url) {
    try {
      return Uri.decodeFull(url);
    } catch (_) {
      return url;
    }
  }

  Future<void> _confirmPayment(String paymentKey, String paymentOrderId, int amount) async {
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
    }
  }

  void _finishWithFail(String message) {
    Navigator.pop(context, {
      'status': 'FAIL',
      'message': message,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E1A47),
        title: const Text('결제하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (_clientKey.isNotEmpty) WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: const Color(0xFF1E1E2C),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF9100)),
              ),
            ),
        ],
      ),
    );
  }
}
