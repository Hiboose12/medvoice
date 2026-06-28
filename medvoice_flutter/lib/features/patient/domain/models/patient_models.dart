class PatientProfile {
  const PatientProfile({
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.totalComplaints,
    required this.resolvedComplaints,
    required this.pendingComplaints,
    this.phoneNumber,
    this.photoUrl,
    this.city,
    this.state,
  });

  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? photoUrl;
  final String? city;
  final String? state;
  final int totalComplaints;
  final int resolvedComplaints;
  final int pendingComplaints;

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? username : full;
  }

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    // Flat JSON is returned from the UserSerializer, so fallback to 'json'
    final user = json['user'] as Map<String, dynamic>? ?? json;
    final profile = json['profile'] as Map<String, dynamic>? ?? json;
    
    return PatientProfile(
      username: user['username']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      firstName: user['first_name']?.toString() ?? '',
      lastName: user['last_name']?.toString() ?? '',
      phoneNumber: profile['phone_number']?.toString() ?? user['phone_number']?.toString(),
      photoUrl: profile['photo']?.toString() ?? user['photo']?.toString(),
      city: user['city']?.toString(),
      state: user['state']?.toString(),
      totalComplaints: int.tryParse(json['total_complaints']?.toString() ?? '') ?? json['total_complaints'] as int? ?? 0,
      resolvedComplaints: int.tryParse(json['resolved_complaints']?.toString() ?? '') ?? json['resolved_complaints'] as int? ?? 0,
      pendingComplaints: int.tryParse(json['pending_complaints']?.toString() ?? '') ?? json['pending_complaints'] as int? ?? 0,
    );
  }
}

class PatientSettingsData {
  const PatientSettingsData({
    required this.emailNotifications,
    required this.complaintStatusUpdates,
    required this.newMessages,
    required this.authorityResponses,
    required this.showInFeed,
    required this.anonymousPosting,
    required this.showResolvedPublicly,
    required this.hideProfile,
    required this.allowHospitalContact,
    required this.allowEscalation,
    required this.theme,
    this.phoneNumber,
  });

  final bool emailNotifications;
  final bool complaintStatusUpdates;
  final bool newMessages;
  final bool authorityResponses;
  final bool showInFeed;
  final bool anonymousPosting;
  final bool showResolvedPublicly;
  final bool hideProfile;
  final bool allowHospitalContact;
  final bool allowEscalation;
  final String theme;
  final String? phoneNumber;

  Map<String, dynamic> toJson() => {
        'email_notifications': emailNotifications,
        'complaint_status_updates': complaintStatusUpdates,
        'new_messages': newMessages,
        'authority_responses': authorityResponses,
        'show_in_feed': showInFeed,
        'anonymous_posting': anonymousPosting,
        'show_resolved_publicly': showResolvedPublicly,
        'hide_profile': hideProfile,
        'allow_hospital_contact': allowHospitalContact,
        'allow_escalation': allowEscalation,
        'theme': theme,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      };

  PatientSettingsData copyWith({
    bool? emailNotifications,
    bool? complaintStatusUpdates,
    bool? newMessages,
    bool? authorityResponses,
    bool? showInFeed,
    bool? anonymousPosting,
    bool? showResolvedPublicly,
    bool? hideProfile,
    bool? allowHospitalContact,
    bool? allowEscalation,
    String? theme,
    String? phoneNumber,
  }) {
    return PatientSettingsData(
      emailNotifications: emailNotifications ?? this.emailNotifications,
      complaintStatusUpdates:
          complaintStatusUpdates ?? this.complaintStatusUpdates,
      newMessages: newMessages ?? this.newMessages,
      authorityResponses: authorityResponses ?? this.authorityResponses,
      showInFeed: showInFeed ?? this.showInFeed,
      anonymousPosting: anonymousPosting ?? this.anonymousPosting,
      showResolvedPublicly:
          showResolvedPublicly ?? this.showResolvedPublicly,
      hideProfile: hideProfile ?? this.hideProfile,
      allowHospitalContact: allowHospitalContact ?? this.allowHospitalContact,
      allowEscalation: allowEscalation ?? this.allowEscalation,
      theme: theme ?? this.theme,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  factory PatientSettingsData.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] as Map<String, dynamic>? ?? json;
    final profile = json['profile'] as Map<String, dynamic>? ?? const {};
    return PatientSettingsData(
      emailNotifications: settings['email_notifications'] ?? true,
      complaintStatusUpdates: settings['complaint_status_updates'] ?? true,
      newMessages: settings['new_messages'] ?? true,
      authorityResponses: settings['authority_responses'] ?? false,
      showInFeed: settings['show_in_feed'] ?? true,
      anonymousPosting: settings['anonymous_posting'] ?? true,
      showResolvedPublicly: settings['show_resolved_publicly'] ?? false,
      hideProfile: settings['hide_profile'] ?? false,
      allowHospitalContact: settings['allow_hospital_contact'] ?? true,
      allowEscalation: settings['allow_escalation'] ?? true,
      theme: settings['theme'] ?? 'light',
      phoneNumber: settings['phone_number'] ?? profile['phone_number'],
    );
  }
}

class PatientHospitalOption {
  const PatientHospitalOption({required this.id, required this.name});
  final int id;
  final String name;

  factory PatientHospitalOption.fromJson(Map<String, dynamic> json) {
    return PatientHospitalOption(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

class PatientCategoryOption {
  const PatientCategoryOption({required this.name, this.description});
  final String name;
  final String? description;

  factory PatientCategoryOption.fromJson(Map<String, dynamic> json) {
    return PatientCategoryOption(
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}

class PatientComplaintOptions {
  const PatientComplaintOptions({
    required this.hospitals,
    required this.categories,
  });

  final List<PatientHospitalOption> hospitals;
  final List<PatientCategoryOption> categories;

  factory PatientComplaintOptions.fromJson(Map<String, dynamic> json) {
    return PatientComplaintOptions(
      hospitals: (json['hospitals'] as List<dynamic>? ?? [])
          .map((e) => PatientHospitalOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => PatientCategoryOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.name,
    required this.role,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    this.complaintTitle,
  });

  final int id;
  final String name;
  final String role;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final String? complaintTitle;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final other = json['other_user'] as Map<String, dynamic>? ?? const {};
    final complaint = json['complaint'] as Map<String, dynamic>?;
    return ChatConversation(
      id: json['id'] ?? 0,
      name: other['name'] ?? 'Conversation',
      role: other['role'] ?? '',
      lastMessage: json['last_message'] ?? '',
      lastMessageAt: DateTime.tryParse(json['last_message_at'] ?? '') ??
          DateTime.now(),
      unreadCount: json['unread_count'] ?? 0,
      complaintTitle: complaint?['title'],
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.createdAtLabel,
    required this.isMe,
    required this.isRead,
    this.attachmentUrl,
  });

  final int id;
  final String sender;
  final String content;
  final String createdAtLabel;
  final bool isMe;
  final bool isRead;
  final String? attachmentUrl;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      sender: json['sender'] ?? '',
      content: json['content'] ?? '',
      createdAtLabel: json['created_at'] ?? '',
      isMe: json['is_me'] ?? false,
      isRead: json['is_read'] ?? false,
      attachmentUrl: json['attachment_url'],
    );
  }
}
