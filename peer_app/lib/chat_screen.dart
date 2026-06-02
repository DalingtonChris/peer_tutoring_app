import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final int receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _baseUrl = 'http://192.168.1.145:3000';

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  late IO.Socket _socket;
  bool _isConnected = false;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadMessageHistory();
    _initSocket();
  }

  // ── 1. Load past messages from MySQL ─────────────────────────────────────
  Future<void> _loadMessageHistory() async {
    try {
      final response = await http
          .get(Uri.parse(
              '$_baseUrl/api/messages/${widget.currentUserId}/${widget.receiverId}'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> history = jsonDecode(response.body);
        setState(() {
          _messages.addAll(history.map((m) => {
                'text': m['message_text'],
                'senderId': m['sender_id'],
                'time': m['created_at'],
              }));
          _isLoadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      setState(() => _isLoadingHistory = false);
    }
  }

  // ── 2. Connect to Socket.IO ───────────────────────────────────────────────
  void _initSocket() {
    _socket = IO.io(_baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      setState(() => _isConnected = true);
      // Join the shared room for these two users
      _socket.emit('join_room', {
        'senderId': widget.currentUserId,
        'receiverId': widget.receiverId,
      });
    });

    _socket.onDisconnect((_) => setState(() => _isConnected = false));

    // ── 3. Listen for incoming messages ──────────────────────────────────
    _socket.on('receive_message', (data) {
      // Avoid duplicating the message we just sent ourselves
      if (data['sender_id'] != widget.currentUserId) {
        setState(() {
          _messages.add({
            'text': data['message_text'],
            'senderId': data['sender_id'],
            'time': data['timestamp'],
          });
        });
        _scrollToBottom();
      }
    });
  }

  // ── 4. Send a message ─────────────────────────────────────────────────────
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final messageData = {
      'sender_id': widget.currentUserId,
      'receiver_id': widget.receiverId,
      'message_text': text,
    };

    // Optimistically add to UI
    setState(() {
      _messages.add({
        'text': text,
        'senderId': widget.currentUserId,
        'time': DateTime.now().toIso8601String(),
      });
    });

    _socket.emit('send_message', messageData);
    _messageController.clear();
    _scrollToBottom();
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
  void dispose() {
    _socket.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF7B2FBE).withOpacity(0.15),
              child: Text(
                widget.receiverName[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF7B2FBE),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _isConnected ? 'Online' : 'Connecting...',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isConnected ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Message List ───────────────────────────────────────────────────
          Expanded(
            child: _isLoadingHistory
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7B2FBE)),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 56,
                                color: Colors.grey.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            const Text(
                              'No messages yet.\nSay hello! 👋',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFFAAAAAA), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe =
                              msg['senderId'] == widget.currentUserId;
                          return _buildBubble(msg, isMe);
                        },
                      ),
          ),

          // ── Input Bar ──────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle:
                            const TextStyle(color: Color(0xFFAAAAAA)),
                        filled: true,
                        fillColor: const Color(0xFFF3EEF9),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7B2FBE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF7B2FBE) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'] ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF1A1A2E),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg['time']?.toString()),
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}