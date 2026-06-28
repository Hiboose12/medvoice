import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/create_post_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/widgets/severity_selector.dart';
import 'package:provider/provider.dart';

/// Mirrors the upload modal form from `templates/complaints/feed.html`.
class CreatePostForm extends StatefulWidget {
  const CreatePostForm({
    super.key,
    required this.onSubmit,
    this.showHeader = true,
    this.onCancel,
  });

  final Future<void> Function(CreatePostFormData data) onSubmit;
  final bool showHeader;
  final VoidCallback? onCancel;

  @override
  State<CreatePostForm> createState() => _CreatePostFormState();
}

class CreatePostFormData {
  const CreatePostFormData({
    required this.title,
    required this.description,
    required this.category,
    this.unregisteredHospitalName,
  });

  final String title;
  final String description;
  final String category;
  final String? unregisteredHospitalName;
}

class _CreatePostFormState extends State<CreatePostForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _manualHospitalController = TextEditingController();
  String? _category;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreatePostProvider>().loadOptions();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _manualHospitalController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(CreatePostProvider provider) async {
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    await widget.onSubmit(
      CreatePostFormData(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category!,
        unregisteredHospitalName: provider.showManualHospital
            ? _manualHospitalController.text
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreatePostProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) ...[
          Text(
            'New Complaint',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: PatientColors.textMain,
            ),
          ),
          const SizedBox(height: 24),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x14137FEC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33137FEC)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: PatientColors.primary, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'End-to-end encrypted & confidential submission.',
                  style: TextStyle(
                    fontSize: 12,
                    color: PatientColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _FieldLabel(label: 'Title', required: true),
        const SizedBox(height: 4),
        _FormInput(
          controller: _titleController,
          hint: 'e.g., Long waiting times',
        ),
        const SizedBox(height: 20),
        const _FieldLabel(label: 'Healthcare Facility'),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: ValueKey(provider.selectedHospitalId),
          initialValue: provider.showManualHospital
              ? 'other'
              : provider.selectedHospitalId?.toString(),
          decoration: _inputDecoration(),
          hint: const Text('Select facility...'),
          items: [
            ...provider.hospitals.map(
              (h) => DropdownMenuItem(
                value: h.id.toString(),
                child: Text(h.name),
              ),
            ),
            const DropdownMenuItem(
              value: 'other',
              child: Text(
                '+ Other / Not Listed',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: PatientColors.primary,
                ),
              ),
            ),
          ],
          onChanged: provider.setHospitalSelection,
        ),
        if (provider.showManualHospital) ...[
          const SizedBox(height: 12),
          _FormInput(
            controller: _manualHospitalController,
            hint: 'Enter facility name',
          ),
        ],
        const SizedBox(height: 20),
        _FieldLabel(label: 'Category', required: true),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: _inputDecoration(),
          hint: const Text('Select Category...'),
          items: provider.categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _category = v),
        ),
        const SizedBox(height: 20),
        const _FieldLabel(label: 'Severity', required: true),
        const SizedBox(height: 8),
        SeveritySelector(
          selected: provider.severity,
          onChanged: provider.setSeverity,
        ),
        const SizedBox(height: 20),
        _FieldLabel(label: 'Description', required: true),
        const SizedBox(height: 4),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: _inputDecoration(hint: 'Describe the incident...'),
        ),
        const SizedBox(height: 20),
        const _FieldLabel(label: 'Evidence (Photo/Video)'),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: PatientColors.card,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('Choose from Gallery'),
                      onTap: () {
                        Navigator.pop(ctx);
                        provider.pickEvidenceFromGallery();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Take a Photo'),
                      onTap: () {
                        Navigator.pop(ctx);
                        provider.pickEvidenceFromCamera();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            side: const BorderSide(color: PatientColors.border),
          ),
          icon: const Icon(Icons.upload_file, size: 18),
          label: Text(
            provider.evidenceFileName ?? 'Choose file',
            style: TextStyle(
              fontSize: 14,
              color: provider.evidenceFileName != null
                  ? PatientColors.primary
                  : PatientColors.textMuted,
            ),
          ),
        ),
        if (provider.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            provider.errorMessage!,
            style: const TextStyle(color: PatientColors.medicalRed, fontSize: 13),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: provider.isSubmitting
                    ? null
                    : (widget.onCancel ?? () => Navigator.of(context).maybePop()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: PatientColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => _handleSubmit(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PatientColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: PatientColors.primary.withValues(alpha: 0.2),
                ),
                icon: provider.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: PatientColors.textMain,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: const Text('Post Complaint'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: PatientColors.cardElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: PatientColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: PatientColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: PatientColors.primary),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${label.toUpperCase()}${required ? ' *' : ''}',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: PatientColors.textMuted,
      ),
    );
  }
}

class _FormInput extends StatelessWidget {
  const _FormInput({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: PatientColors.cardElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PatientColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PatientColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PatientColors.primary),
        ),
      ),
    );
  }
}
