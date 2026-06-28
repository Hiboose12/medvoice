import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/patient/data/patient_repository.dart';

/// Support Ticket screen supporting New Ticket creation and viewing Past Tickets.
class PatientSupportScreen extends StatefulWidget {
  const PatientSupportScreen({super.key});

  @override
  State<PatientSupportScreen> createState() => _PatientSupportScreenState();
}

class _PatientSupportScreenState extends State<PatientSupportScreen> {
  final _repo = PatientRepository();
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _submitted = false;

  List<dynamic> _tickets = [];
  bool _isLoadingTickets = false;
  String? _ticketsError;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    if (mounted) {
      setState(() {
        _isLoadingTickets = true;
        _ticketsError = null;
      });
    }
    try {
      final tickets = await _repo.getSupportTickets();
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _isLoadingTickets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ticketsError = e.toString();
          _isLoadingTickets = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await _repo.submitSupportTicket(
        subject: _subjectCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
      );
      _subjectCtrl.clear();
      _messageCtrl.clear();
      await _loadTickets(); // Reload list to include the new ticket
      if (mounted) {
        setState(() {
          _submitted = true;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: PatientColors.bgLight,
        appBar: AppBar(
          backgroundColor: PatientColors.card,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: PatientColors.textMain),
            onPressed: () => context.canPop() ? context.pop() : null,
          ),
          title: Text(
            'Patient Support',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: PatientColors.textMain,
            ),
          ),
          bottom: TabBar(
            labelColor: PatientColors.primary,
            unselectedLabelColor: PatientColors.textMuted,
            indicatorColor: PatientColors.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: 'New Ticket'),
              Tab(text: 'Past Tickets'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _submitted ? _buildSuccess() : _buildForm(),
                ),
              ),
            ),
            _buildTicketsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: Color(0x1A4CAF50),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 50,
            color: PatientColors.medicalTeal,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Ticket Submitted!',
          style: GoogleFonts.manrope(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: PatientColors.textMain,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your support request has been submitted successfully.\nYou can track updates on the "Past Tickets" tab.',
          textAlign: TextAlign.center,
          style: TextStyle(color: PatientColors.textMuted, height: 1.6),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _submitted = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PatientColors.cardElevated,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: PatientColors.border),
                ),
              ),
              child: const Text('Create Another', style: TextStyle(color: PatientColors.textMain)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _submitted = false;
                });
                DefaultTabController.of(context).animateTo(1); // Switch to Past Tickets tab
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PatientColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Tickets', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF137FEC), Color(0xFF0B5EAF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How can we help?',
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Submit a support ticket and we will get back to you.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Common issues chips
          Text(
            'Common Issues',
            style: GoogleFonts.manrope(
              fontSize: 14, fontWeight: FontWeight.w700, color: PatientColors.textMuted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Account access issue',
              'Complaint not appearing',
              'Hospital not responding',
              'Incorrect hospital info',
              'Privacy concern',
              'Other',
            ].map((issue) => ActionChip(
              label: Text(issue, style: const TextStyle(fontSize: 12, color: PatientColors.textMain)),
              onPressed: () {
                _subjectCtrl.text = issue;
              },
              backgroundColor: PatientColors.cardElevated,
              side: const BorderSide(color: PatientColors.border),
            )).toList(),
          ),
          const SizedBox(height: 24),

          // Subject field
          _buildLabel('Subject'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _subjectCtrl,
            style: const TextStyle(color: PatientColors.textMain),
            decoration: _inputDecoration(
              hint: 'e.g. I cannot access my complaint',
              icon: Icons.subject_outlined,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
          ),
          const SizedBox(height: 20),

          // Message field
          _buildLabel('Message'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _messageCtrl,
            maxLines: 7,
            style: const TextStyle(color: PatientColors.textMain),
            decoration: _inputDecoration(
              hint: 'Describe your issue in detail...',
              icon: Icons.message_outlined,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Message is required'
                : v.trim().length < 20
                    ? 'Message must be at least 20 characters'
                    : null,
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_outlined, color: Colors.white),
              label: Text(
                _isSubmitting ? 'Submitting...' : 'Submit Support Ticket',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PatientColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Info note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PatientColors.cardElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PatientColors.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: PatientColors.textMuted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Our support team typically responds within 24–48 hours. '
                    'You will receive a notification when we reply to your ticket.',
                    style: TextStyle(fontSize: 13, color: PatientColors.textMuted, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 14, fontWeight: FontWeight.w700, color: PatientColors.textMain),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: PatientColors.textMuted),
      prefixIcon: Icon(icon, color: PatientColors.textMuted, size: 20),
      filled: true,
      fillColor: PatientColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PatientColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PatientColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PatientColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PatientColors.medicalRed),
      ),
    );
  }

  Widget _buildTicketsTab() {
    if (_isLoadingTickets && _tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: PatientColors.primary));
    }

    if (_ticketsError != null && _tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: PatientColors.medicalRed),
              const SizedBox(height: 16),
              Text(
                'Failed to load tickets',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PatientColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _ticketsError!,
                style: const TextStyle(color: PatientColors.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadTickets,
                style: ElevatedButton.styleFrom(backgroundColor: PatientColors.primary),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_tickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTickets,
        color: PatientColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: PatientColors.cardElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_outlined, size: 32, color: PatientColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No support tickets found',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: PatientColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Submit a ticket in the "New Ticket" tab.',
                    style: TextStyle(color: PatientColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      color: PatientColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          final status = ticket['status'] ?? 'open';
          final isResolved = status == 'resolved';
          final createdDate = _formatDate(ticket['created_at'] ?? '');

          return Card(
            color: PatientColors.card,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: PatientColors.cardBorder),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                context.push('/patient/support/${ticket['id']}');
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            ticket['subject'] ?? '',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: PatientColors.textMain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isResolved ? Colors.green.withValues(alpha: 0.1) : PatientColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(height: 8),
                    Text(
                      ticket['message'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: PatientColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          createdDate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: PatientColors.textMuted,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Open Chat',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: PatientColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 10,
                              color: PatientColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
