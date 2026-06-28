import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';
import 'package:medvoice_flutter/core/theme/app_spacing.dart';
import 'package:medvoice_flutter/shared/widgets/medvoice_button.dart';
import 'package:medvoice_flutter/shared/widgets/medvoice_card.dart';

class OcrUploadScreen extends StatelessWidget {
  const OcrUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('OCR Document Scan'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.document_scanner_outlined,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Scan Medical Reports',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Upload prescription cards, diagnostic reports or discharge summaries to extract clinical context automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const MedVoiceCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'Drag & Drop or Tap to Upload',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              MedVoiceButton(
                label: 'Process Document',
                onPressed: () {
                  context.push(
                    '${RoutePaths.patientOcrProcessing}?result=Sample extracted medical report text',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
