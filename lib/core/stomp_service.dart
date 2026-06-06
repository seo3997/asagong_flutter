import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../data/models/chat_models.dart';

class StompService {
  static final StompService _instance = StompService._internal();
  factory StompService() => _instance;
  StompService._internal();

  StompClient? _client;
  final Map<String, void Function({Map<String, String>? unsubscribeHeaders})> _subscriptions = {};

  void connect({
    required String userId,
    required String baseChatUrl,
    void Function(StompFrame)? onConnect,
    void Function(StompFrame)? onDisconnect,
    void Function(Object?)? onError,
  }) {
    if (_client != null && _client!.connected) {
      return;
    }

    final url = '$baseChatUrl$userId';

    _client = StompClient(
      config: StompConfig(
        url: url,
        onConnect: (frame) {
          onConnect?.call(frame);
        },
        onDisconnect: (frame) {
          onDisconnect?.call(frame);
        },
        onStompError: (frame) {
          onError?.call(frame.body);
        },
        onWebSocketError: (error) {
          onError?.call(error);
        },
        // Enable heartbeats like native stomps if needed
        webSocketConnectHeaders: {
          'transports': ['websocket'],
        },
      ),
    );

    _client!.activate();
  }

  bool get isConnected => _client != null && _client!.connected;

  void sendMessage(ChatMessage message) {
    if (!isConnected) return;
    _client!.send(
      destination: '/app/chat.send',
      body: jsonEncode(message.toJson()),
    );
  }

  void sendMessageRoomId(ChatMessage message) {
    if (!isConnected) return;
    _client!.send(
      destination: '/app/chat.send.${message.roomId}',
      body: jsonEncode(message.toJson()),
    );
  }

  void sendEnterRoom(String roomId, String senderId) {
    if (!isConnected) return;
    _client!.send(
      destination: '/app/chat.enter.$roomId',
      body: jsonEncode({'roomId': roomId, 'senderId': senderId}),
    );
  }

  void sendExitRoom(String roomId, String senderId) {
    if (!isConnected) return;
    _client!.send(
      destination: '/app/chat.exit.$roomId',
      body: jsonEncode({'roomId': roomId, 'senderId': senderId}),
    );
  }

  void sendExitMe(String senderId) {
    if (!isConnected) return;
    _client!.send(
      destination: '/app/chat.me.exit',
      body: jsonEncode({'senderId': senderId}),
    );
  }

  void subscribe({
    required String topicPath,
    required void Function(ChatMessage) onMessageReceived,
  }) {
    if (!isConnected) return;

    if (_subscriptions.containsKey(topicPath)) {
      return; // Already subscribed
    }

    final unsubscribeFn = _client!.subscribe(
      destination: topicPath,
      callback: (frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!) as Map<String, dynamic>;
            final message = ChatMessage.fromJson(json);
            onMessageReceived(message);
          } catch (_) {}
        }
      },
    );

    _subscriptions[topicPath] = unsubscribeFn;
  }

  void unsubscribe(String topicPath) {
    final unsubscribeFn = _subscriptions.remove(topicPath);
    if (unsubscribeFn != null) {
      unsubscribeFn();
    }
  }

  void clearSubscriptions() {
    for (final unsubscribeFn in _subscriptions.values) {
      unsubscribeFn();
    }
    _subscriptions.clear();
  }

  void disconnect() {
    clearSubscriptions();
    _client?.deactivate();
    _client = null;
  }
}
