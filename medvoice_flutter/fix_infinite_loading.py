import re

def fix_review_details(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # We need to replace the _ReviewDetailsPageState implementation.
    # First, let's find class _ReviewDetailsPageState extends State<_ReviewDetailsPage> {
    start_str = "class _ReviewDetailsPageState extends State<_ReviewDetailsPage> {"
    start_idx = content.find(start_str)
    if start_idx == -1:
        print("Could not find start.")
        return

    # Find the end of the class. It ends before class _DetailSection extends StatelessWidget {
    end_str = "class _DetailSection extends StatelessWidget {"
    end_idx = content.find(end_str, start_idx)
    if end_idx == -1:
        print("Could not find end.")
        return
        
    old_class = content[start_idx:end_idx]
    
    # We will modify the initState and build method.
    new_class = """class _ReviewDetailsPageState extends State<_ReviewDetailsPage> {
  final _reasonController = TextEditingController();
  late Future<Map<String, dynamic>?> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  Future<Map<String, dynamic>?> _loadDetails() async {
    await Future.microtask(() {});
    if (!mounted) return null;
    return context.read<AdminProvider>().loadEntityVerificationDetail(widget.entityType, widget.entityId);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    
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
    // DO NOT use context.watch here to avoid infinite rebuilds!
    final adminProv = context.read<AdminProvider>();

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
        future: _detailsFuture,
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
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    color: Colors.green,
                                    child: const Center(child: Text('ALREADY APPROVED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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

"""
    new_content = content.replace(old_class, new_class)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
        print("Fixed infinite loading in Review Details.")

fix_review_details(r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\operations\presentation\screens\operational_screen.dart')
