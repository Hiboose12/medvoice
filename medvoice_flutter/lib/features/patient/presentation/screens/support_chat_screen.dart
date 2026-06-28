import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/patient/data/patient_repository.dart';

/// Support Ticket detail screen displaying consolidated messages thread.
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _repo = PatientRepository();
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;

  Map<String, dynamic>? _ticketDetail;
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
    // Poll for support ticket updates every 3 seconds for real-time feel
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollTicketMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Silent background polling for ticket messages.
  Future<void> _pollTicketMessages() async {
    if (!mounted || _isSending) return;
    try {
      final detail = await _repo.getSupportTicketDetail(widget.ticketId);
      final newMessages = detail['messages'] ?? [];
      if (mounted && newMessages.length != _messages.length) {
        setState(() {
          _ticketDetail = detail;
          _messages = newMessages;
        });
        _scrollToBottom();
      }
    } catch (_) {
      // silently ignore poll errors
    }
  }

  Future<void> _loadTicketDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final detail = await _repo.getSupportTicketDetail(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticketDetail = detail;
          _messages = detail['messages'] ?? [];
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendReply() async {
    final content = _msgController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _repo.sendSupportTicketReply(widget.ticketId, content);
      _msgController.clear();
      await _loadTicketDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reply: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
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

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = _ticketDetail?['subject'] ?? 'Support Thread';
    final status = _ticketDetail?['status'] ?? 'open';
    final isResolved = status == 'resolved';

    return Scaffold(
      backgroundColor: PatientColors.bgLight,
      appBar: AppBar(
        backgroundColor: PatientColors.card,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PatientColors.textMain),
          onPressed: () => context.canPop() ? context.pop() : context.go('/patient/support'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: PatientColors.textMain,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isResolved ? Colors.green.withValues(alpha: 0.1) : PatientColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isResolved ? Colors.green : PatientColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: PatientColors.textMuted),
            onPressed: _loadTicketDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PatientColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Error loading support thread',
                          style: GoogleFonts.manrope(
                            color: PatientColors.textMain,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: PatientColors.textMuted, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTicketDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PatientColors.primary,
                          ),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
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
              child: const Icon(Icons.support_agent, size: 28, color: PatientColors.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              'No messages in thread',
              style: GoogleFonts.manrope(
                color: PatientColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
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
        final isMe = msg['sender'] == 'patient';
        final senderLabel = isMe ? 'You' : 'Support Agent';
        final timeLabel = _formatTime(msg['created_at'] ?? '');

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.only(bottom: 12),
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
                  color: Colors.black.withValues(alpha: 0.04),
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
                      senderLabel,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: PatientColors.primary,
                      ),
                    ),
                  ),
                Text(
                  msg['message'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isMe ? Colors.white : PatientColors.textMain,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                if (timeLabel.isNotEmpty)
                  Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : PatientColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        );
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
                style: const TextStyle(color: PatientColors.textMain),
                decoration: InputDecoration(
                  hintText: 'Type a message to support...',
                  hintStyle: const TextStyle(color: PatientColors.textMuted),
                  filled: true,
                  fillColor: PatientColors.cardElevated,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendReply(),
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
                onPressed: _isSending ? null : _sendReply,
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
