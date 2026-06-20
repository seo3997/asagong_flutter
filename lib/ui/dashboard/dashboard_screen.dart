import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../domain/service/app_service.dart';
import '../../core/constants.dart';
import '../widgets/app_drawer.dart';
import '../../main.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  String _memberCode = '';
  String _branchName = '';
  String? _token;
  
  Map<String, dynamic>? _dashboardData;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndHandlePendingPush();
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('saved_token');
      _memberCode = prefs.getString('saved_member_code') ?? '';
      _branchName = prefs.getString('saved_branch_name') ?? '';

      if (_token == null || _token!.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMsg = '세션 정보가 없습니다. 다시 로그인해 주세요.';
        });
        return;
      }

      final appService = RepositoryProvider.of<AppService>(context);
      final data = await appService.getDashboardMgtData(_token!);

      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = '데이터 로딩 중 오류가 발생했습니다: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFF1E1E2C),
        drawer: const AppDrawer(currentRoute: '/dashboard'),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E1A47),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: const Text(
            '대시보드',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/notificationList');
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF9100)),
              )
            : RefreshIndicator(
                color: const Color(0xFFFF9100),
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMsg != null) ...[
                        Text(
                          _errorMsg!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Welcome & Action Buttons Header
                      _buildHeaderSection(),
                      const SizedBox(height: 16),

                      // Notice card for branch deposit
                      _buildNoticeCard(),

                      // Statistics Block
                      const Text(
                        '대시보드 통계 현황',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatsBlock(_memberCode, _dashboardData?['dashboardStats'] as Map<String, dynamic>?),
                      const SizedBox(height: 28),

                      // Recent Orders List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '최근 주문 현황',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/orderMgt');
                            },
                            child: const Text(
                              '전체보기 >',
                              style: TextStyle(color: Color(0xFFFF9100)),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildRecentOrdersList(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    String titleText = '대시보드';
    if (_memberCode == Constants.roleAdmin) {
      titleText = '시스템 관리자 모드';
    } else if (_memberCode == Constants.roleSell) {
      titleText = '본사 통합 관리 시스템';
    } else if (_memberCode == Constants.roleProj) {
      titleText = '지점 판매 어드민\n[$_branchName]';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '안녕하세요!',
          style: TextStyle(fontSize: 14, color: Colors.white54),
        ),
        const SizedBox(height: 4),
        Text(
          titleText,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeCard() {
    if (_memberCode != Constants.roleProj || _dashboardData == null) {
      return const SizedBox.shrink();
    }
    final hq = _dashboardData!['headQuarterBranch'] as Map<String, dynamic>?;
    if (hq == null) return const SizedBox.shrink();

    final bank = hq['BANK_NM'] ?? hq['bankNm'] ?? '';
    final acc = hq['ACCOUNT_NO'] ?? hq['accountNo'] ?? '';
    final holder = hq['ACCOUNT_HOLDER'] ?? hq['accountHolder'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF9100), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '본사 입금 안내: $bank $acc (예금주: $holder)로 입금하셔야 배송이 시작됩니다.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBlock(String role, Map<String, dynamic>? stats) {
    if (stats == null) return const SizedBox.shrink();

    List<Map<String, dynamic>> cards = [];
    if (role == Constants.roleAdmin) {
      cards = [
        {'label': '총 사용자 수', 'value': stats['totalUsers'], 'color': const Color(0xFF6366F1), 'isCurrency': false},
        {'label': '지점 수', 'value': stats['totalBranches'], 'color': const Color(0xFF6366F1), 'isCurrency': false},
        {'label': '누적 주문', 'value': stats['totalOrders'], 'color': const Color(0xFFEF4444), 'isCurrency': false},
        {'label': '누적 매출', 'value': stats['totalRevenue'], 'color': const Color(0xFF10B981), 'isCurrency': true},
      ];
    } else if (role == Constants.roleSell) {
      cards = [
        {'label': '미처리 주문', 'value': stats['unprocessedOrders'], 'color': const Color(0xFF6366F1), 'isCurrency': false},
        {'label': '지점 미입금액', 'value': stats['branchPendingAmount'], 'color': const Color(0xFFEF4444), 'isCurrency': true},
        {'label': '오늘의 수금액', 'value': stats['todayCollectionAmount'], 'color': const Color(0xFF10B981), 'isCurrency': true},
        {'label': '배송 중', 'value': stats['inTransit'], 'color': const Color(0xFF3B82F6), 'isCurrency': false},
      ];
    } else if (role == Constants.roleProj) {
      cards = [
        {'label': '오늘의 매출', 'value': stats['todayTotalSales'], 'color': const Color(0xFF10B981), 'isCurrency': true},
        {'label': '예상 순이익', 'value': stats['estimatedProfit'], 'color': const Color(0xFF6366F1), 'isCurrency': true},
        {'label': '본사 송금 대기', 'value': stats['remittancePending'], 'color': const Color(0xFFEF4444), 'isCurrency': false},
        {'label': '이달의 주문', 'value': stats['completedOrders'], 'color': const Color(0xFF3B82F6), 'isCurrency': false},
      ];
    } else {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: cards.length,
      itemBuilder: (context, idx) {
        final card = cards[idx];
        final val = card['value'];
        final isCurrency = card['isCurrency'] as bool;
        final color = card['color'] as Color;

        String valStr = '0';
        if (val != null) {
          final doubleVal = double.tryParse(val.toString()) ?? 0.0;
          if (isCurrency) {
            valStr = doubleVal.toInt().toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            );
            valStr = '₩$valStr';
          } else {
            valStr = '${doubleVal.toInt()}건';
          }
        } else {
          valStr = isCurrency ? '₩0' : '0건';
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                card['label'] as String,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                valStr,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentOrdersList() {
    final orders = (_dashboardData?['dashboardOrderList'] as List<dynamic>?) ?? [];

    if (orders.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: const Center(
          child: Text(
            '최근 주문 내역이 없습니다.',
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index] as Map<String, dynamic>;

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

    // Adjust color based on order status code:
    // 10: 결제대기, 30: 결제완료, 40: 주문취소, 50: 배송준비, 60: 배송중, 70: 배송완료, 80: 반품요청, 89: 반품완료, 99: 주문확정
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
