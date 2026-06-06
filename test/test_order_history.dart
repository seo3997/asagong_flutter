import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'http://www.asagong.com';
  print('Logging in as buyer...');
  final loginResponse = await http.post(
    Uri.parse('$baseUrl/api/members/login'),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'id': 'pub1@gmail.com',
      'pass': '1234',
      'login_cd': 'PWD',
      'reg_id': '',
      'appver': '1.0.0',
      'providerUserId': '',
    },
  );

  print('Login status: ${loginResponse.statusCode}');
  print('Login body: ${loginResponse.body}');

  if (loginResponse.statusCode == 200) {
    final loginData = jsonDecode(loginResponse.body);
    final token = loginData['token'];
    final userNoStr = loginData['login_idx'] ?? loginData['loginIdx'] ?? '0';
    final userNo = int.tryParse(userNoStr) ?? 0;
    print('Token: $token, UserNo: $userNo');

    if (token != null && userNo > 0) {
      print('Fetching order history for buyerNo: $userNo...');
      
      final url = Uri.parse('$baseUrl/api/orders/buyer/$userNo').replace(
        queryParameters: {'page': '0', 'size': '20'},
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Order history status: ${response.statusCode}');
      print('Order history headers: ${response.headers}');
      print('Order history body: ${utf8.decode(response.bodyBytes)}');
    } else {
      print('Token is null or UserNo is 0!');
    }
  } else {
    print('Login failed!');
  }
}
