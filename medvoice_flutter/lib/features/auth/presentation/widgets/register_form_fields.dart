import 'package:flutter/material.dart';
import 'package:medvoice_flutter/features/auth/domain/models/user_role.dart';
import 'package:medvoice_flutter/features/auth/presentation/widgets/auth_form_field.dart';

/// Role-specific registration fields mirroring Django registration forms.
class RegisterFormFields extends StatelessWidget {
  const RegisterFormFields({
    super.key,
    required this.role,
    required this.controllers,
    required this.onFilePick,
    this.fileNames = const {},
    this.govtIdType = 'aadhaar',
    this.hospitalType = 'govt',
    this.authorityType = 'district',
    this.jurisdictionLevel = 'national',
    required this.onGovtIdTypeChanged,
    required this.onHospitalTypeChanged,
    required this.onAuthorityTypeChanged,
    required this.onJurisdictionChanged,
  });

  final UserRole role;
  final Map<String, TextEditingController> controllers;
  final void Function(String fieldKey) onFilePick;
  final Map<String, String?> fileNames;
  final String govtIdType;
  final String hospitalType;
  final String authorityType;
  final String jurisdictionLevel;
  final ValueChanged<String?> onGovtIdTypeChanged;
  final ValueChanged<String?> onHospitalTypeChanged;
  final ValueChanged<String?> onAuthorityTypeChanged;
  final ValueChanged<String?> onJurisdictionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _twoColumn(
          AuthFormField(
            label: 'First name',
            controller: controllers['first_name'],
            hint: 'John',
            required: true,
          ),
          AuthFormField(
            label: 'Last name',
            controller: controllers['last_name'],
            hint: 'Doe',
            required: true,
          ),
        ),
        const SizedBox(height: 20),
        _twoColumn(
          AuthFormField(
            label: 'Email',
            controller: controllers['email'],
            hint: 'john@example.com',
            keyboardType: TextInputType.emailAddress,
            required: true,
          ),
          AuthFormField(
            label: 'Username',
            controller: controllers['username'],
            hint: 'johndoe123',
            required: true,
          ),
        ),
        const SizedBox(height: 20),
        _twoColumn(
          AuthFormField(
            label: 'Phone number',
            controller: controllers['phone_number'],
            hint: '+91-9999999999',
            keyboardType: TextInputType.phone,
          ),
          AuthFormField(
            label: 'Pincode',
            controller: controllers['pincode'],
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 20),
        AuthFormField(
          label: 'Address line 1',
          controller: controllers['address_line_1'],
          hint: 'Street Address',
        ),
        const SizedBox(height: 20),
        AuthFormField(
          label: 'Address line 2',
          controller: controllers['address_line_2'],
          hint: 'Apartment, Suite (Optional)',
        ),
        const SizedBox(height: 20),
        _twoColumn(
          AuthFormField(
            label: 'City',
            controller: controllers['city'],
          ),
          AuthFormField(
            label: 'State',
            controller: controllers['state'],
          ),
        ),
        const SizedBox(height: 20),
        if (role == UserRole.patient) ..._patientFields(),
        if (role == UserRole.hospital) ..._hospitalFields(),
        if (role == UserRole.authority) ..._authorityFields(),
        const SizedBox(height: 20),
        _twoColumn(
          AuthFormField(
            label: 'Password',
            controller: controllers['password'],
            hint: '••••••••',
            obscureText: true,
            required: true,
          ),
          AuthFormField(
            label: 'Confirm password',
            controller: controllers['confirm_password'],
            hint: '••••••••',
            obscureText: true,
            required: true,
          ),
        ),
      ],
    );
  }

  List<Widget> _patientFields() {
    return [
      const SizedBox(height: 20),
      _twoColumn(
        AuthDropdownField<String>(
          label: 'Government ID type',
          value: govtIdType,
          required: true,
          items: const [
            DropdownMenuItem(value: 'aadhaar', child: Text('Aadhaar')),
            DropdownMenuItem(value: 'voter_id', child: Text('Voter ID')),
            DropdownMenuItem(value: 'pan', child: Text('PAN')),
          ],
          onChanged: onGovtIdTypeChanged,
        ),
        AuthFormField(
          label: 'Government ID number',
          controller: controllers['govt_id_number'],
          required: true,
        ),
      ),
      const SizedBox(height: 20),
      AuthFileField(
        label: 'Government ID document',
        required: true,
        fileName: fileNames['govt_id_document'],
        onTap: () => onFilePick('govt_id_document'),
      ),
    ];
  }

  List<Widget> _hospitalFields() {
    return [
      const SizedBox(height: 20),
      AuthFormField(
        label: 'Hospital name',
        controller: controllers['hospital_name'],
        required: true,
      ),
      const SizedBox(height: 20),
      _twoColumn(
        AuthDropdownField<String>(
          label: 'Hospital type',
          value: hospitalType,
          required: true,
          items: const [
            DropdownMenuItem(value: 'govt', child: Text('Government')),
            DropdownMenuItem(value: 'private', child: Text('Private')),
          ],
          onChanged: onHospitalTypeChanged,
        ),
        AuthFormField(
          label: 'Registration number',
          controller: controllers['registration_number'],
          required: true,
        ),
      ),
      const SizedBox(height: 20),
      _twoColumn(
        AuthFormField(
          label: 'License number',
          controller: controllers['license_number'],
          required: true,
        ),
        AuthFileField(
          label: 'License document',
          required: true,
          fileName: fileNames['license_document'],
          onTap: () => onFilePick('license_document'),
        ),
      ),
      const SizedBox(height: 20),
      AuthFormField(
        label: 'Hospital address',
        controller: controllers['hospital_address'],
        maxLines: 3,
        required: true,
      ),
      const SizedBox(height: 20),
      _twoColumn(
        AuthFormField(
          label: 'District',
          controller: controllers['hospital_district'],
          required: true,
        ),
        AuthFormField(
          label: 'State',
          controller: controllers['hospital_state'],
          required: true,
        ),
      ),
      const SizedBox(height: 20),
      _twoColumn(
        AuthFormField(
          label: 'Pincode',
          controller: controllers['hospital_pincode'],
          keyboardType: TextInputType.number,
          required: true,
        ),
        AuthFormField(
          label: 'Contact number',
          controller: controllers['hospital_contact'],
          keyboardType: TextInputType.phone,
          required: true,
        ),
      ),
      const SizedBox(height: 20),
      AuthFormField(
        label: 'Hospital email',
        controller: controllers['hospital_email'],
        hint: 'hospital@example.com',
        keyboardType: TextInputType.emailAddress,
        required: true,
      ),
    ];
  }

  List<Widget> _authorityFields() {
    final level = jurisdictionLevel;
    return [
      const SizedBox(height: 20),
      AuthFormField(
        label: 'Authentication key',
        controller: controllers['authentication_key'],
        hint: 'Secret Key provided by SuperAdmin',
        obscureText: true,
        required: true,
      ),
      const SizedBox(height: 20),
      _twoColumn(
        AuthFormField(
          label: 'Authority name',
          controller: controllers['authority_name'],
          required: true,
        ),
        AuthDropdownField<String>(
          label: 'Authority type',
          value: authorityType,
          required: true,
          items: const [
            DropdownMenuItem(value: 'district', child: Text('District')),
            DropdownMenuItem(value: 'state', child: Text('State')),
            DropdownMenuItem(value: 'central', child: Text('Central')),
          ],
          onChanged: onAuthorityTypeChanged,
        ),
      ),
      const SizedBox(height: 20),
      AuthFormField(
        label: 'Department name',
        controller: controllers['department_name'],
        required: true,
      ),
      const SizedBox(height: 20),
      AuthDropdownField<String>(
        label: 'Jurisdiction level',
        value: level,
        required: true,
        items: const [
          DropdownMenuItem(
            value: 'national',
            child: Text('National Level'),
          ),
          DropdownMenuItem(value: 'state', child: Text('State Level')),
          DropdownMenuItem(
            value: 'district',
            child: Text('District Level'),
          ),
        ],
        onChanged: onJurisdictionChanged,
      ),
      if (level == 'state' || level == 'district') ...[
        const SizedBox(height: 20),
        AuthFormField(
          label: 'Jurisdiction state',
          controller: controllers['jurisdiction_state'],
          hint: 'State Name',
        ),
      ],
      if (level == 'district') ...[
        const SizedBox(height: 20),
        AuthFormField(
          label: 'Jurisdiction district',
          controller: controllers['jurisdiction_district'],
          hint: 'District Name',
        ),
      ],
      const SizedBox(height: 20),
      AuthFormField(
        label: 'Office address',
        controller: controllers['office_address'],
        maxLines: 3,
        required: true,
      ),
      const SizedBox(height: 20),
      _twoColumn(
        AuthFormField(
          label: 'Official email',
          controller: controllers['official_email'],
          keyboardType: TextInputType.emailAddress,
          required: true,
        ),
        AuthFormField(
          label: 'Official phone',
          controller: controllers['official_phone'],
          keyboardType: TextInputType.phone,
          required: true,
        ),
      ),
      const SizedBox(height: 20),
      _twoColumn(
        AuthFileField(
          label: 'Appointment letter',
          required: true,
          fileName: fileNames['appointment_letter'],
          onTap: () => onFilePick('appointment_letter'),
        ),
        AuthFileField(
          label: 'Authority ID document',
          required: true,
          fileName: fileNames['authority_id_document'],
          onTap: () => onFilePick('authority_id_document'),
        ),
      ),
    ];
  }

  Widget _twoColumn(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 20),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          children: [
            left,
            const SizedBox(height: 20),
            right,
          ],
        );
      },
    );
  }
}
