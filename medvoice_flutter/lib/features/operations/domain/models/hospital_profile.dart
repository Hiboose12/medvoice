class HospitalProfile {
  final int id;
  final String hospitalName;
  final String hospitalType;
  final String registrationNumber;
  final String licenseNumber;
  final String address;
  final String district;
  final String state;
  final String pincode;
  final String contactNumber;
  final String email;
  final String status;

  HospitalProfile({
    required this.id,
    required this.hospitalName,
    required this.hospitalType,
    required this.registrationNumber,
    required this.licenseNumber,
    required this.address,
    required this.district,
    required this.state,
    required this.pincode,
    required this.contactNumber,
    required this.email,
    required this.status,
  });

  factory HospitalProfile.fromJson(Map<String, dynamic> json) {
    return HospitalProfile(
      id: int.tryParse(json['id']?.toString() ?? '') ?? json['id'] as int? ?? 0,
      hospitalName: json['hospital_name'] as String? ?? '',
      hospitalType: json['hospital_type'] as String? ?? '',
      registrationNumber: json['registration_number'] as String? ?? '',
      licenseNumber: json['license_number'] as String? ?? '',
      address: json['address'] as String? ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      contactNumber: json['contact_number'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hospital_name': hospitalName,
      'hospital_type': hospitalType,
      'registration_number': registrationNumber,
      'license_number': licenseNumber,
      'address': address,
      'district': district,
      'state': state,
      'pincode': pincode,
      'contact_number': contactNumber,
      'email': email,
      'status': status,
    };
  }
}
