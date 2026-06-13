import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tosspayments_widget_sdk_flutter/payment_widget.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_info.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_widget_options.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/payment_method.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/agreement.dart';

import '../../domain/service/app_service.dart';
import '../../data/models/order_models.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const PaymentWebViewScreen({super.key, required this.arguments});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.example.asagong_flutter/deeplink');
  late PaymentWidget _paymentWidget;

  bool _isSdkInitialized = false;
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
    WidgetsBinding.instance.addObserver(this);
    _orderId = widget.arguments['orderId'] as String? ?? '';
    _orderNo = widget.arguments['orderNo'] as String? ?? '';
    _amount = widget.arguments['amount'] as int? ?? 0;

    final rawName = widget.arguments['productName'] as String? ?? '';
    _productName = rawName.trim().isEmpty ? '상품 결제' : rawName;

    _initDeepLinkListener();
    _loadClientKeyAndInitialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("App resumed - pulling pending deep link from native");
      _checkInitialLink();
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
    debugPrint("=== [DEBUG] _handleDeepLink START: $link ===");
    try {
      final uri = Uri.parse(link);
      debugPrint("=== [DEBUG] _handleDeepLink parsed uri scheme: ${uri.scheme} ===");
      if (uri.scheme == 'asagongpay') {
        final paymentKey = uri.queryParameters['paymentKey'];
        final orderId = uri.queryParameters['orderId'] ?? uri.queryParameters['orderNo'] ?? _orderNo;
        final amountStr = uri.queryParameters['amount'];
        final amount = amountStr != null ? int.tryParse(amountStr) : _amount;

        debugPrint("=== [DEBUG] _handleDeepLink params - paymentKey: $paymentKey, orderId: $orderId, amount: $amount ===");

        if (paymentKey != null && paymentKey.isNotEmpty) {
          _confirmPayment(paymentKey, orderId, amount ?? _amount);
        } else {
          debugPrint("=== [DEBUG] _handleDeepLink: paymentKey is empty or null ===");
        }
      }
    } catch (e) {
      debugPrint("=== [DEBUG] _handleDeepLink ERROR: $e ===");
    }
  }

  Future<void> _loadClientKeyAndInitialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userNo = int.tryParse(prefs.getString('saved_login_idx') ?? '') ?? 0;
      
      // Hardcode client key for testing as requested by user
      _clientKey = 'test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm';

      // Initialize official PaymentWidget
      _paymentWidget = PaymentWidget(
        clientKey: _clientKey,
        customerKey: _userNo > 0 ? 'USER_$_userNo' : 'ANONYMOUS',
      );

      setState(() {
        _isSdkInitialized = true;
      });

      // Render payment methods widget
      _paymentWidget.renderPaymentMethods(
        selector: 'methods',
        amount: Amount(value: _amount, currency: Currency.KRW, country: "KR"),
      );

      // Render agreement widget
      _paymentWidget.renderAgreement(selector: 'agreement');

    } catch (e) {
      debugPrint("TossPayments init error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('결제 모듈 초기화 실패: $e')),
        );
      }
    }
  }

  Future<void> _handlePayment() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final paymentResult = await _paymentWidget.requestPayment(
        paymentInfo: PaymentInfo(
          orderId: _orderNo,
          orderName: _productName,
          appScheme: 'asagongpay',
        ),
      );

      if (paymentResult.success != null) {
        final success = paymentResult.success!;
        debugPrint("TossPayments success: paymentKey=${success.paymentKey}, orderId=${success.orderId}, amount=${success.amount}");
        await _confirmPayment(
          success.paymentKey,
          success.orderId,
          success.amount.toInt(),
        );
      } else if (paymentResult.fail != null) {
        final fail = paymentResult.fail!;
        debugPrint("TossPayments fail: code=${fail.errorCode}, message=${fail.errorMessage}");
        _finishWithFail(fail.errorMessage);
      } else {
        _finishWithFail("결제 처리가 비정상적으로 완료되었습니다.");
      }
    } catch (e) {
      debugPrint("TossPayments exception during requestPayment: $e");
      _finishWithFail("결제 진행 중 오류가 발생했습니다: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmPayment(
    String paymentKey,
    String paymentOrderId,
    int amount,
  ) async {
    debugPrint("=== [DEBUG] _confirmPayment called. Key: $paymentKey, OrderNo: $paymentOrderId, Amount: $amount ===");
    if (_isLoading) {
      // Avoid starting multiple loading state, but set it true if it's not already.
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    final appService = RepositoryProvider.of<AppService>(context);

    try {
      final req = PaymentConfirmRequest(
        paymentKey: paymentKey,
        orderNo: paymentOrderId,
        amount: amount,
        userNo: _userNo,
      );

      debugPrint("=== [DEBUG] _confirmPayment: Sending request to appService ===");
      final response = await appService.confirmPayment(req);
      debugPrint("=== [DEBUG] _confirmPayment: Received response. success: ${response?.success}, message: ${response?.message} ===");
      if (!mounted) return;
      if (response != null && response.success == true) {
        debugPrint("=== [DEBUG] _confirmPayment: Success! Navigating to Success Screen ===");
        Navigator.pop(context, {
          'status': 'SUCCESS',
          'paymentKey': paymentKey,
          'orderId': _orderId,
          'orderNo': _orderNo,
          'amount': amount,
        });
      } else {
        final errMsg = response != null ? response.message : '결제 승인 실패';
        debugPrint("=== [DEBUG] _confirmPayment: Failed. msg: $errMsg ===");
        _finishWithFail(errMsg ?? '결제 승인 실패');
      }
    } catch (e) {
      debugPrint("=== [DEBUG] _confirmPayment ERROR: $e ===");
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
      body: SafeArea(
        child: Stack(
          children: [
            if (_isSdkInitialized)
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          PaymentMethodWidget(
                            paymentWidget: _paymentWidget,
                            selector: 'methods',
                          ),
                          AgreementWidget(
                            paymentWidget: _paymentWidget,
                            selector: 'agreement',
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9100),
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _handlePayment,
                      child: const Text(
                        '결제하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
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
      ),
    );
  }
}
