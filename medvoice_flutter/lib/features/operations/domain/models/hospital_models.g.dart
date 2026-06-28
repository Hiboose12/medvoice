// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hospital_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HospitalComplaint _$HospitalComplaintFromJson(Map<String, dynamic> json) =>
    HospitalComplaint(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      severity: json['severity'] as String,
      category: json['category'] as String,
      evidenceUrl: json['evidenceUrl'] as String?,
      patientName: json['patientName'] as String,
      hospitalName: json['hospitalName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      responses:
          (json['responses'] as List<dynamic>?)
              ?.map((e) => HospitalResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$HospitalComplaintToJson(HospitalComplaint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'severity': instance.severity,
      'category': instance.category,
      'evidenceUrl': instance.evidenceUrl,
      'patientName': instance.patientName,
      'hospitalName': instance.hospitalName,
      'createdAt': instance.createdAt.toIso8601String(),
      'responses': instance.responses,
    };

HospitalPost _$HospitalPostFromJson(Map<String, dynamic> json) => HospitalPost(
  id: (json['id'] as num).toInt(),
  authorName: json['author_name'] as String,
  content: json['content'] as String,
  imageUrl: json['image_url'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$HospitalPostToJson(HospitalPost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author_name': instance.authorName,
      'content': instance.content,
      'image_url': instance.imageUrl,
      'created_at': instance.createdAt.toIso8601String(),
    };

HospitalResponse _$HospitalResponseFromJson(Map<String, dynamic> json) =>
    HospitalResponse(
      id: (json['id'] as num).toInt(),
      message: json['message'] as String,
      isPrivate: json['is_private'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$HospitalResponseToJson(HospitalResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': instance.message,
      'is_private': instance.isPrivate,
      'created_at': instance.createdAt.toIso8601String(),
    };
