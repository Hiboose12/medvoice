import re

def replace_entity_verification(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    start_str = "class _EntityVerificationPage extends StatefulWidget {"
    start_idx = content.find(start_str)
    
    end_str = "class _AuditLogsPage extends StatefulWidget {"
    end_idx = content.find(end_str, start_idx)
    
    if start_idx == -1 or end_idx == -1:
        print("Could not find bounds.")
        return
        
    old_code = content[start_idx:end_idx]
    
    new_code = """class _EntityVerificationPage extends StatefulWidget {
  const _EntityVerificationPage();

  @override
  State<_EntityVerificationPage> createState() => _EntityVerificationPageState();
}

class _EntityVerificationPageState extends State<_EntityVerificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadEntityVerification();
    });
  }

  void _refresh() {
    context.read<AdminProvider>().loadEntityVerification();
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final pendingEntities = adminProv.pendingEntities;
    
    final totalPending = pendingEntities.length;
    final hospitalCount = pendingEntities.where((e) => e['entity_type'] == 'hospital').length;
    final authorityCount = pendingEntities.where((e) => e['entity_type'] == 'authority').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Verification Panel',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Review and approve Hospital Admins and Health Authorities.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _StatCard(title: 'Total Pending', value: totalPending.toString(), color: AppColors.primary)),
            const SizedBox(width: 24),
            Expanded(child: _StatCard(title: 'Hospital Admins', value: hospitalCount.toString(), color: Colors.blue)),
            const SizedBox(width: 24),
            Expanded(child: _StatCard(title: 'Health Authorities', value: authorityCount.toString(), color: Colors.green)),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  'Pending Approvals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Container(
                color: AppColors.secondaryBackground,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('Applicant', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 1, child: Text('Role Request', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 1, child: Text('Applied Date', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 1, child: Text('Status', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                    SizedBox(width: 120, child: Text('Action', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              if (adminProv.isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.admin)),
                )
              else if (pendingEntities.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No entities pending verification.', style: TextStyle(color: AppColors.textSecondary))),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingEntities.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final item = pendingEntities[index];
                    final String name = item['name'] ?? item['username'] ?? '';
                    final String email = item['email'] ?? '';
                    final String type = item['entity_type'] ?? '';
                    final String dateJoined = item['date_joined'] ?? 'N/A';
                    final int entityId = item['id'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: type == 'hospital' ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: type == 'hospital' ? Colors.blue.withOpacity(0.3) : Colors.purple.withOpacity(0.3)),
                                ),
                                child: Text(
                                  type.substring(0, 1).toUpperCase() + type.substring(1),
                                  style: TextStyle(
                                    color: type == 'hospital' ? Colors.blue : Colors.purple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              dateJoined.split('T')[0], // simplistic date format handling
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: const Text(
                                  'Pending',
                                  style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => _ReviewDetailsPage(
                                        entityType: type,
                                        entityId: entityId,
                                        onRefresh: _refresh,
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: const Text('View Details', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

import 'package:url_launcher/url_launcher.dart';

class _ReviewDetailsPage extends StatefulWidget {
  final String entityType;
  final int entityId;
  final VoidCallback onRefresh;

  const _ReviewDetailsPage({required this.entityType, required this.entityId, required this.onRefresh});

  @override
  State<_ReviewDetailsPage> createState() => _ReviewDetailsPageState();
}

class _ReviewDetailsPageState extends State<_ReviewDetailsPage> {
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadEntityVerificationDetail(widget.entityType, widget.entityId);
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    
    // In Django, urls usually start with /media. In flutter app, network images need full domain.
    // However, since we don't have the domain hardcoded safely here, we'll construct it from ApiConstants if possible.
    // Assuming Endpoints.baseUrl or similar exists, or we just prepend 'http://127.0.0.1:8000' if it starts with '/'.
    String finalUrl = urlString;
    if (finalUrl.startsWith('/')) {
      finalUrl = 'http://127.0.0.1:8000$finalUrl';
    }
    
    final uri = Uri.tryParse(finalUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open document')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    // The details are fetched via Future in admin_provider but they aren't stored in state properly by loadEntityVerificationDetail.
    // Wait, loadEntityVerificationDetail returns a Future<Map<String, dynamic>?>, it doesn't store it!
    // So we need a FutureBuilder here!

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Review Details', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: adminProv.loadEntityVerificationDetail(widget.entityType, widget.entityId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.admin));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Failed to load details.', style: TextStyle(color: AppColors.error)));
          }

          final data = snapshot.data!;
          final user = data['user'] ?? {};
          final verification = data['verification'] ?? {};
          
          final addressLine1 = user['address_line_1'] ?? '';
          final addressLine2 = user['address_line_2'] ?? '';
          final address = '$addressLine1 $addressLine2'.trim();

          final isApproved = data['is_approved'] == true;
          
          List<Map<String, dynamic>> documents = [];
          if (data['documents'] != null) {
             documents = List<Map<String, dynamic>>.from(data['documents']);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Pending Approvals', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
                    const Text('Review Details', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _DetailSection(
                            title: 'Account Details',
                            fields: [
                              _DetailField('USERNAME', user['username'] ?? ''),
                              _DetailField('ROLE', widget.entityType.toUpperCase()),
                              _DetailField('EMAIL', user['email'] ?? ''),
                              _DetailField('PHONE', user['phone_number'] ?? '-'),
                              _DetailField('ADDRESS', address.isEmpty ? '-' : address, isFullWidth: true),
                              _DetailField('CITY', user['city'] ?? '-'),
                              _DetailField('STATE', user['state'] ?? '-'),
                              _DetailField('PINCODE', user['pincode'] ?? '-'),
                              _DetailField('REGISTERED', user['date_joined']?.split('T')[0] ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _DetailSection(
                            title: widget.entityType == 'authority' ? 'Authority Details' : 'Hospital Details',
                            fields: widget.entityType == 'authority' ? [
                              _DetailField('AUTHORITY NAME', user['first_name'] ?? '-'),
                              _DetailField('AUTHORITY TYPE', verification['authority_type'] ?? '-'),
                              _DetailField('DEPARTMENT', verification['department'] ?? '-'),
                              _DetailField('JURISDICTION LEVEL', verification['jurisdiction_level'] ?? '-'),
                              _DetailField('JURISDICTION STATE', verification['jurisdiction_state'] ?? '-'),
                              _DetailField('JURISDICTION DISTRICT', verification['jurisdiction_district'] ?? '-'),
                              _DetailField('OFFICE ADDRESS', verification['office_address'] ?? '-', isFullWidth: true),
                            ] : [
                              _DetailField('HOSPITAL NAME', user['first_name'] ?? '-'),
                              _DetailField('REGISTRATION NUMBER', verification['registration_number'] ?? '-'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 16),
                                if (documents.isEmpty)
                                  const Text('No documents uploaded.', style: TextStyle(color: AppColors.textSecondary))
                                else
                                  ...documents.map((doc) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () => _launchUrl(doc['url']),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.border),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.description, color: Colors.blue, size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(doc['label'] ?? 'Document', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                                  const Text('Click to preview', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.open_in_new, color: AppColors.textSecondary, size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 16),
                                if (isApproved)
                                  const Container(
                                    padding: EdgeInsets.all(12),
                                    color: Colors.green,
                                    child: Center(child: Text('ALREADY APPROVED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                  )
                                else ...[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                                    onPressed: () async {
                                      final success = await adminProv.verifyEntity(widget.entityType, widget.entityId, 'approve');
                                      if (success) {
                                        widget.onRefresh();
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _reasonController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: 'Optional rejection reason',
                                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                                      filled: true,
                                      fillColor: AppColors.secondaryBackground,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    ),
                                    style: const TextStyle(color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
                                    onPressed: () async {
                                      final success = await adminProv.verifyEntity(widget.entityType, widget.entityId, 'reject', reason: _reasonController.text);
                                      if (success) {
                                        widget.onRefresh();
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: const Text('Reject', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<_DetailField> fields;

  const _DetailSection({required this.title, required this.fields});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 24,
            children: fields.map((field) {
              return SizedBox(
                width: field.isFullWidth ? double.infinity : MediaQuery.of(context).size.width * 0.2, // Rough fraction for 2 columns
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(field.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(field.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DetailField {
  final String label;
  final String value;
  final bool isFullWidth;

  _DetailField(this.label, this.value, {this.isFullWidth = false});
}

"""
    
    new_content = content[:start_idx] + new_code + "\n" + content[end_idx:]
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
        print("Updated operational_screen.dart (Steps 3 & 4)")

replace_entity_verification(r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\operations\presentation\screens\operational_screen.dart')
