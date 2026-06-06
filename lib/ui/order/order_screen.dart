import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/service/app_service.dart';
import '../../data/models/order_models.dart';
import '../../data/models/address_book_vo.dart';
import '../../data/models/simple_result_response.dart';
import '../../core/constants.dart';

class OrderScreen extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const OrderScreen({
    super.key,
    required this.arguments,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _orderMemoController = TextEditingController();

  bool _saveAddress = false;
  bool _isLoading = false;

  String? _token;
  int _userNo = 0;
  String _branchId = '';

  int _productId = 0;
  String _productName = '';
  int _unitPrice = 0;
  String _selectedOption = '';
  int _quantity = 1;
  String? _productImage;
  String _productBranchId = '';

  int _deliveryFee = 0;
  int _totalItemAmount = 0;
  int _totalPayAmount = 0;

  @override
  void initState() {
    super.initState();
    _parseArguments();
    _loadCredentialsAndDefaultAddress();
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _zipCodeController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _orderMemoController.dispose();
    super.dispose();
  }

  void _parseArguments() {
    _productId = widget.arguments['productId'] as int? ?? 0;
    _productName = widget.arguments['productName'] as String? ?? '';
    _unitPrice = widget.arguments['unitPrice'] as int? ?? 0;
    _selectedOption = widget.arguments['selectedOption'] as String? ?? '';
    _quantity = widget.arguments['quantity'] as int? ?? 1;
    _productImage = widget.arguments['productImage'] as String?;
    _productBranchId = widget.arguments['branchId']?.toString() ?? '';

    _totalItemAmount = _unitPrice * _quantity;
  }

  Future<void> _loadCredentialsAndDefaultAddress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('saved_token');
      _userNo = int.tryParse(prefs.getString('saved_login_idx') ?? '') ?? 0;
      _branchId = prefs.getString('saved_branch_id') ?? '';

      // Calculate Shipping Cost
      final baseShippingFee = prefs.getInt('saved_base_shipping_fee') ?? 3000;
      final freeThreshold = prefs.getInt('saved_free_shipping_threshold') ?? 50000;

      setState(() {
        _deliveryFee = _totalItemAmount >= freeThreshold ? 0 : baseShippingFee;
        _totalPayAmount = _totalItemAmount + _deliveryFee;
      });

      if (_token != null && _token!.isNotEmpty) {
        final appService = RepositoryProvider.of<AppService>(context);
        final addresses = await appService.getAddressList(_token!);
        if (addresses.isNotEmpty) {
          final defaultAddr = addresses.firstWhere(
            (addr) => addr.isDefault == 1 || addr.isDefault == true,
            orElse: () => addresses.first,
          );
          _applyAddress(defaultAddr);
        }
      }
    } catch (_) {
      // Ignore
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyAddress(TbAddressBookVo addr) {
    setState(() {
      _receiverNameController.text = addr.recipientName;
      _receiverPhoneController.text = addr.recipientPhone;
      _zipCodeController.text = addr.zipCode;
      _address1Controller.text = addr.addressMain;
      _address2Controller.text = addr.addressDetail;
    });
  }

  Future<void> _showAddressBookDialog() async {
    if (_token == null) return;
    final appService = RepositoryProvider.of<AppService>(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final list = await appService.getAddressList(_token!);
      setState(() {
        _isLoading = false;
      });

      if (list.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장된 배송지가 없습니다.')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2E1A47),
            title: const Text('최근 배송지 선택', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (ctx, idx) {
                  final addr = list[idx];
                  return ListTile(
                    title: Text(addr.recipientName, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${addr.addressMain} ${addr.addressDetail}', style: const TextStyle(color: Colors.white70)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _applyAddress(addr);
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('배송지 로드 실패: $e')),
      );
    }
  }

  Future<void> _searchAddress() async {
    final result = await Navigator.pushNamed(context, '/addressSearch');
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _zipCodeController.text = result['zipCode']?.toString() ?? '';
        _address1Controller.text = result['address']?.toString() ?? '';
      });
    }
  }

  bool _validateInputs() {
    if (_receiverNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수령인 이름을 입력해주세요.')));
      return false;
    }
    if (_receiverPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('연락처를 입력해주세요.')));
      return false;
    }
    if (_address1Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('주소를 검색해주세요.')));
      return false;
    }
    return true;
  }

  void _showPaymentConfirmDialog() {
    if (!_validateInputs()) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E1A47),
          title: const Text('결제 확인', style: TextStyle(color: Colors.white)),
          content: Text(
            '$_productName을(를) ${_totalPayAmount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}원에 결제하시겠습니까?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _createOrder();
              },
              child: const Text('결제하기', style: TextStyle(color: Color(0xFFFF9100))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createOrder() async {
    if (_token == null) return;

    setState(() {
      _isLoading = true;
    });

    final appService = RepositoryProvider.of<AppService>(context);

    try {
      // Save address if checked
      if (_saveAddress) {
        final addressBook = TbAddressBookVo(
          recipientName: _receiverNameController.text.trim(),
          recipientPhone: _receiverPhoneController.text.trim(),
          zipCode: _zipCodeController.text.trim(),
          addressMain: _address1Controller.text.trim(),
          addressDetail: _address2Controller.text.trim(),
          isDefault: 1,
          memo: _orderMemoController.text.trim(),
        );
        await appService.addAddress(_token!, addressBook);
      }

      final req = OrderCreateRequest(
        userNo: _userNo,
        totalItemAmount: _totalItemAmount,
        deliveryFee: _deliveryFee,
        discountAmount: 0,
        totalPayAmount: _totalPayAmount,
        receiverName: _receiverNameController.text.trim(),
        receiverPhone: _receiverPhoneController.text.trim(),
        zipCode: _zipCodeController.text.trim(),
        address1: _address1Controller.text.trim(),
        address2: _address2Controller.text.trim(),
        orderMemo: _orderMemoController.text.trim(),
        branchId: int.tryParse(_productBranchId),
        items: [
          OrderItemRequest(
            productId: _productId,
            quantity: _quantity,
            optionName: _selectedOption,
          ),
        ],
      );

      final response = await appService.createOrder(req);
      if (response != null && response.success == true) {
        // Launch Payment WebView Screen
        final payResult = await Navigator.pushNamed(context, '/paymentWebview', arguments: {
          'orderId': response.orderId.toString(),
          'orderNo': response.orderNo,
          'amount': response.amount,
          'productName': response.orderName,
        });

        if (payResult != null && payResult is Map<String, dynamic>) {
          if (payResult['status'] == 'SUCCESS') {
            Navigator.pushReplacementNamed(context, '/orderSuccess', arguments: {
              'orderId': payResult['orderId']?.toString() ?? '',
              'orderNo': payResult['orderNo']?.toString() ?? '',
              'amount': payResult['amount'] as int? ?? 0,
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(payResult['message']?.toString() ?? '결제에 실패했습니다.')),
            );
          }
        }
      } else {
        final errMsg = response != null ? response.message : '서버 오류';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주문 생성 실패: $errMsg')),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주문 중 오류 발생: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E1A47),
        title: const Text('주문하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9100)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Preview Card
                  Card(
                    color: Colors.white.withOpacity(0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (_productImage != null && _productImage!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(_productImage!, width: 70, height: 70, fit: BoxFit.cover),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_productName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 6),
                                Text('옵션: $_selectedOption / $_quantity개', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recipient Form
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('배송 정보', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton(
                        onPressed: _showAddressBookDialog,
                        child: const Text('최근 배송지 선택', style: TextStyle(color: Color(0xFFFF9100))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTextField('수령인 이름', _receiverNameController, '이름을 입력해 주세요'),
                  const SizedBox(height: 14),
                  _buildTextField('연락처', _receiverPhoneController, '전화번호를 입력해 주세요 (예: 010-0000-0000)', keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('우편번호', _zipCodeController, '우편번호', readOnly: true)),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E1A47),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                        onPressed: _searchAddress,
                        child: const Text('우편번호 검색', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildTextField('기본 주소', _address1Controller, '우편번호를 검색해 주세요', readOnly: true),
                  const SizedBox(height: 14),
                  _buildTextField('상세 주소', _address2Controller, '상세 주소를 입력해 주세요'),
                  const SizedBox(height: 14),
                  _buildTextField('배송 메모', _orderMemoController, '배송 시 요청사항을 적어주세요'),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Checkbox(
                        value: _saveAddress,
                        activeColor: const Color(0xFFFF9100),
                        onChanged: (val) {
                          setState(() {
                            _saveAddress = val ?? false;
                          });
                        },
                      ),
                      const Text('기본 배송지로 저장', style: TextStyle(color: Colors.white70)),
                    ],
                  ),

                  const Divider(color: Colors.white24, height: 40),

                  // Receipt Breakdown
                  const Text('결제 금액 정보', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildAmountRow('상품 금액 합계', _totalItemAmount),
                  const SizedBox(height: 8),
                  _buildAmountRow('배송비', _deliveryFee),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('최종 결제 금액', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '${_totalPayAmount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}원',
                        style: const TextStyle(color: Color(0xFFFF9100), fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9100),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _showPaymentConfirmDialog,
                    child: const Text('주문하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFF9100)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(
          '${amount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}원',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}
