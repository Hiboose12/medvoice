import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/patient/data/patient_repository.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_post.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_status.dart';
import 'package:medvoice_flutter/features/patient/presentation/utils/time_helper.dart';

// Extensions for file type detection
extension _UrlExtension on String {
  bool get isImageUrl {
    final ext = toLowerCase().split('?').first.split('.').last;
    return ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'].contains(ext);
  }

  bool get isVideoUrl {
    final ext = toLowerCase().split('?').first.split('.').last;
    return ['mp4', 'mov', 'avi', 'webm', 'mkv'].contains(ext);
  }
}

class ComplaintPostCard extends StatefulWidget {
  const ComplaintPostCard({
    super.key,
    required this.post,
    required this.onLike,
    this.onCommentAdded,
  });

  final ComplaintPost post;
  final VoidCallback onLike;
  final VoidCallback? onCommentAdded;

  @override
  State<ComplaintPostCard> createState() => _ComplaintPostCardState();
}

class _ComplaintPostCardState extends State<ComplaintPostCard> {
  final _repo = PatientRepository();
  final _commentController = TextEditingController();
  bool _showComments = false;
  bool _isSendingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSendingComment = true);
    try {
      await _repo.addComment(widget.post.id, content);
      _commentController.clear();
      if (widget.onCommentAdded != null) {
        widget.onCommentAdded!();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added!'),
            backgroundColor: PatientColors.medicalTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: PatientColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuthorHeader(post: post),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => context.push(RoutePaths.patientComplaintDetail(post.id)),
                  child: Text(
                    post.title,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: PatientColors.textMain,
                      decoration: TextDecoration.underline,
                      decorationColor: PatientColors.textMain.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: PatientColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TagChip(
                      label: post.hospitalName,
                      background: PatientColors.cardElevated,
                      foreground: const Color(0xFF52525B),
                    ),
                    _TagChip(
                      label: post.category,
                      background: PatientColors.cardElevated,
                      foreground: PatientColors.primary,
                    ),
                    _TagChip(
                      label: '${post.severity.label} Severity',
                      background: _severityColors(post.severity).$1,
                      foreground: _severityColors(post.severity).$2,
                    ),
                  ],
                ),

                // Evidence media section
                if (post.evidenceUrl != null && post.evidenceUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildEvidenceWidget(post.evidenceUrl!),
                ],

                if (post.hospitalResponses.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ...post.hospitalResponses.map(
                    (r) => _HospitalResponseCard(response: r),
                  ),
                ],
                const SizedBox(height: 20),
                const Divider(color: PatientColors.cardBorder),
                const SizedBox(height: 12),
                Row(
                  children: [
                    InkWell(
                      onTap: widget.onLike,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              post.isLiked
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_outlined,
                              size: 20,
                              color: post.isLiked
                                  ? PatientColors.primary
                                  : PatientColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${post.likes}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: post.isLiked
                                    ? PatientColors.primary
                                    : PatientColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Clickable comment icon to toggle comments section
                    InkWell(
                      onTap: () => setState(() => _showComments = !_showComments),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              _showComments
                                  ? Icons.chat_bubble
                                  : Icons.chat_bubble_outline,
                              size: 20,
                              color: _showComments
                                  ? PatientColors.primary
                                  : PatientColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${post.comments.length}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _showComments
                                    ? PatientColors.primary
                                    : PatientColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share functionality coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.share_outlined, size: 20, color: PatientColors.textMuted),
                      tooltip: 'Share Complaint',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Spacer(),
                    if (!post.isOwner && post.authorId != null) ...[
                      TextButton.icon(
                        onPressed: () async {
                          try {
                            final chat = await PatientRepository().startChat(post.authorId!);
                            if (context.mounted) {
                              context.push(RoutePaths.patientChatDetail(chat.id));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to start chat: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 14, color: PatientColors.primary),
                        label: const Text('Chat', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                      const SizedBox(width: 4),
                    ],
                    TextButton.icon(
                      onPressed: () => context.push(RoutePaths.patientComplaintDetail(post.id)),
                      icon: const Icon(Icons.open_in_new, size: 14, color: PatientColors.primary),
                      label: const Text('View Details', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Inline comments drawer (togglable)
          if (_showComments)
            _buildCommentsSection(post),
        ],
      ),
    );
  }

  Widget _buildEvidenceWidget(String url) {
    if (url.isVideoUrl) {
      return GestureDetector(
        onTap: () {
          // Open url in web view / external browser
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Video evidence attached. Tap to open.'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () {
                  // Could launch URL with url_launcher package
                },
              ),
            ),
          );
        },
        child: Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: PatientColors.cardElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PatientColors.cardBorder),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.play_circle_fill, size: 60, color: PatientColors.primary),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Video Evidence', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default to rendering as an image
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: PatientColors.cardElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator(color: PatientColors.primary)),
          );
        },
        errorBuilder: (ctx, err, st) => Container(
          height: 120,
          decoration: BoxDecoration(
            color: PatientColors.cardElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PatientColors.cardBorder),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_outlined, color: PatientColors.textMuted, size: 32),
                SizedBox(height: 4),
                Text('Unable to load image', style: TextStyle(color: PatientColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsSection(ComplaintPost post) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1623),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(top: BorderSide(color: PatientColors.cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comments list
          if (post.comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: post.comments.map((c) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PatientColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PatientColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${c.username}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: PatientColors.textMain,
                                ),
                              ),
                              TextSpan(
                                text: c.content,
                                style: const TextStyle(color: PatientColors.textMain),
                              ),
                            ],
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatFeedDate(c.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: PatientColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'No comments yet. Be the first to comment!',
                style: TextStyle(fontSize: 13, color: PatientColors.textMuted),
              ),
            ),

          // Comment input field
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(fontSize: 13, color: PatientColors.textMain),
                    decoration: InputDecoration(
                      hintText: 'Write a comment…',
                      hintStyle: const TextStyle(fontSize: 13, color: PatientColors.textMuted),
                      filled: true,
                      fillColor: PatientColors.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: PatientColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: PatientColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: PatientColors.primary, width: 2),
                      ),
                    ),
                    onSubmitted: (_) => _submitComment(),
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
                    onPressed: _isSendingComment ? null : _submitComment,
                    icon: _isSendingComment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 18),
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _severityColors(ComplaintSeverity severity) {
    return switch (severity) {
      ComplaintSeverity.high => (
          const Color(0xFF321218),
          PatientColors.medicalRed,
        ),
      ComplaintSeverity.medium => (
          const Color(0xFF33260A),
          PatientColors.medicalOrange,
        ),
      ComplaintSeverity.low => (
          const Color(0xFF0F2A1D),
          PatientColors.medicalTeal,
        ),
    };
  }
}

class _AuthorHeader extends StatelessWidget {
  const _AuthorHeader({required this.post});

  final ComplaintPost post;

  @override
  Widget build(BuildContext context) {
    if (post.isAnonymous) {
      return Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: PatientColors.cardElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.visibility_off_outlined,
              size: 20,
              color: Color(0xFFA1A1AA),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Anonymous User',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF52525B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PatientColors.cardElevated,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: PatientColors.border),
                    ),
                    child: const Text(
                      'Hidden',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF71717A),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                formatFeedDate(post.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: PatientColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: PatientColors.cardElevated,
          child: Text(
            post.authorInitial.toUpperCase(),
            style: const TextStyle(
              color: PatientColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.authorName,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              formatFeedDate(post.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: PatientColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _HospitalResponseCard extends StatelessWidget {
  const _HospitalResponseCard({required this.response});

  final HospitalResponse response;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0D137FEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33137FEC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: PatientColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      response.hospitalName,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'OFFICIAL RESPONSE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: PatientColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  response.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
