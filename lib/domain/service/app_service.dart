import '../../data/repository/app_repository.dart';
import '../../data/models/login_response.dart';
import '../../data/models/op_user_vo.dart';
import '../../data/models/product_approval_request.dart';
import '../../data/models/product_detail_response.dart';
import '../../data/models/product_dashboard_stats.dart';
import '../../data/models/product_vo.dart';
import '../../data/models/payment_models.dart';
import '../../data/models/password_change_request.dart';
import '../../data/models/simple_result_response.dart';
import '../../data/models/ad_item.dart';
import '../../data/models/ad_list_request.dart';
import '../../data/models/address_book_vo.dart';
import '../../data/models/order_models.dart';
import '../../data/models/chat_models.dart';
import '../../data/models/review_models.dart';
import '../../data/models/qna_models.dart';
import '../../data/models/social_auth_request.dart';
import '../../data/models/link_social_request.dart';
import '../../data/models/unlink_social_request.dart';
import '../../data/models/string_response.dart';

class AppService {
  final AppRepository repository;

  AppService({required this.repository});

  Future<LoginResponse?> login({
    required String email,
    required String password,
    required String loginCd,
    String regId = '',
    required String appVersion,
    String providerUserId = '',
  }) async {
    try {
      return await repository.login(
        email: email,
        password: password,
        loginCd: loginCd,
        regId: regId,
        appVersion: appVersion,
        providerUserId: providerUserId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<OpUserVo?> getUserInfo(String token) async {
    try {
      return await repository.getUserInfoByToken(token);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProductStatus(String token, ProductApprovalRequest product) async {
    try {
      final response = await repository.updateProductStatus(token, product);
      return response.result;
    } catch (_) {
      return false;
    }
  }

  Future<ProductDetailResponse?> getProductDetail(int productId, int userNo) async {
    try {
      return await repository.getProductDetail(productId, userNo);
    } catch (_) {
      return null;
    }
  }

  Future<ProductDashboardStats?> getProductDashboard(String token) async {
    try {
      return await repository.getProductDashboard(token);
    } catch (_) {
      return null;
    }
  }

  Future<List<ProductVo>> getRecentProducts(String token) async {
    try {
      return await repository.getRecentProducts(token);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, String>>> getCodeList(String groupId) async {
    try {
      return await repository.getCodeList(groupId);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getDashboardMgtData(String token) async {
    try {
      return await repository.getDashboardMgtData(token);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOrderMgtList({
    required String token,
    String? orderStatus,
    String? orderStDt,
    String? orderEdDt,
    String? searchKeyword,
  }) async {
    try {
      return await repository.getOrderMgtList(
        token: token,
        orderStatus: orderStatus,
        orderStDt: orderStDt,
        orderEdDt: orderEdDt,
        searchKeyword: searchKeyword,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOrderMgtDetail(String orderId, String token) async {
    try {
      return await repository.getOrderMgtDetail(orderId, token);
    } catch (_) {
      return null;
    }
  }

  Future<bool> confirmDeposit(String token, String orderId, String carrier, String trackingNo) async {
    try {
      return await repository.confirmDeposit(token, orderId, carrier, trackingNo);
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestBranchDeposit(String token, String orderId) async {
    try {
      return await repository.requestBranchDeposit(token, orderId);
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateShipping(String token, String orderId, String carrier, String trackingNo) async {
    try {
      return await repository.updateShipping(token, orderId, carrier, trackingNo);
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateOrderStatus(String token, String orderId, String status) async {
    try {
      return await repository.updateOrderStatus(token, orderId, status);
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelPayment(OrderCancelRequest request) async {
    try {
      return await repository.cancelPayment(request);
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestReturn(String token, Map<String, dynamic> req) async {
    try {
      return await repository.requestReturn(token, req);
    } catch (_) {
      return false;
    }
  }


  Future<SimpleResultResponse?> updateUser(String token, OpUserVo user) async {
    try {
      return await repository.updateUser(token, user);
    } catch (_) {
      return null;
    }
  }

  Future<SimpleResultResponse?> changePassword(String token, PasswordChangeRequest request) async {
    try {
      return await repository.changePassword(token, request);
    } catch (_) {
      return null;
    }
  }

  Future<List<AdItem>> getAdvertiseList(AdListRequest req) async {
    try {
      return await repository.getAdvertiseList(req);
    } catch (_) {
      return [];
    }
  }

  Future<List<AdItem>> getBuyAdvertiseList(AdListRequest req) async {
    try {
      return await repository.getBuyAdvertiseList(req);
    } catch (_) {
      return [];
    }
  }

  Future<List<AdItem>> getInterestItems(String token, int pageNo) async {
    try {
      return await repository.getInterestItems(token, pageNo);
    } catch (_) {
      return [];
    }
  }

  Future<List<AdItem>> getPurchaseItems(String token, int pageNo) async {
    try {
      return await repository.getPurchaseItems(token, pageNo);
    } catch (_) {
      return [];
    }
  }

  Future<List<AdItem>> getOrderHistory(String token, int buyerNo, int page, int size) async {
    try {
      return await repository.getOrderHistory(token, buyerNo, page, size);
    } catch (_) {
      return [];
    }
  }


  Future<bool> toggleInterest(int userNo, int productId) async {
    try {
      return await repository.toggleInterest(userNo, productId);
    } catch (_) {
      return false;
    }
  }

  Future<List<ChatBuyerDto>> getChatBuyers(int productId, String branchId) async {
    try {
      return await repository.getChatBuyers(productId, branchId);
    } catch (_) {
      return [];
    }
  }

  Future<SimpleResultResponse?> createPurchase(int productId, int buyerNo, String roomId, int sellerNo) async {
    try {
      return await repository.createPurchase(productId, buyerNo, roomId, sellerNo);
    } catch (_) {
      return null;
    }
  }

  Future<OrderCreateResponse?> createOrder(OrderCreateRequest req) async {
    try {
      return await repository.createOrder(req);
    } catch (_) {
      return null;
    }
  }

  Future<PaymentConfirmResponse?> confirmPayment(PaymentConfirmRequest req) async {
    try {
      return await repository.confirmPayment(req);
    } catch (_) {
      return null;
    }
  }

  Future<List<TbAddressBookVo>> getAddressList(String token) async {
    try {
      return await repository.getAddressList(token);
    } catch (_) {
      return [];
    }
  }

  Future<SimpleResultResponse?> addAddress(String token, TbAddressBookVo address) async {
    try {
      return await repository.addAddress(token, address);
    } catch (_) {
      return null;
    }
  }

  Future<SimpleResultResponse?> deleteAddress(int id, String token) async {
    try {
      return await repository.deleteAddress(id, token);
    } catch (_) {
      return null;
    }
  }

  Future<List<ReviewItem>> getReviewList(int productId) async {
    try {
      return await repository.getReviewList(productId);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> insertReview({
    required int productId,
    required double rating,
    required String contents,
    required String token,
    required String branchId,
    List<String>? filePaths,
  }) async {
    try {
      return await repository.insertReview(
        productId: productId,
        rating: rating,
        contents: contents,
        token: token,
        branchId: branchId,
        filePaths: filePaths,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateReview({
    required int reviewId,
    required double rating,
    required String contents,
    required String token,
    required String branchId,
    List<String>? filePaths,
  }) async {
    try {
      return await repository.updateReview(
        reviewId: reviewId,
        rating: rating,
        contents: contents,
        token: token,
        branchId: branchId,
        filePaths: filePaths,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> deleteReview(int reviewId, String token) async {
    try {
      return await repository.deleteReview(reviewId, token);
    } catch (_) {
      return null;
    }
  }

  Future<List<QnaItem>> getQnaList(int productId) async {
    try {
      return await repository.getQnaList(productId);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> insertQna({
    required int productId,
    required String title,
    required String contents,
    required String secretYn,
    required String token,
    required String branchId,
  }) async {
    try {
      return await repository.insertQna(
        productId: productId,
        title: title,
        contents: contents,
        secretYn: secretYn,
        token: token,
        branchId: branchId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateQna({
    required int qnaId,
    required String title,
    required String contents,
    required String secretYn,
    required String token,
    required String branchId,
  }) async {
    try {
      return await repository.updateQna(
        qnaId: qnaId,
        title: title,
        contents: contents,
        secretYn: secretYn,
        token: token,
        branchId: branchId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> answerQna({
    required int qnaId,
    required String answerContents,
    required String token,
  }) async {
    try {
      return await repository.answerQna(
        qnaId: qnaId,
        answerContents: answerContents,
        token: token,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> deleteQna(int qnaId, String token) async {
    try {
      return await repository.deleteQna(qnaId, token);
    } catch (_) {
      return null;
    }
  }

  Future<ChatRoomResponse?> createOrGetChatRoom(int productId, String buyerId, String branchId) async {
    try {
      return await repository.createOrGetChatRoom(productId, buyerId, branchId);
    } catch (_) {
      return null;
    }
  }

  Future<List<ChatRoomResponse>> getUserChatRooms(int productId, String userId) async {
    try {
      return await repository.getUserChatRooms(productId, userId);
    } catch (_) {
      return [];
    }
  }

  Future<List<ChatMessage>> getChatMessages(String roomId) async {
    try {
      return await repository.getChatMessages(roomId);
    } catch (_) {
      return [];
    }
  }

  Future<bool> registerPushToken({
    required String userNo,
    required String userId,
    required String pushToken,
    required String deviceType,
  }) async {
    try {
      return await repository.registerPushToken(
        userNo: userNo,
        userId: userId,
        pushToken: pushToken,
        deviceType: deviceType,
      );
    } catch (_) {
      return false;
    }
  }

  Future<StringResponse?> findPassword(String mail) async {
    try {
      return await repository.findPassword(mail);
    } catch (_) {
      return null;
    }
  }

  Future<StringResponse?> findEmail(String name, String phone) async {
    try {
      return await repository.findEmail(name, phone);
    } catch (_) {
      return null;
    }
  }

  Future<SimpleResultResponse?> checkEmailDuplicate(String email) async {
    try {
      return await repository.checkEmailDuplicate(email);
    } catch (_) {
      return null;
    }
  }

  Future<LoginResponse?> registerUser(OpUserVo user) async {
    try {
      return await repository.registerUser(user);
    } catch (_) {
      return null;
    }
  }

  Future<List<BranchInfoVo>> getBranchList() async {
    try {
      return await repository.getBranchList();
    } catch (_) {
      return [];
    }
  }

  Future<LoginResponse?> authSocial(SocialAuthRequest req) async {
    try {
      return await repository.authSocial(req);
    } catch (_) {
      return null;
    }
  }

  Future<LoginResponse?> linkSocial(LinkSocialRequest req) async {
    try {
      return await repository.linkSocial(req);
    } catch (_) {
      return null;
    }
  }

  Future<SimpleResultResponse?> unlinkSocial(UnlinkSocialRequest req) async {
    try {
      return await repository.unlinkSocial(req);
    } catch (_) {
      return null;
    }
  }
}
