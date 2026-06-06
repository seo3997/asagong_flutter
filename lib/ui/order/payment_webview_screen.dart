import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/service/app_service.dart';
import '../../data/models/order_models.dart';

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
    _productName = widget.arguments['productName'] as String? ?? '상품 결제';

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
                _launchExternalApp(url);
                return NavigationDecision.prevent;
              }

              return NavigationDecision.navigate;
            },
            onPageFinished: (_) {
              setState(() {
                _isLoading = false;
              });
            },
          ),
        )
        ..loadHtmlString(htmlContent, baseUrl: 'https://tosspayments.com');
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

  Future<void> _launchExternalApp(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Try fallback scheme or store
        if (url.startsWith('intent://')) {
          final parsed = _parseAndroidIntent(url);
          if (parsed != null) {
            final marketUri = Uri.parse('market://details?id=$parsed');
            if (await canLaunchUrl(marketUri)) {
              await launchUrl(marketUri, mode: LaunchMode.externalApplication);
            }
          }
        }
      }
    } catch (_) {
      // Ignore
    }
  }

  String? _parseAndroidIntent(String url) {
    try {
      final idx = url.indexOf('package=');
      if (idx != -1) {
        final endIdx = url.indexOf(';', idx);
        return url.substring(idx + 8, endIdx != -1 ? endIdx : url.length);
      }
    } catch (_) {}
    return null;
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
