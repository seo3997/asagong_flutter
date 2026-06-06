import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'http://www.asagong.com';
  print('Logging in...');
  final loginResponse = await http.post(
    Uri.parse('$baseUrl/api/members/login'),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'id': 'sel1@gmail.com',
      'pass': '1234',
      'login_cd': 'PWD',
      'reg_id': '',
      'appver': '1.0.0',
      'providerUserId': '',
    },
  );

  if (loginResponse.statusCode == 200) {
    final loginData = jsonDecode(loginResponse.body);
    final token = loginData['token'];
    print('Token: $token');

    if (token != null) {
      // 1. Raw token
      print('1. Requesting with raw token...');
      final recentResponseRaw = await http.get(
        Uri.parse('$baseUrl/api/product/recent?token=$token'),
      );
      print('Raw token recent status: ${recentResponseRaw.statusCode}');
      print('Raw token body length: ${recentResponseRaw.body.length}');

      // 2. Decoded token
      print('2. Requesting with decoded token...');
      final decodedToken = Uri.decodeQueryComponent(token);
      final recentResponseDec = await http.get(
        Uri.parse('$baseUrl/api/product/recent').replace(
          queryParameters: {'token': decodedToken},
        ),
      );
      print('Decoded token recent status: ${recentResponseDec.statusCode}');
      print('Decoded token body: ${recentResponseDec.body}');

      // 3. Double encoded token
      print('3. Requesting with double-encoded token...');
      final doubleEncoded = Uri.encodeQueryComponent(token);
      final recentResponseDouble = await http.get(
        Uri.parse('$baseUrl/api/product/recent?token=$doubleEncoded'),
      );
      print('Double-encoded token recent status: ${recentResponseDouble.statusCode}');
      print('Double-encoded token body length: ${recentResponseDouble.body.length}');
      if (recentResponseDouble.statusCode == 200) {
        print('Double-encoded token body: ${recentResponseDouble.body}');
      }
    }
  }
}
