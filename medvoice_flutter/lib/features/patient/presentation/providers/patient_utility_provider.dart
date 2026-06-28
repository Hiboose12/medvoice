import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:medvoice_flutter/features/patient/data/patient_repository.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_post.dart';
import 'package:medvoice_flutter/features/patient/domain/models/dashboard_stats.dart';
import 'package:medvoice_flutter/features/patient/domain/models/patient_models.dart';

class PatientUtilityProvider extends ChangeNotifier {
  PatientUtilityProvider({PatientRepository? repository})
      : _repository = repository ?? PatientRepository();

  final PatientRepository _repository;

  PatientProfile? _profile;
  PatientSettingsData? _settings;
  List<PatientNotification> _notifications = [];
  List<ChatConversation> _conversations = [];
  List<ComplaintPost> _myComplaints = [];

  bool _isProfileLoading = false;
  bool _isSettingsLoading = false;
  bool _isNotificationsLoading = false;
  bool _isChatLoading = false;
  bool _isComplaintsLoading = false;

  String? _errorMessage;

  // Getters
  PatientProfile? get profile => _profile;
  PatientSettingsData? get settings => _settings;
  List<PatientNotification> get notifications => _notifications;
  List<ChatConversation> get conversations => _conversations;
  List<ComplaintPost> get myComplaints => _myComplaints;

  bool get isProfileLoading => _isProfileLoading;
  bool get isSettingsLoading => _isSettingsLoading;
  bool get isNotificationsLoading => _isNotificationsLoading;
  bool get isChatLoading => _isChatLoading;
  bool get isComplaintsLoading => _isComplaintsLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _isProfileLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final p = await _repository.getPatientProfile();
      try {
        final stats = await _repository.getDashboardStats();
        _profile = PatientProfile(
          username: p.username,
          email: p.email,
          firstName: p.firstName,
          lastName: p.lastName,
          phoneNumber: p.phoneNumber,
          photoUrl: p.photoUrl,
          city: p.city,
          state: p.state,
          totalComplaints: stats.totalComplaints,
          resolvedComplaints: stats.resolvedComplaints,
          pendingComplaints: stats.pendingComplaints,
        );
      } catch (_) {
        // Fallback if dashboard stats fail
        _profile = p;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    _isSettingsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _repository.getPatientSettings();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSettingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNotifications() async {
    _isNotificationsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _repository.getNotifications();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isNotificationsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadConversations() async {
    _isChatLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _conversations = await _repository.getPatientConversations();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isChatLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadComplaints({String? status, String? search}) async {
    _isComplaintsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myComplaints = await _repository.getMyComplaints(status: status, search: search);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isComplaintsLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings(PatientSettingsData updated) async {
    _isSettingsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updatePatientSettings(updated);
      _settings = updated;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSettingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationRead(int id) async {
    try {
      await _repository.markNotificationRead(id);
      await loadNotifications();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> replyToNotification(int id, String message) async {
    try {
      await _repository.replyToNotification(id, message);
      await loadNotifications();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<ChatConversation?> startComplaintChat(int complaintId) async {
    try {
      final chat = await _repository.startComplaintChat(complaintId);
      await loadConversations();
      return chat;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadProfile(),
      loadSettings(),
      loadNotifications(),
      loadConversations(),
      loadComplaints(),
    ]);
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      await loadProfile();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _repository.changePassword(oldPassword, newPassword);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> logoutAllDevices() async {
    try {
      await _repository.logoutAllDevices();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleLike(int complaintId) async {
    try {
      await _repository.toggleLike(complaintId);
      // We could update the local state here directly, but a refresh ensures consistency
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> addComment(int complaintId, String content) async {
    try {
      await _repository.addComment(complaintId, content);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> uploadComplaint(FormData formData) async {
    try {
      await _repository.uploadComplaint(formData);
      await loadComplaints(); // Refresh complaints after upload
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> retry() => refreshAll();
}
