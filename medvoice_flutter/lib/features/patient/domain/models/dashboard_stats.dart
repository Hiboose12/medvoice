import 'package:medvoice_flutter/features/patient/domain/models/complaint_post.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalComplaints,
    required this.resolvedComplaints,
    required this.pendingComplaints,
    required this.recentActivity,
    required this.communityBillingCount,
    required this.communityResolvedToday,
  });

  final int totalComplaints;
  final int resolvedComplaints;
  final int pendingComplaints;
  final List<ComplaintPost> recentActivity;
  final int communityBillingCount;
  final int communityResolvedToday;
}

class PatientNotification {
  const PatientNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.link,
    this.isRead = false,
  });

  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? link;
  final bool isRead;

  factory PatientNotification.fromJson(Map<String, dynamic> json) {
    return PatientNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      link: json['link'],
      isRead: json['is_read'] ?? false,
    );
  }
}

class MockHospital {
  const MockHospital({required this.id, required this.name});

  final int id;
  final String name;
}
