import 'package:flutter/material.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/patient/presentation/widgets/create_post_form.dart';

class CreatePostModal extends StatelessWidget {
  const CreatePostModal({
    super.key,
    required this.onSubmit,
  });

  final Future<void> Function(CreatePostFormData data) onSubmit;

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(CreatePostFormData data) onSubmit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePostModal(onSubmit: onSubmit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.only(top: 48),
        decoration: const BoxDecoration(
          color: PatientColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: CreatePostForm(
              onSubmit: (data) async {
                await onSubmit(data);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }
}
