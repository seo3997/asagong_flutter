import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({super.key});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    const html = """
      <!DOCTYPE html>
      <html>
      <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
          <script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
          <style>
              html, body, #layer { width:100%; height:100%; margin:0; padding:0; background-color: #1E1E2C; }
          </style>
      </head>
      <body>
          <div id="layer"></div>
          <script>
              var element_layer = document.getElementById('layer');
              new daum.Postcode({
                  oncomplete: function(data) {
                      if (window.Android) {
                          window.Android.postMessage(JSON.stringify({
                              zonecode: data.zonecode,
                              address: data.address
                          }));
                      }
                  },
                  width : '100%',
                  height : '100%'
              }).embed(element_layer);
          </script>
      </body>
      </html>
    """;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1E1E2C))
      ..addJavaScriptChannel(
        'Android',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final parsed = jsonDecode(message.message) as Map<String, dynamic>;
            final zipCode = parsed['zonecode']?.toString() ?? '';
            final address = parsed['address']?.toString() ?? '';
            Navigator.pop(context, {
              'zipCode': zipCode,
              'address': address,
            });
          } catch (_) {
            Navigator.pop(context);
          }
        },
      )
      ..loadHtmlString(html, baseUrl: 'https://daum.net');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E1A47),
        title: const Text('주소 검색', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
