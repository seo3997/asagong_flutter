import 'package:flutter_test/flutter_test.dart';
import 'package:asagong_flutter/data/models/approval_status.dart';
import 'package:asagong_flutter/data/models/product_approval_request.dart';
import 'package:asagong_flutter/data/models/product_vo.dart';
import 'package:asagong_flutter/data/models/product_image_vo.dart';
import 'package:asagong_flutter/data/models/product_detail_response.dart';
import 'package:asagong_flutter/data/models/product_dashboard_stats.dart';
import 'package:asagong_flutter/data/models/password_change_request.dart';
import 'package:asagong_flutter/data/models/ad_item.dart';
import 'package:asagong_flutter/data/models/ad_list_request.dart';
import 'package:asagong_flutter/data/models/ad_response.dart';
import 'package:asagong_flutter/data/models/address_book_vo.dart';
import 'package:asagong_flutter/data/models/order_models.dart';
import 'package:asagong_flutter/data/models/chat_models.dart';
import 'package:asagong_flutter/data/models/review_models.dart';
import 'package:asagong_flutter/data/models/qna_models.dart';

void main() {
  group('ApprovalStatus Enum Tests', () {
    test('Correct status code mapping', () {
      expect(ApprovalStatus.fromCode('0'), ApprovalStatus.request);
      expect(ApprovalStatus.fromCode('1'), ApprovalStatus.approved);
      expect(ApprovalStatus.fromCode('98'), ApprovalStatus.rejected);
      expect(ApprovalStatus.fromCode('99'), ApprovalStatus.done);
      expect(ApprovalStatus.fromCode('invalid'), ApprovalStatus.request); // Fallback
      expect(ApprovalStatus.fromCode(null), ApprovalStatus.request); // Fallback
    });

    test('Correct labels', () {
      expect(ApprovalStatus.request.label, '결재요청');
      expect(ApprovalStatus.approved.label, '결재완료');
      expect(ApprovalStatus.rejected.label, '반려');
      expect(ApprovalStatus.done.label, '완료');
    });
  });

  group('ProductApprovalRequest Serialization Tests', () {
    test('toJson and fromJson mapping', () {
      final request = ProductApprovalRequest(
        productId: '12345',
        approvalStatus: ApprovalStatus.rejected,
        updusrNo: 42,
        rejectReason: 'Incomplete documents',
        systemType: '2',
      );

      final json = request.toJson();
      expect(json['productId'], '12345');
      expect(json['saleStatus'], '98');
      expect(json['updusrNo'], 42);
      expect(json['rejectReason'], 'Incomplete documents');
      expect(json['systemType'], '2');

      final deserialized = ProductApprovalRequest.fromJson(json);
      expect(deserialized.productId, '12345');
      expect(deserialized.approvalStatus, ApprovalStatus.rejected);
      expect(deserialized.updusrNo, 42);
      expect(deserialized.rejectReason, 'Incomplete documents');
      expect(deserialized.systemType, '2');
    });
  });

  group('ProductVo & ProductImageVo Deserialization Tests', () {
    test('fromJson mapping with name fields', () {
      final productMap = {
        'productId': '777',
        'userNo': '10',
        'title': 'Sweet Carrots',
        'description': 'Fresh carrots directly from the farm.',
        'price': '15000',
        'categoryGroup': 'C01',
        'categoryMid': 'C0101',
        'categoryScls': 'C010101',
        'saleStatus': '1', // Approved
        'areaGroup': 'A01',
        'areaMid': 'A0101',
        'areaScls': 'A010101',
        'quantity': '100',
        'unitGroup': 'U01',
        'unitCode': 'U0101',
        'desiredShippingDate': '2026-06-10',
        'registerNo': '10',
        'updusrNo': '10',
        'imageUrl': 'http://image.url/1.png',
        'saleStatusNm': '판매중',
      };

      final product = ProductVo.fromJson(productMap);
      expect(product.productId, '777');
      expect(product.title, 'Sweet Carrots');
      expect(product.approvalStatus, ApprovalStatus.approved);
      expect(product.approvalStatusNm, '결재완료');
      expect(product.imageUrl, 'http://image.url/1.png');
    });

    test('ProductImageVo helper tests', () {
      final image1 = ProductImageVo(represent: '1', imageUrl: 'represent.png');
      final image2 = ProductImageVo(represent: '0', imageUrl: 'sub.png');

      expect(image1.isRepresent, true);
      expect(image2.isRepresent, false);
    });
  });

  group('ProductDetailResponse Integration Tests', () {
    test('Full detail response parse', () {
      final responseMap = {
        'product': {
          'productId': '100',
          'userNo': '2',
          'title': 'Organic Carrots',
          'price': '10000',
          'saleStatus': '0', // Request
        },
        'imageMetas': [
          {'represent': '1', 'imageUrl': 'represent.png'},
          {'represent': '0', 'imageUrl': 'sub1.png'}
        ]
      };

      final response = ProductDetailResponse.fromJson(responseMap);
      expect(response.product.productId, '100');
      expect(response.product.title, 'Organic Carrots');
      expect(response.product.approvalStatus, ApprovalStatus.request);
      expect(response.imageMetas.length, 2);
      expect(response.imageMetas[0].isRepresent, true);
      expect(response.imageMetas[1].isRepresent, false);
    });
  });

  group('ProductDashboardStats Typo Mapping Tests', () {
    test('Parsing backend typo reguestCount', () {
      final statsMap = {
        'totalCount': 10,
        'reguestCount': 3, // Typo key from backend
        'processingCount': 5,
        'completedCount': 2
      };

      final stats = ProductDashboardStats.fromJson(statsMap);
      expect(stats.totalCount, 10);
      expect(stats.rejectedCount, 3);
      expect(stats.processingCount, 5);
      expect(stats.completedCount, 2);

      // Verify serialization output maps back to reguestCount
      final json = stats.toJson();
      expect(json['reguestCount'], 3);
      expect(json['totalCount'], 10);
    });
  });

  group('PasswordChangeRequest Serialization Tests', () {
    test('toJson and fromJson mapping', () {
      final request = PasswordChangeRequest(
        currentPassword: 'old_password_123',
        newPassword: 'new_password_456',
        confirmPassword: 'new_password_456',
      );

      final json = request.toJson();
      expect(json['currentPassword'], 'old_password_123');
      expect(json['newPassword'], 'new_password_456');
      expect(json['confirmPassword'], 'new_password_456');

      final deserialized = PasswordChangeRequest.fromJson(json);
      expect(deserialized.currentPassword, 'old_password_123');
      expect(deserialized.newPassword, 'new_password_456');
      expect(deserialized.confirmPassword, 'new_password_456');
    });
  });

  group('Product List Model Tests', () {
    test('AdItem serialization and deserialization', () {
      final adItemMap = {
        'productId': '999',
        'title': 'Deluxe Apple Box',
        'description': 'A premium collection of high-quality apples.',
        'price': '35000',
        'imageUrl': 'http://image.url/apple.png',
        'userId': '15',
        'ORDER_NO': 'ORD-1004',
        'ORDER_STATUS': '30',
        'ORDER_STATUS_NM': '결제완료'
      };

      final adItem = AdItem.fromJson(adItemMap);
      expect(adItem.productId, '999');
      expect(adItem.title, 'Deluxe Apple Box');
      expect(adItem.price, '35000');
      expect(adItem.orderNo, 'ORD-1004');
      expect(adItem.paymentStatus, '30');
      expect(adItem.orderStatusNm, '결제완료');

      final json = adItem.toJson();
      expect(json['productId'], '999');
      expect(json['title'], 'Deluxe Apple Box');
      expect(json['price'], '35000');
    });

    test('AdListRequest serialization and deserialization', () {
      final request = AdListRequest(
        token: 'test_token_123',
        adCode: 2,
        pageno: 3,
        minPrice: 5000,
        maxPrice: 50000,
        saleStatus: '20',
        memberCode: 'ROLE_PROJ'
      );

      final json = request.toJson();
      expect(json['token'], 'test_token_123');
      expect(json['adCode'], 2);
      expect(json['pageno'], 3);
      expect(json['minPrice'], 5000);
      expect(json['maxPrice'], 50000);
      expect(json['saleStatus'], '20');
      expect(json['memberCode'], 'ROLE_PROJ');

      final deserialized = AdListRequest.fromJson(json);
      expect(deserialized.token, 'test_token_123');
      expect(deserialized.adCode, 2);
      expect(deserialized.pageno, 3);
      expect(deserialized.minPrice, 5000);
      expect(deserialized.maxPrice, 50000);
      expect(deserialized.saleStatus, '20');
      expect(deserialized.memberCode, 'ROLE_PROJ');
    });

    test('AdResponse parsing content / items lists', () {
      final responseMap = {
        'items': [
          {
            'productId': '101',
            'title': 'Product A',
            'description': 'Description A',
            'price': '1000',
            'imageUrl': 'imgA',
            'userId': '1'
          },
          {
            'productId': '102',
            'title': 'Product B',
            'description': 'Description B',
            'price': '2000',
            'imageUrl': 'imgB',
            'userId': '2'
          }
        ]
      };

      final response = AdResponse.fromJson(responseMap);
      expect(response.items.length, 2);
      expect(response.items[0].productId, '101');
      expect(response.items[1].productId, '102');
    });
  });

  group('New Migrated Models Tests', () {
    test('TbAddressBookVo serialization and deserialization', () {
      final map = {
        'recipientName': '홍길동',
        'recipientPhone': '010-1234-5678',
        'zipCode': '12345',
        'addressMain': '서울시 강남구',
        'addressDetail': '역삼동 101호',
        'isDefault': 1,
        'memo': '문 앞에 놔주세요',
        'addressNo': 45
      };

      final vo = TbAddressBookVo.fromJson(map);
      expect(vo.recipientName, '홍길동');
      expect(vo.recipientPhone, '010-1234-5678');
      expect(vo.zipCode, '12345');
      expect(vo.addressMain, '서울시 강남구');
      expect(vo.addressDetail, '역삼동 101호');
      expect(vo.isDefault, 1);
      expect(vo.memo, '문 앞에 놔주세요');
      expect(vo.addressNo, 45);

      final json = vo.toJson();
      expect(json['recipientName'], '홍길동');
      expect(json['addressNo'], 45);
    });

    test('OrderCreateRequest and OrderItemRequest serialization', () {
      final req = OrderCreateRequest(
        userNo: 12,
        totalItemAmount: 20000,
        deliveryFee: 3000,
        discountAmount: 0,
        totalPayAmount: 23000,
        receiverName: '김철수',
        receiverPhone: '010-9876-5432',
        zipCode: '54321',
        address1: '부산시 해운대구',
        address2: '우동 202호',
        orderMemo: '조심히 배달해주세요',
        branchId: 2,
        items: [
          OrderItemRequest(productId: 777, quantity: 2, optionName: '박스')
        ]
      );

      final json = req.toJson();
      expect(json['userNo'], 12);
      expect(json['totalPayAmount'], 23000);
      expect(json['receiverName'], '김철수');
      expect(json['branchId'], 2);
      expect(json['items'][0]['productId'], 777);
      expect(json['items'][0]['quantity'], 2);
      expect(json['items'][0]['optionName'], '박스');
    });

    test('OrderCreateResponse parsing', () {
      final map = {
        'success': true,
        'message': '성공',
        'orderId': 99,
        'orderNo': 'ORD-999',
        'orderName': '당근 외 1건',
        'amount': 25000
      };

      final res = OrderCreateResponse.fromJson(map);
      expect(res.success, true);
      expect(res.message, '성공');
      expect(res.orderId, 99);
      expect(res.orderNo, 'ORD-999');
      expect(res.orderName, '당근 외 1건');
      expect(res.amount, 25000);
    });

    test('PaymentConfirmRequest and response mapping', () {
      final req = PaymentConfirmRequest(
        paymentKey: 'toss_payment_key_xyz',
        orderNo: 'ORD-999',
        amount: 25000,
        userNo: 12
      );

      final json = req.toJson();
      expect(json['paymentKey'], 'toss_payment_key_xyz');
      expect(json['orderNo'], 'ORD-999');
      expect(json['amount'], 25000);
      expect(json['userNo'], 12);

      final resMap = {
        'success': true,
        'message': '승인 완료',
        'paymentKey': 'toss_payment_key_xyz',
        'orderId': '99',
        'orderNo': 'ORD-999',
        'amount': 25000
      };

      final res = PaymentConfirmResponse.fromJson(resMap);
      expect(res.success, true);
      expect(res.message, '승인 완료');
      expect(res.orderNo, 'ORD-999');
      expect(res.amount, 25000);
    });

    test('ChatRoomResponse and ChatBuyerDto parsing', () {
      final roomMap = {
        'roomId': 'room-111',
        'buyerId': 'buyer_gildong',
        'branchId': '2',
        'productId': '777',
        'lastMessage': '안녕하세요',
        'lastMessageTime': '2026-06-06 12:00'
      };

      final room = ChatRoomResponse.fromJson(roomMap);
      expect(room.roomId, 'room-111');
      expect(room.buyerId, 'buyer_gildong');
      expect(room.branchId, '2');
      expect(room.productId, '777');
      expect(room.lastMessage, '안녕하세요');
      expect(room.lastMessageTime, '2026-06-06 12:00');

      final buyerMap = {
        'roomId': 'room-111',
        'productId': 777,
        'branchId': '2',
        'buyerId': 'buyer_gildong',
        'buyerNo': 12,
        'buyerNm': '홍길동',
        'sellerNo': 99,
        'sellerNm': '상인대표'
      };

      final buyer = ChatBuyerDto.fromJson(buyerMap);
      expect(buyer.roomId, 'room-111');
      expect(buyer.productId, 777);
      expect(buyer.buyerNo, 12);
      expect(buyer.buyerNm, '홍길동');
    });

    test('ChatMessage json mapping', () {
      final msgMap = {
        'roomId': 'room-111',
        'senderId': 'buyer_gildong',
        'senderGroup': 'ROLE_PUB',
        'message': '당근 파시나요?',
        'type': 'text',
        'time': '2026-06-06 12:05',
        'receiveGroup': 'ROLE_PROJ'
      };

      final msg = ChatMessage.fromJson(msgMap);
      expect(msg.roomId, 'room-111');
      expect(msg.senderId, 'buyer_gildong');
      expect(msg.message, '당근 파시나요?');
      expect(msg.senderGroup, 'ROLE_PUB');

      final json = msg.toJson();
      expect(json['roomId'], 'room-111');
      expect(json['message'], '당근 파시나요?');
    });

    test('ReviewItem json parsing', () {
      final reviewMap = {
        'REVIEW_ID': 101,
        'RATING': 4.5,
        'CONTENTS': '아주 아삭아삭해요!',
        'FILE_PATHS': 'img1.png',
        'WRITER_ID': 'buyer_gildong',
        'WRITE_DT': '2026-06-06',
        'WRITER_NO': 12
      };

      final review = ReviewItem.fromJson(reviewMap);
      expect(review.reviewNo, 101);
      expect(review.rating, 4.5);
      expect(review.contents, '아주 아삭아삭해요!');
      expect(review.filePaths, 'img1.png');
      expect(review.writerId, 'buyer_gildong');
      expect(review.writerNo, 12);
    });

    test('QnaItem json parsing', () {
      final qnaMap = {
        'QNA_ID': 201,
        'TITLE': '배송 문의',
        'CONTENTS': '언제 배송되나요?',
        'SECRET_YN': 'Y',
        'WRITER_ID': 'buyer_gildong',
        'WRITE_DT': '2026-06-06',
        'WRITER_NO': 12,
        'ANSWER_CONTENTS': '내일 배송됩니다.',
        'ANSWER_DT': '2026-06-07'
      };

      final qna = QnaItem.fromJson(qnaMap);
      expect(qna.qnaNo, 201);
      expect(qna.title, '배송 문의');
      expect(qna.secretYn, 'Y');
      expect(qna.answerContents, '내일 배송됩니다.');
      expect(qna.answerDt, '2026-06-07');
    });
  });
}
