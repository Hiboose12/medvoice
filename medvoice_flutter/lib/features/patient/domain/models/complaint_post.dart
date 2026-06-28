import 'package:medvoice_flutter/features/patient/domain/models/complaint_status.dart';

class ComplaintComment {
  const ComplaintComment({
    required this.id,
    required this.username,
    required this.content,
    required this.createdAt,
    this.isOwner = false,
  });

  final int id;
  final String username;
  final String content;
  final DateTime createdAt;
  final bool isOwner;

  factory ComplaintComment.fromJson(Map<String, dynamic> json) {
    return ComplaintComment(
      id: json['id'] ?? 0,
      username: json['user_name'] ?? 'Anonymous',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isOwner: json['is_owner'] ?? false,
    );
  }
}

class HospitalResponse {
  const HospitalResponse({
    required this.hospitalName,
    required this.message,
    required this.createdAt,
    this.isPrivate = false,
  });

  final String hospitalName;
  final String message;
  final DateTime createdAt;
  final bool isPrivate;

  factory HospitalResponse.fromJson(Map<String, dynamic> json) {
    return HospitalResponse(
      hospitalName: json['hospital_name'] ?? 'Hospital',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isPrivate: json['is_private'] ?? false,
    );
  }
}

class ComplaintPost {
  ComplaintPost({
    required this.id,
    required this.title,
    required this.description,
    required this.hospitalName,
    required this.category,
    required this.severity,
    required this.status,
    required this.createdAt,
    required this.authorName,
    required this.authorInitial,
    this.authorId,
    this.isAnonymous = false,
    this.isOwner = false,
    this.isLiked = false,
    this.likes = 0,
    this.comments = const [],
    this.hospitalResponses = const [],
    this.evidenceUrl,
    this.hospitalId,
  });

  final int id;
  final String title;
  final String description;
  final String hospitalName;
  final String category;
  final ComplaintSeverity severity;
  final ComplaintStatus status;
  final DateTime createdAt;
  final String authorName;
  final String authorInitial;
  final int? authorId;
  final bool isAnonymous;
  final bool isOwner;
  final bool isLiked;
  final int likes;
  final List<ComplaintComment> comments;
  final List<HospitalResponse> hospitalResponses;
  final String? evidenceUrl;
  final int? hospitalId;

  ComplaintPost copyWith({
    bool? isLiked,
    int? likes,
    List<ComplaintComment>? comments,
    List<HospitalResponse>? hospitalResponses,
    ComplaintStatus? status,
  }) {
    return ComplaintPost(
      id: id,
      title: title,
      description: description,
      hospitalName: hospitalName,
      category: category,
      severity: severity,
      status: status ?? this.status,
      createdAt: createdAt,
      authorName: authorName,
      authorInitial: authorInitial,
      authorId: authorId,
      isAnonymous: isAnonymous,
      isOwner: isOwner,
      isLiked: isLiked ?? this.isLiked,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      hospitalResponses: hospitalResponses ?? this.hospitalResponses,
      evidenceUrl: evidenceUrl,
      hospitalId: hospitalId,
    );
  }

  factory ComplaintPost.fromJson(Map<String, dynamic> json) {
    final List<ComplaintComment> parsedComments = (json['comments'] as List<dynamic>? ?? [])
        .map((c) => ComplaintComment.fromJson(c as Map<String, dynamic>))
        .toList();
    final List<HospitalResponse> parsedResponses = (json['hospital_responses'] as List<dynamic>? ?? [])
        .map((r) => HospitalResponse.fromJson(r as Map<String, dynamic>))
        .toList();

    return ComplaintPost(
      id: int.tryParse(json['id']?.toString() ?? '') ?? json['id'] as int? ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      hospitalName: json['hospital_name'] ??
          json['unregistered_hospital_name'] ??
          'Unknown Hospital',
      category: json['category'] ?? 'general',
      severity: ComplaintSeverity.values.firstWhere(
        (e) => e.value == (json['severity'] ?? 'medium'),
        orElse: () => ComplaintSeverity.medium,
      ),
      status: ComplaintStatus.fromValue(json['status'] ?? 'new'),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      authorName: json['user']?['full_name'] ??
          json['user']?['get_full_name'] ??
          json['user']?['username'] ??
          'Anonymous',
      authorInitial: (json['user']?['username'] ?? 'A')[0].toUpperCase(),
      authorId: json['user']?['id'] as int?,
      isAnonymous: json['user']?['is_anonymous_public'] ?? false,
      isOwner: json['is_owner'] ?? false,
      isLiked: json['is_liked'] ?? false,
      likes: int.tryParse(json['likes_count']?.toString() ?? '') ?? int.tryParse(json['likes']?.toString() ?? '') ?? json['likes_count'] as int? ?? json['likes'] as int? ?? 0,
      comments: parsedComments,
      hospitalResponses: parsedResponses,
      evidenceUrl: json['evidence'] ?? json['evidence_url'],
      hospitalId: json['hospital'] as int?,
    );
  }
}

class CreatePostInput {
  const CreatePostInput({
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    this.hospitalId,
    this.unregisteredHospitalName,
    this.evidenceFileName,
  });

  final String title;
  final String description;
  final String category;
  final ComplaintSeverity severity;
  final int? hospitalId;
  final String? unregisteredHospitalName;
  final String? evidenceFileName;
}

