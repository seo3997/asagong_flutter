import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants.dart';
import '../../domain/service/app_service.dart';
import '../../data/models/product_detail_response.dart';
import '../../data/models/product_vo.dart';
import '../../data/models/product_image_vo.dart';
import '../../data/models/review_models.dart';
import '../../data/models/qna_models.dart';
import '../../data/models/chat_models.dart';
import '../../data/models/product_approval_request.dart';
import '../../data/models/simple_result_response.dart';
import '../../data/models/approval_status.dart';

class AdDetailScreen extends StatefulWidget {
  final String productId;

  const AdDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _memberCode = '';
  String _userId = '';
  int _userNo = 0;
  String? _token;
  String _branchId = '';

  ProductDetailResponse? _detail;
  List<ReviewItem> _reviews = [];
  List<QnaItem> _qnas = [];
  bool _isFav = false;

  int _orderQuantity = 1;
  int _maxQuantity = 1;
  int _baseShippingFee = 3000;
  int _freeThreshold = 50000;
  double _webViewHeight = 500;

  WebViewController? _webViewController;

  String _decodeHtml(String html) {
    return html
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'");
  }

  Future<void> _updateWebViewHeight() async {
    if (_webViewController == null) return;
    try {
      final result = await _webViewController!.runJavaScriptReturningResult(
        "Math.max(document.body.scrollHeight, document.documentElement.scrollHeight, document.body.offsetHeight, document.documentElement.offsetHeight, document.body.clientHeight, document.documentElement.clientHeight);"
      );
      if (result != null) {
        final cleanResult = result.toString().replaceAll('"', '').replaceAll("'", '').trim();
        final heightVal = double.tryParse(cleanResult);
        if (heightVal != null && heightVal > 0) {
          if (mounted) {
            setState(() {
              _webViewHeight = heightVal + 20.0;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to get webview height: $e");
    }
  }

  Widget? _buildFAB() {
    final isBuyer = (_memberCode == Constants.rolePub);
    switch (_tabController.index) {
      case 0:
        if (isBuyer) return null;
        return FloatingActionButton.extended(
          backgroundColor: const Color(0xFFFF9100),
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          label: const Text('채팅하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: _handleFabClick,
        );
      case 1:
        if (!isBuyer) return null;
        return FloatingActionButton.extended(
          backgroundColor: const Color(0xFFFF9100),
          label: const Text('리뷰 등록', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/reviewWrite', arguments: {
              'productId': int.tryParse(widget.productId) ?? 0,
            }).then((success) {
              if (success == true) _loadAllData();
            });
          },
        );
      case 2:
        if (!isBuyer) return null;
        return FloatingActionButton.extended(
          backgroundColor: const Color(0xFFFF9100),
          label: const Text('문의 등록', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/qnaWrite', arguments: {
              'productId': int.tryParse(widget.productId) ?? 0,
            }).then((success) {
              if (success == true) _loadAllData();
            });
          },
        );
      default:
        return null;
    }
  }

  Widget? _buildBottomDock() {
    if (_detail == null) return null;
    final isBuyer = (_memberCode == Constants.rolePub);
    if (!isBuyer) return null;

    final product = _detail!.product;
    final price = double.tryParse(product.price) ?? 0.0;
    final totalPrice = price * _orderQuantity;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2E1A47),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: Row(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.08),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              onPressed: _handleFabClick,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('채팅하기', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: product.saleStatus == '1'
                    ? () {
                        final representImg = _detail?.imageMetas.firstWhere(
                          (img) => img.represent == '1',
                          orElse: () => ProductImageVo(represent: '1', imageUrl: ''),
                        ).imageUrl ?? '';

                        Navigator.pushNamed(context, '/order', arguments: {
                          'productId': int.tryParse(product.productId ?? '') ?? 0,
                          'productName': product.title,
                          'unitPrice': (double.tryParse(product.price) ?? 0.0).toInt(),
                          'selectedOption': product.unitCodeNm,
                          'quantity': _orderQuantity,
                          'productImage': representImg,
                          'branchId': product.branchId,
                        });
                      }
                    : null,
                child: Text(
                  product.saleStatus == '1' ? '구매하기' : '판매 완료',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('saved_token');
      _memberCode = prefs.getString('saved_member_code') ?? '';
      _userId = prefs.getString('saved_user_id') ?? '';
      _userNo = int.tryParse(prefs.getString('saved_login_idx') ?? '') ?? 0;
      _branchId = prefs.getString('saved_branch_id') ?? '';

      final appService = RepositoryProvider.of<AppService>(context);
      final productIdVal = int.tryParse(widget.productId) ?? 0;

      // 1. Load detail
      final detail = await appService.getProductDetail(productIdVal, _userNo);
      _baseShippingFee = prefs.getInt('saved_base_shipping_fee') ?? 3000;
      _freeThreshold = prefs.getInt('saved_free_shipping_threshold') ?? 50000;

      if (detail != null) {
        _detail = detail;
        _isFav = detail.product.fav == '1';
        _maxQuantity = int.tryParse(detail.product.availableQuantity) ?? 1;
        if (_maxQuantity < 1) _maxQuantity = 1;

        final editorMode = detail.product.editorMode;
        if (editorMode == '1' || editorMode == '2') {
          var description = detail.product.description;
          if (description.contains('&lt;') || description.contains('&gt;')) {
            description = _decodeHtml(description);
          }
          final htmlContent = """
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=0.5, maximum-scale=5.0, user-scalable=yes">
                <style>
                    * { box-sizing: border-box; }
                    html, body { margin: 0; padding: 0; width: 100%; overflow-x: hidden; }
                    img { max-width: 100% !important; height: auto !important; display: block; margin: 8px 0; }
                    table { width: 100% !important; border-collapse: collapse; table-layout: fixed; }
                    td, th { word-wrap: break-word; overflow-wrap: break-word; }
                    video, iframe { max-width: 100% !important; height: auto !important; }
                    body { 
                        word-wrap: break-word; 
                        padding: 16px;
                        font-size: 16px;
                        line-height: 1.6;
                        color: #E2E8F0;
                        background-color: #1E1E2C;
                        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    }
                    body, p, span, div, table, tr, td, th {
                        background-color: #1E1E2C !important;
                        color: #E2E8F0 !important;
                    }
                    /* Remove fixed widths from inline styles */
                    [style*="width"] { max-width: 100% !important; }
                </style>
            </head>
            <body>$description</body>
            </html>
          """;
          _webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..enableZoom(false)
            ..setBackgroundColor(const Color(0xFF1E1E2C))
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageFinished: (url) {
                  Future.delayed(const Duration(milliseconds: 200), () {
                    _updateWebViewHeight();
                  });
                  Future.delayed(const Duration(seconds: 1), () {
                    _updateWebViewHeight();
                  });
                },
              ),
            )
            ..loadHtmlString(htmlContent);
        }
      }

      // 2. Load Reviews
      final reviews = await appService.getReviewList(productIdVal);
      _reviews = reviews;

      // 3. Load QnAs
      final qnas = await appService.getQnaList(productIdVal);
      _qnas = qnas;

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터 로딩 오류: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_detail == null || _token == null) return;
    final appService = RepositoryProvider.of<AppService>(context);
    final pid = int.tryParse(_detail!.product.productId ?? '') ?? 0;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await appService.toggleInterest(_userNo, pid);
      if (success) {
        setState(() {
          _isFav = !_isFav;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isFav ? '관심상품으로 등록되었습니다.' : '관심상품이 해제되었습니다.')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관심등록 처리 중 오류가 발생했습니다.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleStatusChange(String label, String code) async {
    if (_detail == null || _token == null) return;
    final appService = RepositoryProvider.of<AppService>(context);
    final pid = int.tryParse(_detail!.product.productId ?? '') ?? 0;

    if (code == '99') {
      // Pick buyer then confirm
      setState(() {
        _isLoading = true;
      });
      try {
        final buyers = await appService.getChatBuyers(pid, _branchId);
        setState(() {
          _isLoading = false;
        });

        if (buyers.isEmpty) {
          _showStatusConfirmDialog(label, code, null);
        } else {
          _showBuyerSelectionDialog(buyers, label, code);
        }
      } catch (_) {
        setState(() {
          _isLoading = false;
        });
        _showStatusConfirmDialog(label, code, null);
      }
    } else {
      _showStatusConfirmDialog(label, code, null);
    }
  }

  void _showBuyerSelectionDialog(List<ChatBuyerDto> buyers, String label, String code) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E1A47),
          title: const Text('구매완료 처리 - 구매자 선택', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: buyers.length,
              itemBuilder: (ctx, idx) {
                final buyer = buyers[idx];
                return ListTile(
                  title: Text(buyer.buyerNm, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(buyer.buyerId, style: const TextStyle(color: Colors.white70)),
                  onTap: () {
                    Navigator.pop(context);
                    _showStatusConfirmDialog(label, code, buyer);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showStatusConfirmDialog(label, code, null);
              },
              child: const Text('선택없이 진행', style: TextStyle(color: Color(0xFFFF9100))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  void _showStatusConfirmDialog(String label, String code, ChatBuyerDto? buyer) {
    final message = '상태를 "$label"(으)로 변경하시겠습니까?' + (buyer != null ? '\n구매자: ${buyer.buyerNm}' : '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E1A47),
          title: const Text('상태 변경 확인', style: TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateProductStatus(code, buyer);
              },
              child: const Text('확인', style: TextStyle(color: Color(0xFFFF9100))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProductStatus(String code, ChatBuyerDto? buyer) async {
    if (_detail == null || _token == null) return;
    final appService = RepositoryProvider.of<AppService>(context);
    final pid = int.tryParse(_detail!.product.productId ?? '') ?? 0;

    setState(() {
      _isLoading = true;
    });

    try {
      if (code == '99' && buyer != null) {
        await appService.createPurchase(pid, buyer.buyerNo.toInt(), buyer.roomId, buyer.sellerNo.toInt());
      }

      final request = ProductApprovalRequest(
        productId: pid.toString(),
        approvalStatus: ApprovalStatus.fromCode(code),
        updusrNo: _userNo,
        systemType: '2',
      );

      final success = await appService.updateProductStatus(_token!, request);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상태가 변경되었습니다.')),
        );
        _loadAllData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상태 변경에 실패했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleFabClick() {
    if (_detail == null) return;
    final pid = _detail!.product.productId ?? '';
    final branchId = _detail!.product.branchId;

    if (_memberCode == Constants.rolePub) {
      _createOrGetChatRoom(pid, _userId, branchId);
    } else if (_memberCode == Constants.roleSell) {
      _fetchRoomListForSeller(pid, Constants.centerBranchId);
    } else if (_memberCode == Constants.roleProj) {
      showDialog(
        context: context,
        builder: (ctx) {
          return SimpleDialog(
            backgroundColor: const Color(0xFF2E1A47),
            title: const Text('문의 채팅 선택', style: TextStyle(color: Colors.white)),
            children: [
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(ctx);
                  _fetchRoomListForSeller(pid, _branchId);
                },
                child: const Text('구매자에게 채팅', style: TextStyle(color: Colors.white)),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(ctx);
                  _createOrGetChatRoom(pid, _branchId, Constants.centerBranchId);
                },
                child: const Text('본사와 채팅', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _createOrGetChatRoom(String productId, String buyerId, String branchId) async {
    final appService = RepositoryProvider.of<AppService>(context);
    setState(() {
      _isLoading = true;
    });
    try {
      final room = await appService.createOrGetChatRoom(int.tryParse(productId) ?? 0, buyerId, branchId);
      if (room != null) {
        Navigator.pushNamed(context, '/chat', arguments: {
          'roomId': room.roomId,
          'buyerId': buyerId,
          'branchId': branchId,
          'productId': productId,
        });
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('채팅방 연결 실패')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRoomListForSeller(String productId, String branchId) async {
    final appService = RepositoryProvider.of<AppService>(context);
    setState(() {
      _isLoading = true;
    });
    try {
      final rooms = await appService.getUserChatRooms(int.tryParse(productId) ?? 0, branchId);
      if (rooms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('진행 중인 채팅 문의가 없습니다.')),
        );
      } else if (rooms.length == 1) {
        Navigator.pushNamed(context, '/chat', arguments: {
          'roomId': rooms[0].roomId,
          'buyerId': rooms[0].buyerId,
          'branchId': rooms[0].branchId,
          'productId': productId,
        });
      } else {
        _showChatRoomSelectionDialog(rooms);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('채팅 목록 조회 실패')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showChatRoomSelectionDialog(List<ChatRoomResponse> rooms) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E1A47),
          title: const Text('문의 구매자 선택', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: rooms.length,
              itemBuilder: (ctx, idx) {
                final room = rooms[idx];
                return ListTile(
                  title: Text('구매자 ID: ${room.buyerId}', style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/chat', arguments: {
                      'roomId': room.roomId,
                      'buyerId': room.buyerId,
                      'branchId': room.branchId,
                      'productId': widget.productId,
                    });
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showImageViewer(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (ctx) {
        return Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white30,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBuyer = (_memberCode == Constants.rolePub);
    final title = _detail?.product.title ?? '상품 상세';
    final representImage = _detail?.imageMetas.firstWhere(
      (img) => img.represent == '1',
      orElse: () => ProductImageVo(represent: '1', imageUrl: ''),
    ).imageUrl ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: _isLoading && _detail == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9100)),
            )
          : _detail == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.white30),
                      const SizedBox(height: 16),
                      const Text(
                        '상품 정보를 불러오지 못했습니다.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9100),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: _loadAllData,
                        child: const Text('다시 시도', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 280,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color(0xFF2E1A47),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      if (isBuyer)
                        IconButton(
                          icon: Icon(
                            _isFav ? Icons.favorite : Icons.favorite_border,
                            color: _isFav ? Colors.redAccent : Colors.white,
                          ),
                          onPressed: _toggleFavorite,
                        ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        innerBoxIsScrolled ? title : '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: GestureDetector(
                        onTap: () {
                          if (representImage.isNotEmpty) {
                            _showImageViewer(representImage);
                          }
                        },
                        child: representImage.isNotEmpty
                            ? Image.network(representImage, fit: BoxFit.cover)
                            : Container(color: const Color(0xFF2E1A47)),
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: const Color(0xFFFF9100),
                        labelColor: const Color(0xFFFF9100),
                        unselectedLabelColor: Colors.white70,
                        tabs: const [
                          Tab(text: '상품상세'),
                          Tab(text: '상품리뷰'),
                          Tab(text: '상품문의'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildDescriptionTab(),
                  _buildReviewsTab(),
                  _buildQnasTab(),
                ],
              ),
            ),
      floatingActionButton: _detail != null
          ? _buildFAB()
          : null,
      bottomNavigationBar: _buildBottomDock(),
    );
  }

  Widget _buildDescriptionTab() {
    if (_detail == null) return const SizedBox.shrink();

    final product = _detail!.product;
    final price = double.tryParse(product.price) ?? 0.0;
    final totalPrice = price * _orderQuantity;
    final isBuyer = (_memberCode == Constants.rolePub);
    final subImages = _detail!.imageMetas.where((img) => img.represent == '0').take(3).toList();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFFFF9100),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              product.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${price.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}원',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9100),
              ),
            ),
            const Divider(color: Colors.white24, height: 24),

            // Options Spinner for Sellers
            if (_memberCode == Constants.roleSell) ...[
              const Text('상품 판매 상태 변경', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: product.saleStatus,
                    dropdownColor: const Color(0xFF2E1A47),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (newVal) {
                      if (newVal != null && newVal != product.saleStatus) {
                        final labels = {'0': '대기', '1': '판매중', '10': '승인신청', '20': '승인대기', '30': '반려', '99': '판매완료'};
                        _handleStatusChange(labels[newVal] ?? newVal, newVal);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: '0', child: Text('대기 (0)')),
                      DropdownMenuItem(value: '1', child: Text('판매중 (1)')),
                      DropdownMenuItem(value: '10', child: Text('승인신청 (10)')),
                      DropdownMenuItem(value: '20', child: Text('승인대기 (20)')),
                      DropdownMenuItem(value: '30', child: Text('반려 (30)')),
                      DropdownMenuItem(value: '99', child: Text('판매완료 (99)')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quantity selector (Buyers only)
            if (isBuyer) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '수량 선택',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                        onPressed: () {
                          if (_orderQuantity > 1) {
                            setState(() {
                              _orderQuantity--;
                            });
                          }
                        },
                      ),
                      Text(
                        '$_orderQuantity',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                        onPressed: () {
                          if (_orderQuantity < _maxQuantity) {
                            setState(() {
                              _orderQuantity++;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('구매 가능한 최대 수량입니다.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '구매 가능 수량: $_maxQuantity 개',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.end,
              ),
              const SizedBox(height: 12),
            ],

            // Shipping Info Card (배송비 카드)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, color: Color(0xFFFF9100), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '배송비: ${_baseShippingFee.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}원',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '(${_freeThreshold.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}원 이상 구매 시 무료)',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Description HTML Webview / Text
            const Text(
              '상품 설명',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            (product.editorMode == '1' || product.editorMode == '2') && _webViewController != null
                ? SizedBox(
                    height: _webViewHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: WebViewWidget(
                        controller: _webViewController!,
                      ),
                    ),
                  )
                : (product.editorMode == '1' || product.editorMode == '2')
                    ? _isLoading
                        ? const SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(color: Color(0xFFFF9100)),
                            ),
                          )
                        : Text(
                            product.description.isEmpty 
                                ? '등록된 상품 설명이 없습니다.' 
                                : _decodeHtml(product.description).replaceAll(RegExp(r'<[^>]*>'), ''),
                            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                          )
                    : Text(
                        product.description.isEmpty 
                            ? '등록된 상품 설명이 없습니다.' 
                            : _decodeHtml(product.description),
                        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                      ),

            const SizedBox(height: 20),

            // Sub-images stacked gallery (세로형 추가 이미지 목록)
            if (subImages.isNotEmpty) ...[
              const Text(
                '추가 이미지',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Column(
                children: subImages.map((img) {
                  return GestureDetector(
                    onTap: () => _showImageViewer(img.imageUrl ?? ''),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(img.imageUrl ?? '', fit: BoxFit.cover),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Total amount
            if (isBuyer) ...[
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('총 합계 금액', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text(
                    '${totalPrice.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}원',
                    style: const TextStyle(color: Color(0xFFFF9100), fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFFFF9100),
      child: _reviews.isEmpty
          ? const Center(
              child: Text('작성된 리뷰가 없습니다.', style: TextStyle(color: Colors.white38)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _reviews.length,
              itemBuilder: (ctx, idx) {
                final review = _reviews[idx];
                return Card(
                  color: Colors.white.withOpacity(0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(review.writerId, style: const TextStyle(color: Color(0xFFFF9100), fontWeight: FontWeight.bold)),
                            Text(review.writeDt, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(5, (starIdx) {
                            return Icon(
                              starIdx < review.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(review.contents, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        if (review.filePaths != null && review.filePaths!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => _showImageViewer(review.filePaths!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(review.filePaths!, height: 80, width: 80, fit: BoxFit.cover),
                            ),
                          ),
                        ],
                        if (review.writerNo == _userNo) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/reviewWrite', arguments: {
                                    'productId': int.tryParse(widget.productId) ?? 0,
                                    'reviewId': review.reviewNo.toString(),
                                    'contents': review.contents,
                                    'rating': review.rating,
                                    'filePaths': review.filePaths,
                                  }).then((success) {
                                    if (success == true) _loadAllData();
                                  });
                                },
                                child: const Text('수정', style: TextStyle(color: Colors.white70)),
                              ),
                              TextButton(
                                onPressed: () => _deleteReview(review.reviewNo),
                                child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _deleteReview(int reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E1A47),
          title: const Text('리뷰 삭제', style: TextStyle(color: Colors.white)),
          content: const Text('작성한 리뷰를 삭제하시겠습니까?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.redAccent))),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소', style: TextStyle(color: Colors.white54))),
          ],
        );
      },
    );

    if (confirmed == true && _token != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        final appService = RepositoryProvider.of<AppService>(context);
        await appService.deleteReview(reviewId, _token!);
        _loadAllData();
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제 실패')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildQnasTab() {
    final isSellerOrAdmin = (_memberCode == Constants.roleSell || _memberCode == Constants.roleAdmin);

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFFFF9100),
      child: _qnas.isEmpty
          ? const Center(
              child: Text('작성된 문의글이 없습니다.', style: TextStyle(color: Colors.white38)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _qnas.length,
              itemBuilder: (ctx, idx) {
                final qna = _qnas[idx];
                final isSecret = qna.secretYn == 'Y';
                final isMine = qna.writerNo == _userNo;
                final canRead = !isSecret || isMine || isSellerOrAdmin;

                return Card(
                  color: Colors.white.withOpacity(0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(qna.writerId, style: const TextStyle(color: Color(0xFFFF9100), fontWeight: FontWeight.bold)),
                                if (isSecret) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.lock, color: Colors.white38, size: 14),
                                ],
                              ],
                            ),
                            Text(qna.writeDt, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          qna.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        canRead
                            ? Text(qna.contents, style: const TextStyle(color: Colors.white70, fontSize: 14))
                            : const Text('비밀글로 등록된 문의글입니다.', style: TextStyle(color: Colors.white38, fontSize: 14)),
                        if (qna.answerContents != null && qna.answerContents!.isNotEmpty) ...[
                          const Divider(color: Colors.white24),
                          Row(
                            children: [
                              const Text('답변', style: TextStyle(color: Color(0xFFFF9100), fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text(qna.answerDt ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          canRead
                              ? Text(qna.answerContents!, style: const TextStyle(color: Colors.white70, fontSize: 14))
                              : const Text('답변은 작성자만 볼 수 있습니다.', style: TextStyle(color: Colors.white38, fontSize: 14)),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isMine) ...[
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/qnaWrite', arguments: {
                                    'productId': int.tryParse(widget.productId) ?? 0,
                                    'qnaId': qna.qnaNo.toString(),
                                    'title': qna.title,
                                    'contents': qna.contents,
                                    'secretYn': qna.secretYn,
                                  }).then((success) {
                                    if (success == true) _loadAllData();
                                  });
                                },
                                child: const Text('수정', style: TextStyle(color: Colors.white70)),
                              ),
                              TextButton(
                                onPressed: () => _deleteQna(qna.qnaNo),
                                child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                            if (isSellerOrAdmin && (qna.answerContents == null || qna.answerContents!.isEmpty)) ...[
                              TextButton(
                                onPressed: () => _showAnswerDialog(qna.qnaNo),
                                child: const Text('답변 작성', style: TextStyle(color: Color(0xFFFF9100))),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _deleteQna(int qnaId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E1A47),
          title: const Text('문의글 삭제', style: TextStyle(color: Colors.white)),
          content: const Text('작성한 문의글을 삭제하시겠습니까?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.redAccent))),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소', style: TextStyle(color: Colors.white54))),
          ],
        );
      },
    );

    if (confirmed == true && _token != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        final appService = RepositoryProvider.of<AppService>(context);
        await appService.deleteQna(qnaId, _token!);
        _loadAllData();
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제 실패')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAnswerDialog(int qnaId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E1A47),
          title: const Text('문의 답변 작성', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: '답변 내용을 입력해 주세요.',
              hintStyle: TextStyle(color: Colors.white38),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(ctx);
                await _submitAnswer(qnaId, text);
              },
              child: const Text('등록', style: TextStyle(color: Color(0xFFFF9100))),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소', style: TextStyle(color: Colors.white54))),
          ],
        );
      },
    );
  }

  Future<void> _submitAnswer(int qnaId, String text) async {
    if (_token == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final appService = RepositoryProvider.of<AppService>(context);
      await appService.answerQna(qnaId: qnaId, answerContents: text, token: _token!);
      _loadAllData();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('답변 등록 실패')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF2E1A47),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
