import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/service/app_service.dart';

class OrderMgtScreen extends StatefulWidget {
  const OrderMgtScreen({super.key});

  @override
  State<OrderMgtScreen> createState() => _OrderMgtScreenState();
}

class _OrderMgtScreenState extends State<OrderMgtScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  String? _token;
  String? _errorMsg;

  List<Map<String, dynamic>> _orderList = [];
  
  String? _selectedStatusCode;
  String _selectedStatusLabel = '전체 상태';

  String? _startDate;
  String? _endDate;

  final List<String> _statusList = [
    '전체 상태',
    '결제대기(10)',
    '결제완료(30)',
    '주문취소(40)',
    '배송준비(50)',
    '배송중(60)',
    '배송완료(70)',
    '반품요청(80)',
    '반품완료(89)',
    '주문확정(99)',
  ];

  final List<String?> _statusCodes = [
    null,
    '10',
    '30',
    '40',
    '50',
    '60',
    '70',
    '80',
    '89',
    '99',
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('saved_token');

    if (_token == null || _token!.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMsg = '세션 정보가 없습니다. 다시 로그인해 주세요.';
      });
      return;
    }

    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final appService = RepositoryProvider.of<AppService>(context);
      final result = await appService.getOrderMgtList(
        token: _token!,
        orderStatus: _selectedStatusCode,
        orderStDt: _startDate,
        orderEdDt: _endDate,
        searchKeyword: _searchController.text.trim(),
      );

      if (result != null) {
        final list = result['resultList'] as List<dynamic>?;
        setState(() {
          _orderList = (list ?? []).map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMsg = '주문 목록을 불러오지 못했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = '오류가 발생했습니다: $e';
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 305)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF9100),
              onPrimary: Colors.white,
              surface: Color(0xFF2E1A47),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = "${picked.start.year}-${picked.start.month.toString().padLeft(2, '0')}-${picked.start.day.toString().padLeft(2, '0')}";
        _endDate = "${picked.end.year}-${picked.end.month.toString().padLeft(2, '0')}-${picked.end.day.toString().padLeft(2, '0')}";
      });
      _loadOrders();
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
          '주문 통합 관리',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter section
          _buildFilterSection(),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF9100)),
                  )
                : RefreshIndicator(
                    color: const Color(0xFFFF9100),
                    onRefresh: _loadOrders,
                    child: _buildOrderList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          // Search input & button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '검색어 (주문번호, 지점명)',
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
                  onSubmitted: (_) => _loadOrders(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadOrders,
                icon: const Icon(Icons.search, color: Color(0xFFFF9100)),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Status Spinner & Date Range Picker
          Row(
            children: [
              // Status selector
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: const Color(0xFF2E1A47),
                      value: _selectedStatusLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      items: _statusList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final idx = _statusList.indexOf(val);
                          setState(() {
                            _selectedStatusLabel = val;
                            _selectedStatusCode = _statusCodes[idx];
                          });
                          _loadOrders();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Date range button
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            (_startDate != null && _endDate != null)
                                ? '$_startDate ~ $_endDate'
                                : '기간 선택',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    if (_errorMsg != null) {
      return Center(
        child: Text(
          _errorMsg!,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    if (_orderList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const Center(
            child: Text(
              '주문 내역이 없습니다.',
              style: TextStyle(color: Colors.white38),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _orderList.length,
      itemBuilder: (context, index) {
        final order = _orderList[index];

        final branchNm = order['BRANCH_NAME'] ?? order['branchName'] ?? order['USER_NM'] ?? order['userNm'] ?? '';
        final orderDt = order['ORDERED_AT'] ?? order['orderedAt'] ?? order['ORDER_DATE'] ?? order['orderDate'] ?? '';
        final orderNo = order['ORDER_NO'] ?? order['orderNo'] ?? '';
        final statusNm = order['ORDER_STATUS_NM'] ?? order['orderStatusNm'] ?? order['ORDER_STATUS'] ?? order['orderStatus'] ?? '';
        final status = (order['ORDER_STATUS'] ?? order['orderStatus'] ?? '').toString();
        final orderId = (order['ORDER_ID'] ?? order['orderId'] ?? '').toString();

        final amtVal = double.tryParse((order['TOTAL_PAY_AMOUNT'] ?? order['totalPayAmount'] ?? order['SUPPLY_PRICE_SUM'] ?? order['supplyPriceSum'] ?? 0).toString()) ?? 0.0;
        final formattedAmt = amtVal.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

        return Card(
          color: Colors.white.withOpacity(0.06),
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (orderId.isNotEmpty) {
                Navigator.pushNamed(
                  context,
                  '/orderMgtDetail',
                  arguments: orderId,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            branchNm,
                            style: const TextStyle(
                              color: Color(0xFFFF9100),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            orderDt,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      _buildOrderStatusBadge(statusNm, status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          orderNo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₩$formattedAmt',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderStatusBadge(String statusNm, String status) {
    Color bg;
    Color fg;

    switch (status) {
      case '30':
      case '70':
      case '99':
        bg = Colors.greenAccent.withOpacity(0.12);
        fg = Colors.greenAccent;
        break;
      case '40':
      case '80':
      case '89':
        bg = Colors.redAccent.withOpacity(0.12);
        fg = Colors.redAccent;
        break;
      case '10':
      case '50':
      case '60':
      default:
        bg = const Color(0xFFFF9100).withOpacity(0.12);
        fg = const Color(0xFFFF9100);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusNm.isEmpty ? '대기 중' : statusNm,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
