import re

def patch_review_details(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # We need to replace the section starting with 'final user = data['user'] ?? {};'
    # up to the end of the `_DetailSection` for authority/hospital.
    
    # Let's locate the build method of _ReviewDetailsPageState
    search_str = "final user = data['user'] ?? {};"
    if search_str not in content:
        print("Could not find start point.")
        return
        
    old_code_start = content.find(search_str)
    
    old_code_end_str = "], // End of Hospital/Authority Details"
    # Actually, the old code ends at:
    # ] : [
    #   _DetailField('HOSPITAL NAME', user['first_name'] ?? '-'),
    #   _DetailField('REGISTRATION NUMBER', verification['registration_number'] ?? '-'),
    # ],
    # ),
    
    search_end_str = "], // end of fields"
    # Let's just find the `_DetailSection` for Authority/Hospital.
    # We will replace from `final user = data['user'] ?? {};` to just before `const SizedBox(width: 24),` 
    # which is after the expanded flex 2 column.
    
    end_point = content.find("Expanded(\n                      flex: 1,\n                      child: Column(", old_code_start)
    if end_point == -1:
        # Fallback search
        end_point = content.find("const SizedBox(width: 24),\n                    Expanded(\n                      flex: 1,\n                      child: Column(", old_code_start)
        
    if end_point == -1:
        print("Could not find end point.")
        return
        
    old_code = content[old_code_start:end_point]
    
    new_code = """final user = data['user'] ?? {};
          final verification = data['verification'] ?? {};
          final authorityDetails = data['authority_details'] ?? {};
          final hospitalDetails = data['hospital_details'] ?? {};
          
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
                              _DetailField('ROLE', user['role_display'] ?? widget.entityType.toUpperCase()),
                              _DetailField('EMAIL', user['email'] ?? ''),
                              _DetailField('PHONE', user['phone_number'] ?? '-'),
                              _DetailField('ADDRESS', address.isEmpty ? '-' : address, isFullWidth: true),
                              _DetailField('CITY', user['city'] ?? '-'),
                              _DetailField('STATE', user['state'] ?? '-'),
                              _DetailField('PINCODE', user['pincode'] ?? '-'),
                              _DetailField('REGISTERED', user['date_joined'] ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _DetailSection(
                            title: widget.entityType == 'authority' ? 'Authority Details' : 'Hospital Details',
                            fields: widget.entityType == 'authority' ? [
                              _DetailField('AUTHORITY NAME', authorityDetails['authority_name'] ?? '-'),
                              _DetailField('AUTHORITY TYPE', authorityDetails['authority_type_display'] ?? '-'),
                              _DetailField('DEPARTMENT', authorityDetails['department_name'] ?? '-'),
                              _DetailField('JURISDICTION LEVEL', authorityDetails['jurisdiction_level'] ?? '-'),
                              _DetailField('JURISDICTION STATE', authorityDetails['jurisdiction_state'] ?? '-'),
                              _DetailField('JURISDICTION DISTRICT', authorityDetails['jurisdiction_district'] ?? '-'),
                              _DetailField('OFFICE ADDRESS', authorityDetails['office_address'] ?? '-', isFullWidth: true),
                            ] : [
                              _DetailField('HOSPITAL NAME', hospitalDetails['hospital_name'] ?? '-'),
                              _DetailField('HOSPITAL TYPE', hospitalDetails['hospital_type_display'] ?? '-'),
                              _DetailField('REGISTRATION NUMBER', hospitalDetails['registration_number'] ?? '-'),
                              _DetailField('LICENSE NUMBER', hospitalDetails['license_number'] ?? '-'),
                              _DetailField('HOSPITAL ADDRESS', hospitalDetails['address'] ?? '-', isFullWidth: true),
                              _DetailField('DISTRICT', hospitalDetails['district'] ?? '-'),
                              _DetailField('STATE', hospitalDetails['state'] ?? '-'),
                              _DetailField('PINCODE', hospitalDetails['pincode'] ?? '-'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    """
                    
    content = content.replace(old_code, new_code)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        print("Updated details fetching.")

patch_review_details(r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\operations\presentation\screens\operational_screen.dart')
