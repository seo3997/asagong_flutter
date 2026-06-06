import '../api/api_service.dart';
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
import '../models/address_book_vo.dart';
import '../models/order_models.dart';
import '../models/chat_models.dart';
import '../models/review_models.dart';
import '../models/qna_models.dart';

class AppRepository {
  final ApiService apiService;

  AppRepository({required this.apiService});

  Future<LoginResponse> login({
    required String email,
    required String password,
    required String loginCd,
    String regId = '',
    required String appVersion,
    String providerUserId = '',
  }) {
    return apiService.login(
      email: email,
      password: password,
      loginCd: loginCd,
      regId: regId,
      appVersion: appVersion,
      providerUserId: providerUserId,
    );
  }

  Future<OpUserVo> getUserInfoByToken(String token) {
    return apiService.getUserInfoByToken(token);
  }

  Future<SimpleResultResponse> updateProductStatus(String token, ProductApprovalRequest product) {
    return apiService.updateProductStatus(token, product);
  }

  Future<ProductDetailResponse> getProductDetail(int productId, int userNo) {
    return apiService.getProductDetail(productId, userNo);
  }

  Future<ProductDashboardStats> getProductDashboard(String token) {
    return apiService.getProductDashboard(token);
  }

  Future<List<ProductVo>> getRecentProducts(String token) {
    return apiService.getRecentProducts(token);
  }

  Future<List<Map<String, String>>> getCodeList(String groupId) {
    return apiService.getCodeList(groupId);
  }

  Future<Map<String, dynamic>> getDashboardMgtData(String token) {
    return apiService.getDashboardMgtData(token);
  }

  Future<Map<String, dynamic>> getOrderMgtList({
    required String token,
    String? orderStatus,
    String? orderStDt,
    String? orderEdDt,
    String? searchKeyword,
  }) {
    return apiService.getOrderMgtList(
      token: token,
      orderStatus: orderStatus,
      orderStDt: orderStDt,
      orderEdDt: orderEdDt,
      searchKeyword: searchKeyword,
    );
  }

  Future<Map<String, dynamic>> getOrderMgtDetail(String orderId, String token) {
    return apiService.getOrderMgtDetail(orderId, token);
  }

  Future<bool> confirmDeposit(String token, String orderId, String carrier, String trackingNo) {
    return apiService.confirmDeposit(token, orderId, carrier, trackingNo);
  }

  Future<bool> requestBranchDeposit(String token, String orderId) {
    return apiService.requestBranchDeposit(token, orderId);
  }

  Future<bool> updateShipping(String token, String orderId, String carrier, String trackingNo) {
    return apiService.updateShipping(token, orderId, carrier, trackingNo);
  }

  Future<bool> updateOrderStatus(String token, String orderId, String status) {
    return apiService.updateOrderStatus(token, orderId, status);
  }

  Future<bool> cancelPayment(OrderCancelRequest request) {
    return apiService.cancelPayment(request);
  }

  Future<SimpleResultResponse> updateUser(String token, OpUserVo user) {
    return apiService.updateUser(token, user);
  }

  Future<SimpleResultResponse> changePassword(String token, PasswordChangeRequest request) {
    return apiService.changePassword(token, request);
  }

  Future<List<AdItem>> getAdvertiseList(AdListRequest req) {
    return apiService.getAdvertiseList(req);
  }

  Future<List<AdItem>> getBuyAdvertiseList(AdListRequest req) {
    return apiService.getBuyAdvertiseList(req);
  }

  Future<bool> toggleInterest(int userNo, int productId) {
    return apiService.toggleInterest(userNo, productId);
  }

  Future<List<ChatBuyerDto>> getChatBuyers(int productId, String branchId) {
    return apiService.getChatBuyers(productId, branchId);
  }

  Future<SimpleResultResponse> createPurchase(int productId, int buyerNo, String roomId, int sellerNo) {
    return apiService.createPurchase(productId, buyerNo, roomId, sellerNo);
  }

  Future<OrderCreateResponse> createOrder(OrderCreateRequest req) {
    return apiService.createOrder(req);
  }

  Future<PaymentConfirmResponse> confirmPayment(PaymentConfirmRequest req) {
    return apiService.confirmPayment(req);
  }

  Future<List<TbAddressBookVo>> getAddressList(String token) {
    return apiService.getAddressList(token);
  }

  Future<SimpleResultResponse> addAddress(String token, TbAddressBookVo address) {
    return apiService.addAddress(token, address);
  }

  Future<SimpleResultResponse> deleteAddress(int id, String token) {
    return apiService.deleteAddress(id, token);
  }

  Future<List<ReviewItem>> getReviewList(int productId) {
    return apiService.getReviewList(productId);
  }

  Future<Map<String, dynamic>> insertReview({
    required int productId,
    required double rating,
    required String contents,
    required String token,
    required String branchId,
    List<String>? filePaths,
  }) {
    return apiService.insertReview(
      productId: productId,
      rating: rating,
      contents: contents,
      token: token,
      branchId: branchId,
      filePaths: filePaths,
    );
  }

  Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required double rating,
    required String contents,
    required String token,
    required String branchId,
    List<String>? filePaths,
  }) {
    return apiService.updateReview(
      reviewId: reviewId,
      rating: rating,
      contents: contents,
      token: token,
      branchId: branchId,
      filePaths: filePaths,
    );
  }

  Future<Map<String, dynamic>> deleteReview(int reviewId, String token) {
    return apiService.deleteReview(reviewId, token);
  }

  Future<List<QnaItem>> getQnaList(int productId) {
    return apiService.getQnaList(productId);
  }

  Future<Map<String, dynamic>> insertQna({
    required int productId,
    required String title,
    required String contents,
    required String secretYn,
    required String token,
    required String branchId,
  }) {
    return apiService.insertQna(
      productId: productId,
      title: title,
      contents: contents,
      secretYn: secretYn,
      token: token,
      branchId: branchId,
    );
  }

  Future<Map<String, dynamic>> updateQna({
    required int qnaId,
    required String title,
    required String contents,
    required String secretYn,
    required String token,
    required String branchId,
  }) {
    return apiService.updateQna(
      qnaId: qnaId,
      title: title,
      contents: contents,
      secretYn: secretYn,
      token: token,
      branchId: branchId,
    );
  }

  Future<Map<String, dynamic>> answerQna({
    required int qnaId,
    required String answerContents,
    required String token,
  }) {
    return apiService.answerQna(
      qnaId: qnaId,
      answerContents: answerContents,
      token: token,
    );
  }

  Future<Map<String, dynamic>> deleteQna(int qnaId, String token) {
    return apiService.deleteQna(qnaId, token);
  }

  Future<ChatRoomResponse> createOrGetChatRoom(int productId, String buyerId, String branchId) {
    return apiService.createOrGetChatRoom(productId, buyerId, branchId);
  }

  Future<List<ChatRoomResponse>> getUserChatRooms(int productId, String userId) {
    return apiService.getUserChatRooms(productId, userId);
  }

  Future<List<ChatMessage>> getChatMessages(String roomId) {
    return apiService.getChatMessages(roomId);
  }
}
