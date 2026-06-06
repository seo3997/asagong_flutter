import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/service/app_service.dart';
import '../../core/constants.dart';
import '../../data/models/payment_models.dart';

class OrderMgtDetailScreen extends StatefulWidget {
  const OrderMgtDetailScreen({super.key});

  @override
  State<OrderMgtDetailScreen> createState() => _OrderMgtDetailScreenState();
}

class _OrderMgtDetailScreenState extends State<OrderMgtDetailScreen> {
  final TextEditingController _trackingController = TextEditingController();
  
  bool _isLoading = true;
  String? _token;
  String? _memberCode;
  String? _orderId;
  String? _errorMsg;

  Map<String, dynamic>? _orderDetailData;
  List<Map<String, dynamic>> _orderItems = [];
  List<Map<String, dynamic>> _carrierList = [];

  String? _selectedCarrierCode;
  String _selectedCarrierLabel = '선택하세요';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orderId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _orderId = args;
        _initData();
      } else {
        setState(() {
          _isLoading = false;
          _errorMsg = '유효하지 않은 주문 ID입니다.';
        });
      }
    }
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('saved_token');
    _memberCode = prefs.getString('saved_member_code');

    if (_token == null || _token!.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMsg = '세션 정보가 없습니다. 다시 로그인해 주세요.';
      });
      return;
    }

    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final appService = RepositoryProvider.of<AppService>(context);
      final result = await appService.getOrderMgtDetail(_orderId!, _token!);

      if (result != null) {
        final items = result['orderItemList'] as List<dynamic>? ?? [];
        final carriers = result['deliveryCompanyList'] as List<dynamic>? ?? [];
        
        setState(() {
          _orderDetailData = result;
          _orderItems = items.map((e) => e as Map<String, dynamic>).toList();
          _carrierList = carriers.map((e) => e as Map<String, dynamic>).toList();

          final order = result['resultVo'] as Map<String, dynamic>? ?? {};
          final currentCarrierCode = (order['deliveryCompanyCode'] ?? order['DELIVERY_COMPANY_CODE'] ?? '').toString();
          
          if (currentCarrierCode.isNotEmpty) {
            final idx = _carrierList.indexWhere((c) => (c['CODE'] ?? c['code'])?.toString() == currentCarrierCode);
            if (idx >= 0) {
              _selectedCarrierCode = currentCarrierCode;
              _selectedCarrierLabel = (_carrierList[idx]['CODE_NM'] ?? _carrierList[idx]['codeNm'] ?? '').toString();
            }
          }

          final trackingNo = (order['trackingNo'] ?? order['TRACKING_NO'] ?? '').toString();
          _trackingController.text = trackingNo;

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMsg = '주문 정보를 불러오지 못했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = '오류가 발생했습니다: $e';
      });
    }
  }

  Future<void> _confirmAction(String type) async {
    String title = '';
    switch (type) {
      case 'DEPOSIT':
        title = '입금 확인 처리를 하시겠습니까?';
        break;
      case 'BRANCH_DEPOSIT':
        title = '본사에 입금 확인 요청을 하시겠습니까?';
        break;
      case 'DELIVERY':
        title = '배송 완료 처리를 하시겠습니까?';
        break;
      case 'ORDER':
        title = '주문 확정 처리를 하시겠습니까?';
        break;
      case 'CANCEL':
        title = '주문을 취소하시겠습니까?';
        break;
      case 'SHIPPING':
        title = '배송 정보를 업데이트하시겠습니까?';
        break;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E1A47),
        title: const Text('확인', style: TextStyle(color: Colors.white)),
        content: Text(title, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9100)),
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _performAction(type);
    }
  }

  Future<void> _performAction(String type) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appService = RepositoryProvider.of<AppService>(context);
      bool success = false;

      switch (type) {
        case 'DEPOSIT':
          if (_selectedCarrierCode == null || _selectedCarrierCode!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('입금 확인 시 택배사를 먼저 선택해주세요.')),
            );
            setState(() => _isLoading = false);
            return;
          }
          final tracking = _trackingController.text.trim();
          if (tracking.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('입금 확인 시 운송장 번호를 입력해주세요.')),
            );
            setState(() => _isLoading = false);
            return;
          }
          success = await appService.confirmDeposit(_token!, _orderId!, _selectedCarrierCode!, tracking);
          break;
        case 'BRANCH_DEPOSIT':
          success = await appService.requestBranchDeposit(_token!, _orderId!);
          break;
        case 'DELIVERY':
          success = await appService.updateOrderStatus(_token!, _orderId!, '70');
          break;
        case 'ORDER':
          success = await appService.updateOrderStatus(_token!, _orderId!, '99');
          break;
        case 'SHIPPING':
          if (_selectedCarrierCode == null || _selectedCarrierCode!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('택배사를 먼저 선택해주세요.')),
            );
            setState(() => _isLoading = false);
            return;
          }
          final tracking = _trackingController.text.trim();
          if (tracking.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('운송장 번호를 입력해주세요.')),
            );
            setState(() => _isLoading = false);
            return;
          }
          success = await appService.updateShipping(_token!, _orderId!, _selectedCarrierCode!, tracking);
          break;
        case 'CANCEL':
          final req = OrderCancelRequest(
            orderId: _orderId!,
            cancelReason: '',
            userNo: 0,
          );
          success = await appService.cancelPayment(req);
          break;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('처리가 완료되었습니다.')),
        );
        _loadOrderDetail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('처리에 실패했습니다.')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
      setState(() => _isLoading = false);
    }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '주문 상세 관리',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9100)),
            )
          : _errorMsg != null
              ? Center(
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_orderDetailData == null) return const SizedBox.shrink();

    final order = _orderDetailData!['resultVo'] as Map<String, dynamic>? ?? {};

    final orderNo = order['orderNo'] ?? order['ORDER_NO'] ?? '';
    final orderDt = order['orderedAt'] ?? order['ORDERED_AT'] ?? order['ORDER_DATE'] ?? '';
    
    final status = (order['orderStatus'] ?? order['ORDER_STATUS'] ?? '').toString();
    final statusNm = (order['orderStatusNm'] ?? order['ORDER_STATUS_NM'] ?? status).toString();
    final depositStatusNm = (order['branchDepositStatusNm'] ?? order['BRANCH_DEPOSIT_STATUS_NM'] ?? '').toString();
    
    final displayStatus = depositStatusNm.isNotEmpty ? '$statusNm ($depositStatusNm)' : statusNm;

    final buyerName = order['receiverName'] ?? order['USER_NM'] ?? order['BRANCH_NAME'] ?? '';
    final buyerPhone = order['receiverPhone'] ?? order['TEL_NO'] ?? order['PHONE'] ?? '';
    
    final zip = order['zipCode'] ?? order['ZIP_CODE'] ?? '';
    final addr1 = order['address1'] ?? order['ADDRESS_MAIN'] ?? '';
    final addr2 = order['address2'] ?? order['ADDRESS_DETAIL'] ?? '';
    
    final memo = order['orderMemo'] ?? order['ORDER_MEMO'] ?? '없음';
    final carrierNm = order['deliveryCompanyNm'] ?? order['DELIVERY_COMPANY_NM'] ?? '';
    final trackingNo = order['trackingNo'] ?? order['TRACKING_NO'] ?? '';

    final branchDepositStatus = (order['branchDepositStatus'] ?? order['BRANCH_DEPOSIT_STATUS'] ?? '').toString();
    final isHQOrAdmin = (_memberCode == Constants.roleAdmin || _memberCode == Constants.roleSell);

    // Dynamic buttons visibility
    final showConfirmDeposit = isHQOrAdmin && (branchDepositStatus == '10' || branchDepositStatus == '20');
    final showBranchConfirmDeposit = (_memberCode == Constants.roleProj && (branchDepositStatus == '10' || branchDepositStatus == '20'));
    final showShippingInput = isHQOrAdmin && (status == '30' || status == '50' || status == '60');
    final showConfirmDelivery = isHQOrAdmin && status == '60';
    final showConfirmOrder = (_memberCode == Constants.roleProj && status == '70');
    final showCancelOrder = status != '40' && _memberCode != Constants.roleSell;
    final showUpdateShipping = isHQOrAdmin && branchDepositStatus == '30';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Basic Info Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayStatus,
                  style: const TextStyle(
                    color: Color(0xFFFF9100),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '주문번호: $orderNo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '주문일시: $orderDt',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Actions Card
          if (showConfirmDeposit || showBranchConfirmDeposit || showShippingInput || showConfirmDelivery || showConfirmOrder || showCancelOrder)
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📦 관리가능 처리',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (showConfirmDeposit) ...[
                    // Carrier Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF2E1A47),
                          value: _selectedCarrierLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                          items: [
                            const DropdownMenuItem<String>(
                              value: '선택하세요',
                              child: Text('선택하세요'),
                            ),
                            ..._carrierList.map((c) {
                              final name = (c['CODE_NM'] ?? c['codeNm'] ?? '').toString();
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              if (val == '선택하세요') {
                                setState(() {
                                  _selectedCarrierLabel = val;
                                  _selectedCarrierCode = null;
                                });
                              } else {
                                final idx = _carrierList.indexWhere((c) => (c['CODE_NM'] ?? c['codeNm'] ?? '').toString() == val);
                                if (idx >= 0) {
                                  setState(() {
                                    _selectedCarrierLabel = val;
                                    _selectedCarrierCode = (_carrierList[idx]['CODE'] ?? _carrierList[idx]['code'])?.toString();
                                  });
                                }
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Tracking No Input
                    TextField(
                      controller: _trackingController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '운송장 번호',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFF9100)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    ElevatedButton(
                      onPressed: () => _confirmAction('DEPOSIT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('입금 확인 (배송시작가능)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (showBranchConfirmDeposit) ...[
                    ElevatedButton(
                      onPressed: () => _confirmAction('BRANCH_DEPOSIT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('본사 입금 확인 요청', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (showShippingInput && !showConfirmDeposit) ...[
                    // Carrier Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF2E1A47),
                          value: _selectedCarrierLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                          items: [
                            const DropdownMenuItem<String>(
                              value: '선택하세요',
                              child: Text('선택하세요'),
                            ),
                            ..._carrierList.map((c) {
                              final name = (c['CODE_NM'] ?? c['codeNm'] ?? '').toString();
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              if (val == '선택하세요') {
                                setState(() {
                                  _selectedCarrierLabel = val;
                                  _selectedCarrierCode = null;
                                });
                              } else {
                                final idx = _carrierList.indexWhere((c) => (c['CODE_NM'] ?? c['codeNm'] ?? '').toString() == val);
                                if (idx >= 0) {
                                  setState(() {
                                    _selectedCarrierLabel = val;
                                    _selectedCarrierCode = (_carrierList[idx]['CODE'] ?? _carrierList[idx]['code'])?.toString();
                                  });
                                }
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Tracking No Input
                    TextField(
                      controller: _trackingController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '운송장 번호',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFF9100)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    ElevatedButton(
                      onPressed: () => _confirmAction('SHIPPING'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('배송 정보 업데이트', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (showConfirmDelivery) ...[
                    ElevatedButton(
                      onPressed: () => _confirmAction('DELIVERY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('배송 완료 처리', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (showConfirmOrder) ...[
                    ElevatedButton(
                      onPressed: () => _confirmAction('ORDER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('주문 확정 처리', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (showCancelOrder) ...[
                    ElevatedButton(
                      onPressed: () => _confirmAction('CANCEL'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('주문 취소', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),

          // Customer & Shipping Info Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 주문 및 배송 정보',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Text(
                  '주문자: $buyerName ($buyerPhone)',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  '주소: ($zip) $addr1 $addr2',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  '배송메모: $memo',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
                
                if (carrierNm.toString().isNotEmpty || trackingNo.toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 6),
                  Text(
                    '현재배송: $carrierNm ($trackingNo)',
                    style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),

          // Product List Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📦 상품 목록',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _orderItems.length,
                  itemBuilder: (context, index) {
                    final item = _orderItems[index];

                    final pName = item['productName'] ?? item['PRODUCT_NAME'] ?? item['TITLE'] ?? '';
                    final qtyVal = double.tryParse((item['quantity'] ?? item['QUANTITY'] ?? 0).toString()) ?? 0.0;
                    final priceVal = double.tryParse((item['unitPrice'] ?? item['UNIT_PRICE'] ?? 0).toString()) ?? 0.0;
                    
                    final totalItemPrice = qtyVal * priceVal;

                    final formattedQty = qtyVal.toInt().toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    );

                    final formattedTotal = totalItemPrice.toInt().toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (index > 0) ...[
                          const Divider(color: Colors.white10, height: 16),
                        ],
                        Text(
                          pName,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$formattedQty개',
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                            ),
                            Text(
                              '₩$formattedTotal',
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}
