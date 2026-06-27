import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../models/login_response.dart';
import '../models/op_user_vo.dart';
import '../models/product_approval_request.dart';
import '../models/product_detail_response.dart';
import '../models/product_dashboard_stats.dart';
import '../models/simple_result_response.dart';
import '../models/product_vo.dart';
import '../models/payment_models.dart';
import '../models/password_change_request.dart';
import '../models/ad_item.dart';
import '../models/ad_list_request.dart';
import '../models/ad_response.dart';
import '../models/address_book_vo.dart';
import '../models/order_models.dart';
import '../models/chat_models.dart';
import '../models/review_models.dart';
import '../models/qna_models.dart';
import '../models/social_auth_request.dart';
import '../models/link_social_request.dart';
import '../models/unlink_social_request.dart';
import '../models/string_response.dart';

class ApiService {
  final String baseUrl;
  final http.Client client;

  ApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? Constants.baseUrl,
        client = client ?? http.Client();

  /// Authenticates user with email and password (api/members/login)
  Future<LoginResponse> login({
    required String email,
    required String password,
    required String loginCd,
    String regId = '',
    required String appVersion,
    String providerUserId = '',
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/members/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'id': email,
        'pass': password,
        'login_cd': loginCd,
        'reg_id': regId,
        'appver': appVersion,
        'providerUserId': providerUserId,
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Login Failed: ${response.statusCode}');
    }
  }

  /// Fetches user details using JWT token (api/members/userinfo)
  Future<OpUserVo> getUserInfoByToken(String token) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/members/userinfo'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'token': token},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return OpUserVo.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Fetch UserInfo Failed: ${response.statusCode}');
    }
  }

  /// Updates approval status of a product (api/product/status/update)
  Future<SimpleResultResponse> updateProductStatus(String token, ProductApprovalRequest product) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/product/status/update').replace(
        queryParameters: {'token': token},
      ),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(product.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return SimpleResultResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Update Status Failed: ${response.statusCode}');
    }
  }

  /// Fetches details of a product (api/product/detail/{productId})
  Future<ProductDetailResponse> getProductDetail(int productId, int userNo) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/product/detail/$productId').replace(
        queryParameters: {'userNo': userNo.toString()},
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return ProductDetailResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Fetch Product Detail Failed: ${response.statusCode}');
    }
  }

  /// Fetches dashboard statistics (api/product/dashboard)
  Future<ProductDashboardStats> getProductDashboard(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/product/dashboard').replace(
        queryParameters: {'token': token},
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return ProductDashboardStats.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Fetch Dashboard Failed: ${response.statusCode}');
    }
  }

  /// Fetches recent products (api/product/recent)
  Future<List<ProductVo>> getRecentProducts(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/product/recent').replace(
        queryParameters: {'token': token},
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return list.map((item) => ProductVo.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Fetch Recent Products Failed: ${response.statusCode}');
    }
  }

  /// Fetches common code lists (api/common/codelist)
  Future<List<Map<String, String>>> getCodeList(String groupId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/common/codelist').replace(
        queryParameters: {'groupId': groupId},
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return {
          'strIdx': (map['strIdx'] ?? '').toString(),
          'strMsg': (map['strMsg'] ?? '').toString(),
        };
      }).toList();
    } else {
      throw Exception('Fetch CodeList Failed: ${response.statusCode}');
    }
  }

  /// Fetches mall dashboard data (api/dashboard)
  Future<Map<String, dynamic>> getDashboardMgtData(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/dashboard').replace(
        queryParameters: {'token': token},
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('Fetch Dashboard Mgt Data Failed: ${response.statusCode}');
    }
  }

  /// Fetches order management list (api/order/list)
  Future<Map<String, dynamic>> getOrderMgtList({
    required String token,
    String? orderStatus,
    String? orderStDt,
    String? orderEdDt,
    String? searchKeyword,
  }) async {
    final queryParams = {'token': token};
    if (orderStatus != null && orderStatus.isNotEmpty) {
      queryParams['orderStatus'] = orderStatus;
    }
    if (orderStDt != null && orderStDt.isNotEmpty) {
      queryParams['orderStDt'] = orderStDt;
    }
    if (orderEdDt != null && orderEdDt.isNotEmpty) {
      queryParams['orderEdDt'] = orderEdDt;
    }
    if (searchKeyword != null && searchKeyword.isNotEmpty) {
      queryParams['searchKeyword'] = searchKeyword;
    }

    final response = await client.get(
      Uri.parse('$baseUrl/api/order/list').replace(
        queryParameters: queryParams,
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('Fetch Order Mgt List Failed: ${response.statusCode}');
    }
  }

  /// Fetches order management detail (api/order/{orderId})
  Future<Map<String, dynamic>> getOrderMgtDetail(String orderId, String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/order/$orderId').replace(
        queryParameters: {'token': token},
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('Fetch Order Mgt Detail Failed: ${response.statusCode}');
    }
  }

  /// Confirms deposit (api/order/confirmDeposit)
  Future<bool> confirmDeposit(String token, String orderId, String carrier, String trackingNo) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/order/confirmDeposit').replace(
        queryParameters: {
          'token': token,
          'orderId': orderId,
          'carrier': carrier,
          'trackingNo': trackingNo,
        },
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    return response.statusCode == 200;
  }

  /// Requests deposit confirmation from branch (api/order/requestBranchDeposit)
  Future<bool> requestBranchDeposit(String token, String orderId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/order/requestBranchDeposit').replace(
        queryParameters: {
          'token': token,
          'orderId': orderId,
        },
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    return response.statusCode == 200;
  }

  /// Updates shipping details (api/order/updateShipping)
  Future<bool> updateShipping(String token, String orderId, String carrier, String trackingNo) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/order/updateShipping').replace(
        queryParameters: {
          'token': token,
          'orderId': orderId,
          'carrier': carrier,
          'trackingNo': trackingNo,
        },
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    return response.statusCode == 200;
  }

  /// Updates order status (api/order/status)
  Future<bool> updateOrderStatus(String token, String orderId, String status) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/order/status').replace(
        queryParameters: {
          'token': token,
          'orderId': orderId,
          'status': status,
        },
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    return response.statusCode == 200;
  }

  /// Cancels payment (api/payment/cancel)
  Future<bool> cancelPayment(OrderCancelRequest request) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/payment/cancel'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(request.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return body['success'] as bool? ?? false;
    } else {
      return false;
    }
  }

  /// Requests return (api/payment/return)
  Future<bool> requestReturn(String token, Map<String, dynamic> req) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/payment/return'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(req),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return body['success'] as bool? ?? false;
    } else {
      return false;
    }
  }


  /// Updates user profile details (api/members/update)
  Future<SimpleResultResponse> updateUser(String token, OpUserVo user) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/members/update').replace(
        queryParameters: {'token': token},
      ),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(user.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return SimpleResultResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Update User Failed: ${response.statusCode}');
    }
  }

  /// Changes password of a user (api/members/change-password)
  Future<SimpleResultResponse> changePassword(String token, PasswordChangeRequest request) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/members/change-password').replace(
        queryParameters: {'token': token},
      ),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(request.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return SimpleResultResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Change Password Failed: ${response.statusCode}');
    }
  }

  /// Fetches advertise items (api/product)
  Future<List<AdItem>> getAdvertiseList(AdListRequest req) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/product'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(req.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final res = AdResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      return res.items;
    } else {
      throw Exception('Fetch Advertise List Failed: ${response.statusCode}');
    }
  }

  /// Fetches buy advertise items (api/product/buyListAdvertise)
  Future<List<AdItem>> getBuyAdvertiseList(AdListRequest req) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/product/buyListAdvertise'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(req.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final res = AdResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      return res.items;
    } else {
      throw Exception('Fetch Buy Advertise List Failed: ${response.statusCode}');
    }
  }

  /// Fetches interest items list (api/product/interests/list)
  Future<List<AdItem>> getInterestItems(String token, int pageNo) async {
    final Map<String, String> headers = {
      'Accept': 'application/json',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await client.get(
      Uri.parse('$baseUrl/api/product/interests/list').replace(
        queryParameters: {'token': token, 'pageno': pageNo.toString()},
      ),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final res = AdResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      return res.items;
    } else {
      throw Exception('Fetch Interest Items Failed: ${response.statusCode}');
    }
  }

  /// Fetches purchase items list (api/product/purchases/list)
  Future<List<AdItem>> getPurchaseItems(String token, int pageNo) async {
    final Map<String, String> headers = {
      'Accept': 'application/json',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await client.get(
      Uri.parse('$baseUrl/api/product/purchases/list').replace(
        queryParameters: {'token': token, 'pageno': pageNo.toString()},
      ),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final res = AdResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      return res.items;
    } else {
      throw Exception('Fetch Purchase Items Failed: ${response.statusCode}');
    }
  }

  /// Fetches order history for a buyer (api/orders/buyer/{buyerNo})
  Future<List<AdItem>> getOrderHistory(String token, int buyerNo, int page, int size) async {
    final Map<String, String> headers = {
      'Accept': 'application/json',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final requestUrl = Uri.parse('$baseUrl/api/orders/buyer/$buyerNo').replace(
      queryParameters: {'page': page.toString(), 'size': size.toString()},
    );

    print("[DEBUG] getOrderHistory Request URL: $requestUrl");
    print("[DEBUG] getOrderHistory Headers: $headers");

    try {
      final response = await client.get(
        requestUrl,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print("[DEBUG] getOrderHistory Status Code: ${response.statusCode}");
      print("[DEBUG] getOrderHistory Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final res = AdResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
        print("[DEBUG] getOrderHistory Parsed items count: ${res.items.length}");
        return res.items;
      } else {
        print("[DEBUG] getOrderHistory Failed with status: ${response.statusCode}");
        throw Exception('Fetch Order History Failed: ${response.statusCode}');
      }
    } catch (e, stack) {
      print("[DEBUG] getOrderHistory Exception: $e");
      print("[DEBUG] getOrderHistory Stack: $stack");
      rethrow;
    }
  }

  /// Toggle favorite interest status (api/interests/toggle)
  Future<bool> toggleInterest(int userNo, int productId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/interests/toggle'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'userNo': userNo, 'productId': productId}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as bool? ?? false;
    } else {
      throw Exception('Toggle Interest Failed: ${response.statusCode}');
    }
  }

  /// Fetches chat buyers list (api/product/chat/buyers)
  Future<List<ChatBuyerDto>> getChatBuyers(int productId, String branchId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/product/chat/buyers').replace(
        queryParameters: {'productId': productId.toString(), 'branchId': branchId},
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return list.map((item) => ChatBuyerDto.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Fetch Chat Buyers Failed: ${response.statusCode}');
    }
  }

  /// Creates a purchase history record (api/purchases)
  Future<SimpleResultResponse> createPurchase(int productId, int buyerNo, String roomId, int sellerNo) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/purchases'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'productId': productId,
        'buyerNo': buyerNo,
        'roomId': roomId,
        'sellerNo': sellerNo,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return SimpleResultResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Create Purchase Failed: ${response.statusCode}');
    }
  }

  /// Creates a checkout order (api/payment/order/create)
  Future<OrderCreateResponse> createOrder(OrderCreateRequest req) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/payment/order/create'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(req.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return OrderCreateResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Create Order Failed: ${response.statusCode}');
    }
  }

  /// Confirms a payment (api/payment/confirm)
  Future<PaymentConfirmResponse> confirmPayment(PaymentConfirmRequest req) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/payment/confirm'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(req.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return PaymentConfirmResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Confirm Payment Failed: ${response.statusCode}');
    }
  }

  /// Gets delivery addresses (api/members/address)
  Future<List<TbAddressBookVo>> getAddressList(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/members/address').replace(
        queryParameters: {'token': token},
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return list.map((item) => TbAddressBookVo.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Fetch Address List Failed: ${response.statusCode}');
    }
  }

  /// Adds a delivery address (api/members/address)
  Future<SimpleResultResponse> addAddress(String token, TbAddressBookVo address) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/members/address').replace(
        queryParameters: {'token': token},
      ),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(address.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return SimpleResultResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Add Address Failed: ${response.statusCode}');
    }
  }

  /// Deletes a delivery address (api/members/address/delete/{id})
  Future<SimpleResultResponse> deleteAddress(int id, String token) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/members/address/delete/$id').replace(
        queryParameters: {'token': token},
      ),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return SimpleResultResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Delete Address Failed: ${response.statusCode}');
    }
  }

  /// Gets reviews (api/product/review/list)
  Future<List<ReviewItem>> getReviewList(int productId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/product/review/list').replace(
        queryParameters: {'productId': productId.toString()},
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final list = (body['list'] ?? body['data']) as List? ?? [];
      return list.map((item) => ReviewItem.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Fetch Review List Failed: ${response.statusCode}');
    }
  }

  /// Inserts a review (api/product/review/insert)
  Future<Map<String, dynamic>> insertReview({
    required int productId,
    required double rating,
    required String contents,
    required String token,
    required String branchId,
    List<String>? filePaths,
  }) async {
    final uri = Uri.parse('$baseUrl/api/product/review/insert');
    final request = http.MultipartRequest('POST', uri);
    request.fields['productId'] = productId.toString();
    request.fields['rating'] = rating.toString();
    request.fields['contents'] = contents;
    request.fields['token'] = token;
    request.fields['branchId'] = branchId;

    if (filePaths != null && filePaths.isNotEmpty) {
      for (final path in filePaths) {
        final file = await http.MultipartFile.fromPath('reviewFile', path);
        request.files.add(file);
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('Insert Review Failed: ${response.statusCode}');
    }
  }

  /// Updates a review (api/product/review/update)
  Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required double rating,
    required String contents,
    required String token,
    required String branchId,
    List<String>? filePaths,
  }) async {
    final uri = Uri.parse('$baseUrl/api/product/review/update');
    final request = http.MultipartRequest('POST', uri);
    request.fields['reviewId'] = reviewId.toString();
    request.fields['rating'] = rating.toString();
    request.fields['contents'] = contents;
    request.fields['token'] = token;
    request.fields['branchId'] = branchId;

    if (filePaths != null && filePaths.isNotEmpty) {
      for (final path in filePaths) {
        if (!path.startsWith('http')) {
          final file = await http.MultipartFile.fromPath('reviewFile', path);
          request.files.add(file);
        }
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('Update Review Failed: ${response.statusCode}');
    }
  }

  /// Deletes a review (api/product/review/delete)
  Future<Map<String, dynamic>> deleteReview(int reviewId, String token) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/product/review/delete'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'reviewId': reviewId.toString(),
        'token': token,
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('Delete Review Failed: ${response.statusCode}');
    }
  }

  /// Gets QnA list (api/product/qna/list)
  Future<List<QnaItem>> getQnaList(int productId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/product/qna/list').replace(
        queryParameters: {'productId': productId.toString()},
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final list = (body['list'] ?? body['data']) as List? ?? [];
      return list.map((item) => QnaItem.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Fetch QnA List Failed: ${response.statusCode}');
    }
  }

  /// Inserts a QnA (api/product/qna/insert)
  Future<Map<String, dynamic>> insertQna({
    required int productId,
    required String title,
    required String contents,
    required String secretYn,
    required String token,
    required String branchId,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/product/qna/insert'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'productId': productId.toString(),
        'title': title,
        'contents': contents,
        'secretYn': secretYn,
        'token': token,
        'branchId': branchId,
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('Insert QnA Failed: ${response.statusCode}');
    }
  }

  /// Updates a QnA (api/product/qna/update)
  Future<Map<String, dynamic>> updateQna({
    required int qnaId,
    required String title,
    required String contents,
    required String secretYn,
    required String token,
    required String branchId,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/product/qna/update'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'qnaId': qnaId.toString(),
        'title': title,
        'contents': contents,
        'secretYn': secretYn,
        'token': token,
        'branchId': branchId,
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('Update QnA Failed: ${response.statusCode}');
    }
  }

  /// Answers a QnA (api/product/qna/answer)
  Future<Map<String, dynamic>> answerQna({
    required int qnaId,
    required String answerContents,
    required String token,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/product/qna/answer'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'qnaId': qnaId.toString(),
        'answerContents': answerContents,
        'token': token,
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('Answer QnA Failed: ${response.statusCode}');
    }
  }

  /// Deletes a QnA (api/product/qna/delete)
  Future<Map<String, dynamic>> deleteQna(int qnaId, String token) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/product/qna/delete'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'qnaId': qnaId.toString(),
        'token': token,
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('Delete QnA Failed: ${response.statusCode}');
    }
  }

  /// Creates/gets a chat room (api/chat/room)
  Future<ChatRoomResponse> createOrGetChatRoom(int productId, String buyerId, String branchId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/chat/room').replace(
        queryParameters: {
          'productId': productId.toString(),
          'buyerId': buyerId,
          'branchId': branchId,
        },
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return ChatRoomResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Create/Get ChatRoom Failed: ${response.statusCode}');
    }
  }

  /// Gets chat rooms list for seller (api/chat/rooms/{productId}/{userId})
  Future<List<ChatRoomResponse>> getUserChatRooms(int productId, String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/chat/rooms/$productId/$userId'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return list.map((item) => ChatRoomResponse.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Fetch User Chat Rooms Failed: ${response.statusCode}');
    }
  }

  /// Gets chat messages (api/chatmessage/list/{roomId})
  Future<List<ChatMessage>> getChatMessages(String roomId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/chatmessage/list/$roomId'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return list.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Fetch Chat Messages Failed: ${response.statusCode}');
    }
  }

  /// Registers push token to the server (api/members/push/savetoken)
  Future<bool> registerPushToken({
    required String userNo,
    required String userId,
    required String pushToken,
    required String deviceType,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/members/push/savetoken'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'userNo': userNo,
        'userId': userId,
        'pushToken': pushToken,
        'deviceType': deviceType,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return body['result'] as bool? ?? false;
    } else {
      return false;
    }
  }

  /// GET api/members/find-password
  Future<StringResponse> findPassword(String mail) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/members/find-password').replace(
        queryParameters: {'mail': mail},
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return StringResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Find Password Failed: ${response.statusCode}');
    }
  }

  /// GET api/members/find-email
  Future<StringResponse> findEmail(String name, String phone) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/members/find-email').replace(
        queryParameters: {'nm': name, 'hp': phone},
      ),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return StringResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Find Email Failed: ${response.statusCode}');
    }
  }

  /// POST api/members/email-check
  Future<SimpleResultResponse> checkEmailDuplicate(String email) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/members/email-check'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'email': email},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return SimpleResultResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Check Email Failed: ${response.statusCode}');
    }
  }

  /// POST api/members/register
  Future<LoginResponse> registerUser(OpUserVo user) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/members/register'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(user.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Register User Failed: ${response.statusCode}');
    }
  }

  /// GET /api/branch/list
  Future<List<BranchInfoVo>> getBranchList() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/branch/list'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return list.map((item) => BranchInfoVo.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Get Branch List Failed: ${response.statusCode}');
    }
  }

  /// POST api/members/social
  Future<LoginResponse> authSocial(SocialAuthRequest req) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/members/social'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(req.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Social Auth Failed: ${response.statusCode}');
    }
  }

  /// POST api/members/link
  Future<LoginResponse> linkSocial(LinkSocialRequest req) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/members/link'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(req.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Link Social Failed: ${response.statusCode}');
    }
  }

  /// POST api/members/unlink
  Future<SimpleResultResponse> unlinkSocial(UnlinkSocialRequest req) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/members/unlink'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(req.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return SimpleResultResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Unlink Social Failed: ${response.statusCode}');
    }
  }
}
