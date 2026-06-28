import 'package:json_annotation/json_annotation.dart';

part 'hospital_models.g.dart';

class HospitalDashboardStats {
  final int totalComplaints;
  final int openComplaints;
  final int respondedComplaints;
  final int resolvedComplaints;

  HospitalDashboardStats({
    required this.totalComplaints,
    required this.openComplaints,
    required this.respondedComplaints,
    required this.resolvedComplaints,
  });

  factory HospitalDashboardStats.fromJson(Map<String, dynamic> json) {
    return HospitalDashboardStats(
      totalComplaints: int.tryParse(json['total_complaints']?.toString() ?? '') ?? json['total_complaints'] as int? ?? 0,
      openComplaints: int.tryParse(json['open_complaints']?.toString() ?? '') ?? json['open_complaints'] as int? ?? 0,
      respondedComplaints: int.tryParse(json['responded_complaints']?.toString() ?? '') ?? json['responded_complaints'] as int? ?? 0,
      resolvedComplaints: int.tryParse(json['resolved_complaints']?.toString() ?? '') ?? json['resolved_complaints'] as int? ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'total_complaints': totalComplaints,
    'open_complaints': openComplaints,
    'responded_complaints': respondedComplaints,
    'resolved_complaints': resolvedComplaints,
  };
}

@JsonSerializable()
class HospitalComplaint {
  final int id;
  final String title;
  final String description;
  final String status;
  final String severity;
  final String category;
  final String? evidenceUrl;
  final String patientName;
  final String hospitalName;
  final DateTime createdAt;
  final List<HospitalResponse> responses;

  HospitalComplaint({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.severity,
    required this.category,
    this.evidenceUrl,
    required this.patientName,
    required this.hospitalName,
    required this.createdAt,
    this.responses = const [],
  });

  factory HospitalComplaint.fromJson(Map<String, dynamic> json) {
    return HospitalComplaint(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'new',
      severity: json['severity'] as String? ?? 'medium',
      category: json['category'] as String? ?? 'General',
      evidenceUrl: json['evidence'] as String?,
      patientName: json['user']?['username'] as String? ?? 'Unknown',
      hospitalName: json['hospital_name'] as String? ?? json['unregistered_hospital_name'] as String? ?? 'Unknown',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      responses: (json['hospital_responses'] as List<dynamic>? ?? [])
          .map((r) => HospitalResponse.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => _$HospitalComplaintToJson(this);
}

@JsonSerializable()
class HospitalPost {
  final int id;
  @JsonKey(name: 'author_name')
  final String authorName;
  final String content;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  HospitalPost({
    required this.id,
    required this.authorName,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });

  factory HospitalPost.fromJson(Map<String, dynamic> json) => _$HospitalPostFromJson(json);
  Map<String, dynamic> toJson() => _$HospitalPostToJson(this);
}

@JsonSerializable()
class HospitalResponse {
  final int id;
  final String message;
  @JsonKey(name: 'is_private')
  final bool isPrivate;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  HospitalResponse({
    required this.id,
    required this.message,
    required this.isPrivate,
    required this.createdAt,
  });

  factory HospitalResponse.fromJson(Map<String, dynamic> json) => _$HospitalResponseFromJson(json);
  Map<String, dynamic> toJson() => _$HospitalResponseToJson(this);
}
