import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:medvoice_flutter/features/auth/domain/models/user_role.dart';
import 'package:medvoice_flutter/features/operations/data/hospital_repository.dart';
import 'package:medvoice_flutter/features/patient/data/patient_repository.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_post.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_status.dart';
import 'package:dio/dio.dart';
import 'package:medvoice_flutter/features/patient/presentation/utils/time_helper.dart';

/// Full complaint detail page — displays complete description, timeline, comments,
/// evidence attachments, and official responses. Includes control panel for hospitals.
class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({super.key, required this.complaintId});

  final int complaintId;

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final _repo = PatientRepository();
  final _hospitalRepo = HospitalRepository();
  final _commentController = TextEditingController();
  final _hospitalResponseController = TextEditingController();

  ComplaintPost? _complaint;
  bool _isLoading = true;
  bool _isSendingComment = false;
  bool _isSendingHospitalResponse = false;
  bool _isPrivateResponse = false;
  bool _isResolving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComplaint();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _hospitalResponseController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaint() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final complaint = await _repo.getComplaintDetail(widget.complaintId);
      if (mounted) {
        setState(() {
          _complaint = complaint;
          _isLoading = false;
        });
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

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSendingComment = true);
    try {
      await _repo.addComment(widget.complaintId, content);
      _commentController.clear();
      await _loadComplaint();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  Future<void> _submitHospitalResponse() async {
    final text = _hospitalResponseController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingHospitalResponse = true);
    try {
      await _hospitalRepo.respondToComplaint(widget.complaintId, text, isPrivate: _isPrivateResponse);
      _hospitalResponseController.clear();
      _isPrivateResponse = false;
      await _loadComplaint();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Official response posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post response: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingHospitalResponse = false);
    }
  }

  Future<void> _updateHospitalStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      if (newStatus.toLowerCase() == 'resolved') {
        await _hospitalRepo.resolveComplaint(widget.complaintId);
      } else {
        await _hospitalRepo.updateComplaintStatus(widget.complaintId, newStatus);
      }
      await _loadComplaint();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${newStatus.toUpperCase()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markResolved(String resolution) async {
    setState(() => _isResolving = true);
    try {
      await _repo.markComplaintResolved(widget.complaintId, resolution);
      await _loadComplaint();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Complaint marked as $resolution!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as $resolution: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  Future<void> _startChat() async {
    try {
      final chat = await _repo.startComplaintChat(widget.complaintId);
      if (mounted) context.push(RoutePaths.patientChatDetail(chat.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  Future<void> _deleteComplaint() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Complaint'),
        content: const Text('Are you sure you want to delete this complaint? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: PatientColors.medicalRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    try {
      await _repo.deleteComplaint(widget.complaintId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint deleted successfully.')));
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/patient/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Future<void> _editComplaint() async {
    final titleCtrl = TextEditingController(text: _complaint!.title);
    final descCtrl = TextEditingController(text: _complaint!.description);
    
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Complaint'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    
    if (submitted != true) return;
    
    setState(() => _isLoading = true);
    try {
      final formData = FormData.fromMap({
        'title': titleCtrl.text,
        'description': descCtrl.text,
      });
      await _repo.editComplaint(widget.complaintId, formData);
      await _loadComplaint();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint updated successfully.')));
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to edit: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: PatientColors.bgLight,
      appBar: AppBar(
        backgroundColor: PatientColors.bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PatientColors.textMain),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(user?.role.dashboardPath ?? RoutePaths.patientFeed);
            }
          },
        ),
        title: Text(
          'Complaint Detail',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PatientColors.textMain,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PatientColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: PatientColors.medicalRed),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: PatientColors.textMuted),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadComplaint,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadComplaint,
                  child: _buildBody(user),
                ),
    );
  }

  Widget _buildBody(dynamic user) {
    final c = _complaint!;
    final bool isHospital = user?.role == UserRole.hospital;
    final bool isAssignedHospital = isHospital && c.hospitalId == user?.id;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status + Date Header ───────────────
              Row(
                children: [
                  _StatusBadge(status: c.status),
                  const Spacer(),
                  Text(
                    formatFeedDate(c.createdAt),
                    style: const TextStyle(color: PatientColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Title ──────────────────────────────
              Text(
                c.title,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: PatientColors.textMain,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),

              // ── Meta chips ─────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(label: c.hospitalName, icon: Icons.local_hospital_outlined),
                  _Chip(label: c.category, icon: Icons.category_outlined),
                  _Chip(
                    label: '${c.severity.label} Severity',
                    icon: Icons.warning_amber_outlined,
                    color: _severityColor(c.severity),
                  ),
                  _Chip(
                    label: c.isAnonymous ? 'Anonymous Patient' : 'By ${c.authorName}',
                    icon: Icons.person_outline,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Description ────────────────────────
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complaint Description',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PatientColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: PatientColors.textMain,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Evidence / Attachments ─────────────
              if (c.evidenceUrl != null && c.evidenceUrl!.isNotEmpty) ...[
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evidence / Attachments',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: PatientColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: PatientColors.cardElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PatientColors.border),
                        ),
                        child: Image.network(
                          c.evidenceUrl!.startsWith('http')
                              ? c.evidenceUrl!
                              : 'http://192.168.39.110:8000${c.evidenceUrl}',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.broken_image_outlined, color: PatientColors.textMuted, size: 48),
                                  SizedBox(height: 8),
                                  Text('Preview not available', style: TextStyle(color: PatientColors.textMuted)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Progress Timeline ──────────────────
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complaint Progress',
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: PatientColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    _ProgressTimeline(complaint: c),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Hospital Resolution Console (Hospital role and assigned) ──
              if (isAssignedHospital) ...[
                _buildHospitalControlPanel(c),
                const SizedBox(height: 16),
              ],

              // ── Hospital Responses ─────────────────
              if (c.hospitalResponses.isNotEmpty) ...[
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hospital Responses',
                        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: PatientColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      ...c.hospitalResponses.map(_buildHospitalResponse),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Patient Owner Action Buttons ─────────────────────
              if (user?.role == UserRole.patient && c.isOwner) ...[
                _Card(
                  child: Column(
                    children: [
                      if (c.status != ComplaintStatus.resolved) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isResolving ? null : () => _markResolved('satisfied'),
                                icon: _isResolving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.sentiment_very_satisfied, size: 18),
                                label: const Text('Satisfied'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PatientColors.medicalTeal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isResolving ? null : () => _markResolved('resolved'),
                                icon: _isResolving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('Resolved'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PatientColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _startChat,
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Chat with Hospital'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: PatientColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _editComplaint,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: PatientColors.textMain,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _deleteComplaint,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: PatientColors.medicalRed,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: PatientColors.medicalRed),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Comments ───────────────────────────
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comments (${c.comments.length})',
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: PatientColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    if (c.comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No comments yet.', style: TextStyle(color: PatientColors.textMuted)),
                      )
                    else
                      ...c.comments.map(_buildComment),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: PatientColors.textMain),
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              hintStyle: const TextStyle(color: PatientColors.textMuted),
                              filled: true,
                              fillColor: PatientColors.cardElevated,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: PatientColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: PatientColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: PatientColors.primary),
                              ),
                            ),
                            onSubmitted: (_) => _addComment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isSendingComment ? null : _addComment,
                          icon: _isSendingComment
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send, color: PatientColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalControlPanel(ComplaintPost c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientColors.primary.withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_outlined, color: PatientColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Hospital Resolution Console',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: PatientColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dropdown for status update
          Row(
            children: [
              const Text(
                'Update Status: ',
                style: TextStyle(color: PatientColors.textMain, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: PatientColors.cardElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PatientColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: PatientColors.cardElevated,
                      value: c.status.value,
                      style: const TextStyle(color: PatientColors.textMain, fontWeight: FontWeight.w600),
                      icon: const Icon(Icons.arrow_drop_down, color: PatientColors.textMuted),
                      items: [
                        const DropdownMenuItem(value: 'new', child: Text('New')),
                        const DropdownMenuItem(value: 'review', child: Text('Investigating / In Review')),
                        const DropdownMenuItem(value: 'responded', child: Text('Responded')),
                        if (c.status.value == 'resolved')
                          const DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                        const DropdownMenuItem(value: 'escalated', child: Text('Escalated')),
                      ],
                      onChanged: c.status.value == 'resolved'
                          ? null
                          : (newStatus) {
                              if (newStatus != null) {
                                _updateHospitalStatus(newStatus);
                              }
                            },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: PatientColors.border),
          const SizedBox(height: 16),
          Text(
            'Submit Official Response',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: PatientColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'This response will be featured prominently as the official hospital statement.',
            style: TextStyle(
              fontSize: 12,
              color: PatientColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hospitalResponseController,
            maxLines: 4,
            style: const TextStyle(color: PatientColors.textMain),
            decoration: InputDecoration(
              hintText: 'Provide details about investigation steps, policies, or resolution...',
              hintStyle: const TextStyle(color: PatientColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: PatientColors.cardElevated,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PatientColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PatientColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PatientColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _isPrivateResponse,
                activeColor: PatientColors.primary,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _isPrivateResponse = val;
                    });
                  }
                },
              ),
              const Expanded(
                child: Text(
                  'Post response privately (Visible only to patient & authority)',
                  style: TextStyle(color: PatientColors.textMain, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSendingHospitalResponse ? null : _submitHospitalResponse,
              icon: _isSendingHospitalResponse
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.publish_outlined, size: 18),
              label: const Text('Post Official Response', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: PatientColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _startChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 18, color: PatientColors.primary),
              label: const Text('Chat with Patient', style: TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: PatientColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalResponse(HospitalResponse response) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
            height: 56,
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
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: PatientColors.textMain),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'OFFICIAL RESPONSE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8), letterSpacing: 0.5),
                      ),
                    ),
                    if (response.isPrivate) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'PRIVATE',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFDC2626), letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(response.message, style: const TextStyle(fontSize: 14, height: 1.5, color: PatientColors.textMain)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(ComplaintComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PatientColors.cardElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${comment.username}: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: comment.content),
                ],
                style: const TextStyle(fontSize: 14, color: PatientColors.textMain),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatFeedDate(comment.createdAt),
              style: const TextStyle(fontSize: 12, color: PatientColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(ComplaintSeverity severity) {
    return switch (severity) {
      ComplaintSeverity.high => PatientColors.medicalRed,
      ComplaintSeverity.medium => PatientColors.medicalOrange,
      ComplaintSeverity.low => PatientColors.medicalTeal,
    };
  }
}

// ── Reusable widgets ─────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ComplaintStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      ComplaintStatus.newComplaint => (const Color(0x1AFF9800), PatientColors.medicalOrange),
      ComplaintStatus.review => (const Color(0x1A2196F3), PatientColors.primary),
      ComplaintStatus.responded => (const Color(0x1A9C27B0), const Color(0xFFE040FB)),
      ComplaintStatus.resolved => (const Color(0x1A4CAF50), PatientColors.medicalTeal),
      ComplaintStatus.escalated => (const Color(0x1AF44336), PatientColors.medicalRed),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg, letterSpacing: 0.5),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon, this.color});
  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: PatientColors.cardElevated,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? PatientColors.textMuted),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? PatientColors.textMuted)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientColors.cardBorder),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class _ProgressTimeline extends StatelessWidget {
  const _ProgressTimeline({required this.complaint});
  final ComplaintPost complaint;

  @override
  Widget build(BuildContext context) {
    final steps = <_TimelineStep>[
      _TimelineStep('Submitted', complaint.createdAt, true),
      _TimelineStep('Under Review', null, complaint.status.index >= ComplaintStatus.review.index),
      _TimelineStep('Hospital Responded', null, complaint.status.index >= ComplaintStatus.responded.index),
      _TimelineStep('Resolved', null, complaint.status == ComplaintStatus.resolved),
    ];

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: steps[i].isActive ? PatientColors.primary : PatientColors.cardElevated,
                      border: Border.all(
                        color: steps[i].isActive ? PatientColors.primary : PatientColors.border,
                        width: 2,
                      ),
                    ),
                    child: steps[i].isActive
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 28,
                      color: steps[i].isActive ? PatientColors.primary : PatientColors.border,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[i].label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: steps[i].isActive ? FontWeight.w700 : FontWeight.w500,
                          color: steps[i].isActive ? PatientColors.textMain : PatientColors.textMuted,
                        ),
                      ),
                      if (steps[i].date != null)
                        Text(
                          formatFeedDate(steps[i].date!),
                          style: const TextStyle(fontSize: 12, color: PatientColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TimelineStep {
  const _TimelineStep(this.label, this.date, this.isActive);
  final String label;
  final DateTime? date;
  final bool isActive;
}
