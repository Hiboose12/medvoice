import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:medvoice_flutter/features/auth/presentation/providers/auth_provider.dart';

class AccountFrozenScreen extends StatefulWidget {
  final int userId;
  
  const AccountFrozenScreen({super.key, required this.userId});

  @override
  State<AccountFrozenScreen> createState() => _AccountFrozenScreenState();
}

class _AccountFrozenScreenState extends State<AccountFrozenScreen> {
  final _reasonCtrl = TextEditingController();
  bool _isLoading = false;
  List<int>? _selectedFileBytes;
  String? _selectedFileName;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFileBytes = result.files.first.bytes;
          _selectedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitAppeal() async {
    if (widget.userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User session lost. Please go back to login and try again.'), backgroundColor: Colors.red),
      );
      return;
    }

    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reactivation reason.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.submitAppeal(
        widget.userId, 
        reason,
        evidenceBytes: _selectedFileBytes,
        evidenceFileName: _selectedFileName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appeal submitted successfully! Admin will review your account.'), backgroundColor: Colors.green),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit appeal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1215), // Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1215),
        elevation: 0,
        title: const Text('Account Status', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              width: 500, // Fixed width to prevent any constraint propagation issues
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF161A1D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF27272A), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2015),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.gavel_rounded,
                      color: Color(0xFFEBB02A),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'Account Frozen',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text(
                    'This account is frozen because of governance or authority action. Submit an explanation and evidence so the appeal can be reviewed.',
                    style: TextStyle(
                      color: Color(0xFFA1A1AA),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Text Area
                  TextField(
                    controller: _reasonCtrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Reactivation reason',
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: 'Please explain your situation...',
                      hintStyle: const TextStyle(color: Color(0xFF71717A)),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF27272A)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF22C55E)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // File Picker Button
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.attach_file, color: Color(0xFF22C55E), size: 18),
                        label: const Text(
                          'Attach evidence',
                          style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFF27272A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_selectedFileName != null)
                        Expanded(
                          child: Text(
                            _selectedFileName!,
                            style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Back to Login'),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitAppeal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text(
                              'Submit request',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
