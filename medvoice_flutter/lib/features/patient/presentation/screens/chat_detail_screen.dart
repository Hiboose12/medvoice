import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/patient/data/patient_repository.dart';
import 'package:medvoice_flutter/features/patient/domain/models/patient_models.dart';

/// Full chat thread screen — mirrors Django patient_chat_room.html.
class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.conversationId});

  final int conversationId;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _repo = PatientRepository();
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Poll for new messages every 3 seconds for real-time feel
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Silent background poll — doesn't show loading indicator.
  Future<void> _pollMessages() async {
    if (!mounted || _isSending) return;
    try {
      final messages = await _repo.getChatMessages(widget.conversationId);
      if (mounted && messages.length != _messages.length) {
        setState(() => _messages = messages);
        _scrollToBottom();
      }
    } catch (_) {
      // silently ignore poll errors
    }
  }

  Future<void> _loadMessages() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final messages = await _repo.getChatMessages(widget.conversationId);
      if (mounted) {
        setState(() { _messages = messages; _isLoading = false; });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _sendMessage() async {
    final content = _msgController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _repo.sendChatMessage(widget.conversationId, content);
      _msgController.clear();
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
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
      backgroundColor: PatientColors.bgLight,
      appBar: AppBar(
        backgroundColor: PatientColors.card,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PatientColors.textMain),
          onPressed: () => context.canPop() ? context.pop() : context.go('/patient/chat'),
        ),
        title: Text(
          'Conversation',
          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: PatientColors.textMain),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: PatientColors.textMuted),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PatientColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: PatientColors.textMuted)))
              : Column(
                  children: [
                    Expanded(child: _buildMessageList()),
                    _buildInputBar(),
                  ],
                ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: PatientColors.cardElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline, size: 28, color: PatientColors.textMuted),
            ),
            const SizedBox(height: 12),
            const Text('No messages yet', style: TextStyle(color: PatientColors.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('Start the conversation below.', style: TextStyle(color: PatientColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _MessageBubble(message: msg);
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: PatientColors.card,
        border: Border(top: BorderSide(color: PatientColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: PatientColors.cardElevated,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: PatientColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? PatientColors.primary : PatientColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
          border: isMe ? null : Border.all(color: PatientColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.sender,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: PatientColors.primary,
                  ),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : PatientColors.textMain,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.createdAtLabel,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : PatientColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
