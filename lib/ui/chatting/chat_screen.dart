import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/stomp_service.dart';
import '../../core/constants.dart';
import '../../domain/service/app_service.dart';
import '../../data/models/chat_models.dart';
import '../../main.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const ChatScreen({
    super.key,
    required this.arguments,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = true;
  String _roomId = '';
  String _buyerId = '';
  String _branchId = '';
  String _productId = '';
  String _otherId = '';
  String _currentUserId = '';
  String _currentMemberCode = '';

  @override
  void initState() {
    super.initState();
    _roomId = widget.arguments['roomId'] as String? ?? '';
    _buyerId = widget.arguments['buyerId'] as String? ?? '';
    _branchId = widget.arguments['branchId'] as String? ?? '';
    _productId = widget.arguments['productId'] as String? ?? '';
    _otherId = widget.arguments['otherUserNm'] as String? ?? _buyerId;
    currentActiveRoomId = _roomId;

    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    // Exit room and disconnect socket
    final stomp = StompService();
    stomp.sendExitRoom(_roomId, _currentUserId);
    stomp.unsubscribe('/topic/$_roomId');
    stomp.disconnect();

    currentActiveRoomId = null;

    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('saved_user_id') ?? prefs.getString('saved_email') ?? '';
      _currentMemberCode = prefs.getString('saved_member_code') ?? '';

      // Determine the Other user's display name
      await _resolveOtherId();

      // Connect to Stomp WebSocket
      final stomp = StompService();
      stomp.connect(
        userId: _currentUserId,
        baseChatUrl: Constants.baseChatUrl,
        onConnect: (_) {
          // Subscribe to topic
          stomp.subscribe(
            topicPath: '/topic/$_roomId',
            onMessageReceived: (message) {
              if (mounted) {
                setState(() {
                  if (message.senderId != _currentUserId) {
                    final incoming = ChatMessage(
                      roomId: message.roomId,
                      senderId: message.senderId,
                      senderGroup: message.senderGroup,
                      message: message.message,
                      type: 'text',
                      time: message.time,
                      receiveGroup: message.receiveGroup,
                      isMe: false,
                    );
                    _messages.add(incoming);
                    _scrollToBottom();
                  }
                });
              }
            },
          );

          // Send enter signal
          stomp.sendEnterRoom(_roomId, _currentUserId);
        },
      );

      // Load previous chat history
      await _loadChatHistory();
    } catch (_) {
      // Ignore
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resolveOtherId() async {
    final intentName = widget.arguments['otherUserNm'] as String?;
    if (intentName != null && intentName.isNotEmpty) {
      _otherId = intentName;
      return;
    }

    final branchNameFromPrefs = (await SharedPreferences.getInstance()).getString('saved_branch_name') ?? '';

    if (_currentMemberCode == Constants.rolePub) {
      _otherId = branchNameFromPrefs;
    } else if (_currentMemberCode == Constants.roleProj) {
      _otherId = _branchId == '2' ? '본사' : _buyerId;
    } else if (_currentMemberCode == Constants.roleSell) {
      _otherId = '$_buyerId 지점';
    } else {
      _otherId = _buyerId;
    }
  }

  Future<void> _loadChatHistory() async {
    final appService = RepositoryProvider.of<AppService>(context);
    try {
      final history = await appService.getChatMessages(_roomId);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(history.map((m) {
            return ChatMessage(
              roomId: m.roomId,
              senderId: m.senderId,
              senderGroup: m.senderGroup,
              message: m.message,
              type: 'text',
              time: m.time,
              receiveGroup: m.receiveGroup,
              isMe: m.senderGroup == _currentMemberCode,
            );
          }));
        });
        _scrollToBottom();
      }
    } catch (_) {
      // Ignore
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final receiveGroup = _resolveReceiveGroup();
    final now = DateTime.now();
    final currentTime = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final message = ChatMessage(
      roomId: _roomId,
      senderId: _currentUserId,
      senderGroup: _currentMemberCode,
      message: text,
      type: 'text',
      time: currentTime,
      receiveGroup: receiveGroup,
      isMe: true,
    );

    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
    _messageController.clear();

    // Send via WebSocket
    StompService().sendMessageRoomId(message);
  }

  String _resolveReceiveGroup() {
    switch (_currentMemberCode) {
      case Constants.rolePub:
        return Constants.roleProj;
      case Constants.roleSell:
        return Constants.roleProj;
      case Constants.roleProj:
        return _branchId == '2' ? Constants.roleSell : Constants.rolePub;
      default:
        return Constants.roleProj;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E1A47),
        title: Text(
          '$_otherId 님과의 대화',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9100)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, idx) {
                      final msg = _messages[idx];
                      return _buildMessageBubble(msg);
                    },
                  ),
                ),
                _buildInputSection(),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isMe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Text(
              msg.senderId,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMe) ...[
                Text(
                  msg.time,
                  style: const TextStyle(color: Colors.white30, fontSize: 10),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF2E1A47) : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 16),
                    ),
                    border: Border.all(
                      color: isMe ? const Color(0xFFFF9100).withOpacity(0.3) : Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Text(
                    msg.message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
              if (!isMe) ...[
                const SizedBox(width: 6),
                Text(
                  msg.time,
                  style: const TextStyle(color: Colors.white30, fontSize: 10),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E1A47).withOpacity(0.6),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '메시지를 입력해 주세요.',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFFF9100)),
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFFFF9100),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
