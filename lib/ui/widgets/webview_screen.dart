import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isInitialized = false;
  int _loadingProgress = 0;
  String _title = '웹페이지';
  String _url = '';

  String _getUserAgent() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1 KyCarrotsApp/Android";
    }
    return "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36 KyCarrotsApp/Android";
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1E1E2C))
      ..setUserAgent(_getUserAgent())
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            _injectJavascriptBridge();
          },
          onPageFinished: (String url) {
            _injectJavascriptBridge();
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('페이지를 불러오지 못했습니다.')));
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            if (url.startsWith('http://') || url.startsWith('https://')) {
              return NavigationDecision.navigate;
            }
            _launchExternalUrl(url);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterAndroidBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJsMessage(message.message);
        },
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, String>? ??
          {};
      _title = args['title'] ?? '웹페이지';
      _url = args['url'] ?? '';
      _isInitialized = true;
      _setupAndLoad();
    }
  }

  Future<void> _setupAndLoad() async {
    if (_url.isEmpty) return;
    if (mounted) {
      await _controller.loadRequest(Uri.parse(_url));
    }
  }

  void _injectJavascriptBridge() {
    const js = '''
      (function() {
        if (typeof window.AndroidBridge === 'undefined') {
          window.AndroidBridge = {
            showToast: function(msg) {
              if (typeof FlutterAndroidBridge !== 'undefined') {
                FlutterAndroidBridge.postMessage(JSON.stringify({action: 'showToast', message: msg}));
              }
            },
            refresh: function() {
              if (typeof FlutterAndroidBridge !== 'undefined') {
                FlutterAndroidBridge.postMessage(JSON.stringify({action: 'refresh'}));
              }
            }
          };
        }
      })();
    ''';
    _controller.runJavaScript(js).catchError((e) {
      debugPrint('JS injection error: $e');
    });
  }

  void _handleJsMessage(String rawMessage) {
    try {
      final data = jsonDecode(rawMessage);
      final action = data['action'];
      if (action == 'showToast') {
        final msg = data['message'] ?? '';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      } else if (action == 'refresh') {
        _controller.reload();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(rawMessage)));
    }
  }

  Future<void> _launchExternalUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E1A47),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                await _controller.goBack();
              } else {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
          title: Text(
            _title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                _controller.reload();
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loadingProgress < 100)
              Center(
                child: CircularProgressIndicator(
                  value: _loadingProgress / 100.0,
                  color: const Color(0xFFFF9100),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
