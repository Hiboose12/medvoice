file_path = r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\operations\presentation\screens\operational_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

start_str = '  Widget _buildProfileContent(HospitalProvider provider) {'
end_str = '}'

start_idx = content.rfind(start_str)

if start_idx != -1:
    end_idx = content.rfind('}')
    
    new_content = """  Widget _buildProfileContent(HospitalProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: provider.retryProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final profile = provider.profile;
    if (profile == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No profile data available.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final isApproved = (profile.status ?? '').toLowerCase() == 'approved' || (profile.status ?? '').toLowerCase() == 'verified';
    final initial = profile.hospitalName.isNotEmpty ? profile.hospitalName.substring(0, 1).toUpperCase() : 'H';

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hospital Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    SizedBox(height: 4),
                    Text('Manage your hospital information and verification status.', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => context.go(RoutePaths.hospitalSettings),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Edit Profile'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Hero Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1e3a8a), Color(0xFF0f172a)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 500;
                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                            ),
                            child: Center(
                              child: Text(initial, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          _buildBadge(isApproved),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildHeroDetails(profile),
                    ],
                  );
                }
                return Row(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                      ),
                      child: Center(
                        child: Text(initial, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildHeroDetails(profile),
                    ),
                    const SizedBox(width: 24),
                    _buildBadge(isApproved),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              
              final card1 = _buildProfileCard(
                title: 'Hospital Information',
                icon: Icons.domain,
                onEdit: () => context.go(RoutePaths.hospitalSettings),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildField('Hospital Name', profile.hospitalName.isNotEmpty ? profile.hospitalName : 'Not set')),
                        Expanded(child: _buildField('Type', profile.hospitalType.isNotEmpty ? profile.hospitalType : 'Not set')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildField('Registration No', profile.registrationNumber.isNotEmpty ? profile.registrationNumber : 'Not set')),
                        Expanded(child: _buildField('License No', profile.licenseNumber.isNotEmpty ? profile.licenseNumber : 'Not set')),
                      ],
                    ),
                  ],
                ),
              );

              final card2 = _buildProfileCard(
                title: 'Address & Contact',
                icon: Icons.location_on_outlined,
                onEdit: () => context.go(RoutePaths.hospitalSettings),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField('Address', profile.address.isNotEmpty ? profile.address : 'Not set'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildField('District', profile.district.isNotEmpty ? profile.district : 'Not set')),
                        Expanded(child: _buildField('State', profile.state.isNotEmpty ? profile.state : 'Not set')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildField('Pincode', profile.pincode.isNotEmpty ? profile.pincode : 'Not set')),
                        Expanded(child: _buildField('Phone', profile.contactNumber.isNotEmpty ? profile.contactNumber : 'Not set')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField('Email', profile.email.isNotEmpty ? profile.email : 'Not set'),
                  ],
                ),
              );

              final card3 = _buildProfileCard(
                title: 'Security',
                icon: Icons.security,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildField('Password', '••••••••••••'),
                    OutlinedButton(
                      onPressed: () => context.go(RoutePaths.hospitalSettings),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF93C5FD),
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                      child: const Text('Change Password'),
                    ),
                  ],
                ),
              );

              final card4 = _buildProfileCard(
                title: 'Quick Actions',
                icon: Icons.flash_on,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go(RoutePaths.hospitalComplaints),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDBEAFE),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Text('View Complaints', textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    card1,
                    const SizedBox(height: 24),
                    card2,
                    const SizedBox(height: 24),
                    card3,
                    const SizedBox(height: 24),
                    card4,
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: card1),
                      const SizedBox(width: 24),
                      Expanded(child: card2),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: card3),
                      const SizedBox(width: 24),
                      Expanded(child: card4),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(bool isApproved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isApproved ? Colors.greenAccent.withOpacity(0.3) : Colors.amberAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isApproved ? Icons.verified : Icons.hourglass_empty, size: 16, color: isApproved ? Colors.greenAccent : Colors.amberAccent),
          const SizedBox(width: 4),
          Text(isApproved ? 'Verified' : 'Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isApproved ? Colors.greenAccent : Colors.amberAccent)),
        ],
      ),
    );
  }

  Widget _buildHeroDetails(dynamic profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(profile.hospitalName.isNotEmpty ? profile.hospitalName : 'Unknown Hospital', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text('License: ${profile.licenseNumber.isNotEmpty ? profile.licenseNumber : "N/A"}', style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 14)),
        Text('Registration No: ${profile.registrationNumber.isNotEmpty ? profile.registrationNumber : "N/A"}', style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 14)),
        Text(profile.address.isNotEmpty ? profile.address : "Address not set", style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mail_outline, size: 16, color: Color(0xFFBFDBFE)),
            const SizedBox(width: 4),
            Text(profile.email.isNotEmpty ? profile.email : 'N/A', style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 14)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_outlined, size: 16, color: Color(0xFFBFDBFE)),
            const SizedBox(width: 4),
            Text(profile.contactNumber.isNotEmpty ? profile.contactNumber : 'N/A', style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCard({required String title, required IconData icon, VoidCallback? onEdit, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1e3a8a), Color(0xFF0f172a)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF60A5FA), size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF93C5FD),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 24),
                  ),
                  child: const Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFBFDBFE), letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
      ],
    );
  }
"""
    final_content = content[:start_idx] + new_content + "\n}\n"
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(final_content)
    print('Patched successfully!')
else:
    print('Failed to find start bounds')
