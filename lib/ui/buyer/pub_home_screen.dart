import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/constants.dart';
import '../../domain/service/app_service.dart';
import '../../data/models/ad_item.dart';
import '../../data/models/ad_list_request.dart';
import '../widgets/app_drawer.dart';

class PubHomeScreen extends StatefulWidget {
  const PubHomeScreen({super.key});

  @override
  State<PubHomeScreen> createState() => _PubHomeScreenState();
}

class _PubHomeScreenState extends State<PubHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  String _memberCode = '';
  String _branchName = '';
  String _token = '';
  bool _isLoadingSession = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _memberCode = prefs.getString('saved_member_code') ?? '';
      _branchName = prefs.getString('saved_branch_name') ?? '';
      _token = prefs.getString('saved_token') ?? '';
      _isLoadingSession = false;
    });
  }

  String _formatPrice(String priceStr) {
    try {
      final parsed = double.parse(priceStr).toInt();
      final str = parsed.toString();
      final chars = str.split('');
      final list = <String>[];
      for (int i = 0; i < chars.length; i++) {
        if (i > 0 && (chars.length - i) % 3 == 0) {
          list.add(',');
        }
        list.add(chars[i]);
      }
      return '${list.join()}원';
    } catch (_) {
      return '$priceStr원';
    }
  }

  void _onProductTap(AdItem item) {
    if (item.productId != null) {
      Navigator.pushNamed(context, '/adDetail', arguments: item.productId.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSession) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E2C),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9100)),
        ),
      );
    }

    final isSellerOrWholesaler =
        _memberCode == Constants.roleSell || _memberCode == Constants.roleProj;

    final appBarTitle = _branchName.isNotEmpty
        ? '($_branchName) 상품리스트'
        : '상품리스트';

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: isSellerOrWholesaler
          ? _buildSellerTabbedView(appBarTitle)
          : _buildBuyerFilterView(appBarTitle),
    );
  }

  // === Seller & Wholesaler tabbed layout (MainActivity.kt counterpart) ===
  Widget _buildSellerTabbedView(String title) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFF1E1E2C),
        drawer: const AppDrawer(currentRoute: '/pubHome'),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E1A47),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color(0xFFFF9100),
            labelColor: Color(0xFFFF9100),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: '판매중'),
              Tab(text: '품절'),
              Tab(text: '판매중지'),
              Tab(text: '판매완료'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SellerProductList(
              saleStatus: '1',
              token: _token,
              memberCode: _memberCode,
              onTap: _onProductTap,
              formatPrice: _formatPrice,
            ),
            SellerProductList(
              saleStatus: '20',
              token: _token,
              memberCode: _memberCode,
              onTap: _onProductTap,
              formatPrice: _formatPrice,
            ),
            SellerProductList(
              saleStatus: '30',
              token: _token,
              memberCode: _memberCode,
              onTap: _onProductTap,
              formatPrice: _formatPrice,
            ),
            SellerProductList(
              saleStatus: '99',
              token: _token,
              memberCode: _memberCode,
              onTap: _onProductTap,
              formatPrice: _formatPrice,
            ),
          ],
        ),
      ),
    );
  }

  // === Buyer filter search view (HomeFragment.kt counterpart) ===
  Widget _buildBuyerFilterView(String title) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF1E1E2C),
      drawer: const AppDrawer(currentRoute: '/pubHome'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E1A47),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: BuyerProductList(
          token: _token,
          onTap: _onProductTap,
          formatPrice: _formatPrice,
        ),
      ),
    );
  }
}

// =========================================================================
// Seller Product List Widget (Tab Page)
// =========================================================================
class SellerProductList extends StatefulWidget {
  final String saleStatus;
  final String token;
  final String memberCode;
  final void Function(AdItem) onTap;
  final String Function(String) formatPrice;

  const SellerProductList({
    super.key,
    required this.saleStatus,
    required this.token,
    required this.memberCode,
    required this.onTap,
    required this.formatPrice,
  });

  @override
  State<SellerProductList> createState() => _SellerProductListState();
}

class _SellerProductListState extends State<SellerProductList> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  
  List<AdItem> _items = [];
  int _pageNo = 1;
  bool _isLoading = false;
  bool _isLastPage = false;
  bool _isInitialLoad = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchProducts(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts({bool isRefresh = false}) async {
    if (_isLoading || (!isRefresh && _isLastPage)) return;

    setState(() {
      _isLoading = true;
    });

    if (isRefresh) {
      _pageNo = 1;
      _isLastPage = false;
    }

    try {
      final appService = RepositoryProvider.of<AppService>(context);
      final req = AdListRequest(
        token: widget.token,
        adCode: 1,
        pageno: _pageNo,
        saleStatus: widget.saleStatus,
        memberCode: widget.memberCode,
      );

      final newItems = await appService.getAdvertiseList(req);
      
      if (mounted) {
        setState(() {
          if (isRefresh) {
            _items = newItems;
          } else {
            _items.addAll(newItems);
          }
          _isLastPage = newItems.isEmpty;
          if (newItems.isNotEmpty) {
            _pageNo++;
          }
          _isInitialLoad = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLastPage = true;
          _isInitialLoad = false;
        });
      }
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
    super.build(context);

    if (_isInitialLoad && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF9100)),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchProducts(isRefresh: true),
        color: const Color(0xFFFF9100),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            const Center(
              child: Text(
                '등록된 상품이 없습니다.',
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchProducts(isRefresh: true),
      color: const Color(0xFFFF9100),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _items.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF9100)),
              ),
            );
          }

          final item = _items[index];
          return _buildProductCard(item);
        },
      ),
    );
  }

  Widget _buildProductCard(AdItem item) {
    final hasStatusBadge = item.saleStatusNm != null && item.saleStatusNm != '판매중';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => widget.onTap(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 90,
                      height: 90,
                      color: Colors.white.withOpacity(0.05),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white30,
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasStatusBadge)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.saleStatusNm!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.formatPrice(item.price),
                      style: const TextStyle(
                        color: Color(0xFFFF9100),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// Buyer Product List Widget (HomeFragment.kt counterpart)
// =========================================================================
class BuyerProductList extends StatefulWidget {
  final String token;
  final void Function(AdItem) onTap;
  final String Function(String) formatPrice;

  const BuyerProductList({
    super.key,
    required this.token,
    required this.onTap,
    required this.formatPrice,
  });

  @override
  State<BuyerProductList> createState() => _BuyerProductListState();
}

class _BuyerProductListState extends State<BuyerProductList> {
  final ScrollController _scrollController = ScrollController();

  List<AdItem> _items = [];
  int _pageNo = 1;
  bool _isLoading = false;
  bool _isLastPage = false;
  bool _isInitialLoad = true;

  // Filters State
  bool _saleOnly = true;
  bool _enablePriceFilter = false;
  RangeValues _priceRange = const RangeValues(0, 200000);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchProducts(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts({bool isRefresh = false}) async {
    if (_isLoading || (!isRefresh && _isLastPage)) return;

    setState(() {
      _isLoading = true;
    });

    if (isRefresh) {
      _pageNo = 1;
      _isLastPage = false;
    }

    try {
      final appService = RepositoryProvider.of<AppService>(context);
      
      final req = AdListRequest(
        token: widget.token,
        adCode: 1,
        pageno: _pageNo,
        saleStatus: _saleOnly ? '1' : '0',
        minPrice: _enablePriceFilter ? _priceRange.start.toInt() : null,
        maxPrice: _enablePriceFilter ? _priceRange.end.toInt() : null,
      );

      final newItems = await appService.getBuyAdvertiseList(req);

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _items = newItems;
          } else {
            _items.addAll(newItems);
          }
          _isLastPage = newItems.isEmpty;
          if (newItems.isNotEmpty) {
            _pageNo++;
          }
          _isInitialLoad = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLastPage = true;
          _isInitialLoad = false;
        });
      }
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
    return Column(
      children: [
        // Filter Panel
        _buildFilterPanel(),
        
        // Items List
        Expanded(
          child: _isInitialLoad && _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF9100)),
                )
              : _items.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () => _fetchProducts(isRefresh: true),
                      color: const Color(0xFFFF9100),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          const Center(
                            child: Text(
                              '검색된 상품이 없습니다.',
                              style: TextStyle(color: Colors.white38, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _fetchProducts(isRefresh: true),
                      color: const Color(0xFFFF9100),
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: _items.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(color: Color(0xFFFF9100)),
                              ),
                            );
                          }

                          final item = _items[index];
                          return _buildProductCard(item);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterPanel() {
    final format = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final minF = _priceRange.start.toInt().toString().replaceAllMapped(format, (Match m) => '${m[1]},');
    final maxF = _priceRange.end.toInt().toString().replaceAllMapped(format, (Match m) => '${m[1]},');

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Sale only checkbox
              Checkbox(
                value: _saleOnly,
                activeColor: const Color(0xFFFF9100),
                onChanged: (val) {
                  setState(() {
                    _saleOnly = val ?? true;
                  });
                  _fetchProducts(isRefresh: true);
                },
              ),
              const Text(
                '판매중인 상품만',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              // Price filter checkbox
              Checkbox(
                value: _enablePriceFilter,
                activeColor: const Color(0xFFFF9100),
                onChanged: (val) {
                  setState(() {
                    _enablePriceFilter = val ?? false;
                  });
                },
              ),
              const Text(
                '희망 단가로 조회',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (_enablePriceFilter) ...[
            const SizedBox(height: 12),
            const Text(
              '희망 단가 범위 설정',
              style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${minF}원',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Expanded(
                  child: RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 200000,
                    divisions: 200,
                    activeColor: const Color(0xFFFF9100),
                    inactiveColor: Colors.white10,
                    onChanged: (values) {
                      setState(() {
                        _priceRange = values;
                      });
                    },
                  ),
                ),
                Text(
                  '${maxF}원',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Text(
                      '선택 범위: $minF ~ $maxF 원',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _fetchProducts(isRefresh: true),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('조회하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9100),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildProductCard(AdItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => widget.onTap(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 90,
                      height: 90,
                      color: Colors.white.withOpacity(0.05),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white30,
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.formatPrice(item.price),
                      style: const TextStyle(
                        color: Color(0xFFFF9100),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
