import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';
import 'package:medvoice_flutter/core/theme/app_typography.dart';
import 'package:medvoice_flutter/features/auth/domain/models/user_role.dart';
import 'package:medvoice_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:medvoice_flutter/features/auth/presentation/widgets/auth_brand_panel.dart';
import 'package:medvoice_flutter/features/auth/presentation/widgets/auth_form_field.dart';
import 'package:medvoice_flutter/features/auth/presentation/widgets/medvoice_logo.dart';
import 'package:medvoice_flutter/features/auth/presentation/widgets/register_form_fields.dart';
import 'package:medvoice_flutter/features/auth/presentation/widgets/role_tab_selector.dart';
import 'package:provider/provider.dart';

/// Mirrors `templates/accounts/register.html`.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  UserRole _selectedRole = UserRole.patient;
  String _govtIdType = 'aadhaar';
  String _hospitalType = 'govt';
  String _authorityType = 'district';
  String _jurisdictionLevel = 'national';
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _fileNames = {};
  final Map<String, String> _filePaths = {};
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    for (final key in _allFieldKeys) {
      _controllers[key] = TextEditingController();
    }
  }

  static const _allFieldKeys = [
    'first_name', 'last_name', 'email', 'username', 'phone_number',
    'address_line_1', 'address_line_2', 'city', 'state', 'pincode',
    'password', 'confirm_password',
    'govt_id_type', 'govt_id_number',
    'hospital_name', 'hospital_type', 'registration_number',
    'license_number', 'hospital_address', 'hospital_district',
    'hospital_state', 'hospital_pincode', 'hospital_contact', 'hospital_email',
    'authentication_key', 'authority_name', 'authority_type',
    'department_name', 'jurisdiction_state', 'jurisdiction_district',
    'office_address', 'official_email', 'official_phone',
  ];

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> _collectFormData() {
    final data = _controllers.map(
      (key, controller) => MapEntry(key, controller.text.trim()),
    );
    data['govt_id_type'] = _govtIdType;
    data['hospital_type'] = _hospitalType;
    data['authority_type'] = _authorityType;
    data['jurisdiction_level'] = _jurisdictionLevel;
    return data;
  }

  Future<void> _pickFile(String fieldKey) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _fileNames[fieldKey] = file.name;
        if (file.path != null) {
          _filePaths[fieldKey] = file.path!;
        }
      });
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    setState(() => _showSuccess = false);

    final success = await auth.register(
      role: _selectedRole,
      formData: _collectFormData(),
      filePaths: _filePaths,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _showSuccess = true);
      await Future<void>.delayed(const Duration(seconds: 1));
      if (mounted) context.go(RoutePaths.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: Row(
        children: [
          if (isWide)
            const Expanded(
              flex: 5,
              child: AuthBrandPanel(
                icon: Icons.person_add_alt_1,
                title: 'Join the\nHealthcare Revolution',
                subtitle:
                    'Create your account to connect with verified hospitals '
                    'and authorities. Raise your voice, track your grievances, '
                    'and drive change.',
                showStats: true,
                opacity: 0.6,
              ),
            ),
          Expanded(
            flex: 7,
            child: ColoredBox(
              color: AppColors.surface,
              child: Column(
                children: [
                  if (!isWide)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.divider)),
                      ),
                      child: Row(
                        children: [
                          const MedVoiceLogo(compact: true),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.go(RoutePaths.login),
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 64 : 24,
                        vertical: isWide ? 48 : 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 672),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Create an account',
                                style: GoogleFonts.manrope(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Please fill in your details to get started.',
                                style: AppTypography.textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 32),
                              RoleTabSelector(
                                selectedRole: _selectedRole,
                                onRoleChanged: (role) =>
                                    setState(() => _selectedRole = role),
                              ),
                              const SizedBox(height: 32),
                              if (_showSuccess)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: AuthMessageBanner(
                                    message:
                                        'Account created successfully! Redirecting to login...',
                                    isError: false,
                                  ),
                                ),
                              if (auth.errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: AuthMessageBanner(
                                    message: auth.errorMessage!,
                                  ),
                                ),
                              RegisterFormFields(
                                role: _selectedRole,
                                controllers: _controllers,
                                onFilePick: _pickFile,
                                fileNames: _fileNames,
                                govtIdType: _govtIdType,
                                hospitalType: _hospitalType,
                                authorityType: _authorityType,
                                jurisdictionLevel: _jurisdictionLevel,
                                onGovtIdTypeChanged: (v) =>
                                    setState(() => _govtIdType = v ?? 'aadhaar'),
                                onHospitalTypeChanged: (v) =>
                                    setState(() => _hospitalType = v ?? 'govt'),
                                onAuthorityTypeChanged: (v) => setState(
                                  () => _authorityType = v ?? 'district',
                                ),
                                onJurisdictionChanged: (v) => setState(
                                  () => _jurisdictionLevel = v ?? 'national',
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: auth.isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.authBlue600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    shadowColor:
                                        AppColors.authBlue600.withValues(alpha: 0.2),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Create Account',
                                              style: AppTypography
                                                  .textTheme.labelLarge
                                                  ?.copyWith(fontSize: 14),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account?',
                                      style: AppTypography.textTheme.bodySmall
                                          ?.copyWith(fontSize: 14),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          context.go(RoutePaths.login),
                                      child: const Text('Log in'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
