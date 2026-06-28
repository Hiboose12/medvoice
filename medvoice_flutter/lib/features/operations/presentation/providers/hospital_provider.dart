import 'package:flutter/foundation.dart';

import 'package:medvoice_flutter/features/operations/domain/models/hospital_models.dart';
import 'package:medvoice_flutter/features/operations/domain/models/hospital_profile.dart';
import 'package:medvoice_flutter/features/operations/data/hospital_repository.dart';

enum ProviderState { idle, loading, error, loaded }

class HospitalProvider extends ChangeNotifier {
  HospitalProvider({HospitalRepository? repository}) : _repo = repository ?? HospitalRepository();

  final HospitalRepository _repo;

  ProviderState _state = ProviderState.idle;
  ProviderState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Dashboard stats
  HospitalDashboardStats? _dashboard;
  HospitalDashboardStats? get dashboard => _dashboard;

  // Complaints list (queue)
  List<HospitalComplaint> _complaints = [];
  List<HospitalComplaint> get complaints => _complaints;

  // Hospital Feed posts
  List<HospitalPost> _feed = [];
  List<HospitalPost> get feed => _feed;

  // Hospital profile
  HospitalProfile? _profile;
  HospitalProfile? get profile => _profile;

  // Notifications
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  // Conversations
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> get conversations => _conversations;

  // Loading flags for specific sections
  bool get isLoading => _state == ProviderState.loading;
  bool get isLoadingNotifications => _state == ProviderState.loading && _notifications.isEmpty;

  // Dashboard derived getters
  int get totalComplaints => _dashboard?.totalComplaints ?? 0;
  int get openComplaints => _dashboard?.openComplaints ?? 0;
  int get respondedComplaints => _dashboard?.respondedComplaints ?? 0;
  int get resolvedComplaints => _dashboard?.resolvedComplaints ?? 0;

  // Complaints lists
  List<HospitalComplaint> get recentComplaints => _complaints;
  List<HospitalComplaint> get queueComplaints => _complaints;

  // Queue Counts
  int _queueTotalCount = 0;
  int _queueNewCount = 0;
  int _queueReviewCount = 0;
  int _queueRespondedCount = 0;
  int _queueResolvedCount = 0;

  int get queueTotalCount => _queueTotalCount;
  int get queueNewCount => _queueNewCount;
  int get queueReviewCount => _queueReviewCount;
  int get queueRespondedCount => _queueRespondedCount;
  int get queueResolvedCount => _queueResolvedCount;

  // Freeze status
  bool _isFrozen = false;
  bool get isFrozen => _isFrozen;

  // Retry callbacks
  VoidCallback get retryDashboard => () => loadDashboard();
  VoidCallback get retryProfile => () => loadProfile();

  // Helper to set state & notify
  void _setState(ProviderState newState) {
    _state = newState;
    notifyListeners();
  }

  // ---------- Dashboard ----------
  Future<void> loadDashboard() async {
    _setState(ProviderState.loading);
    try {
      final data = await _repo.getDashboardStats();
      _dashboard = HospitalDashboardStats.fromJson(data);
      
      final recent = data['recent_complaints'] as List<dynamic>? ?? [];
      _complaints = recent.map((e) => HospitalComplaint.fromJson(e as Map<String, dynamic>)).toList();
      
      _isFrozen = data['is_frozen'] ?? false;
      
      _setState(ProviderState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProviderState.error);
    }
  }

  Future<void> loadProfile() async {
    _setState(ProviderState.loading);
    try {
      _profile = await _repo.getProfile();
      _setState(ProviderState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProviderState.error);
    }
  }

  Future<void> loadNotifications() async {
    _setState(ProviderState.loading);
    try {
      final data = await _repo.getNotifications();
      final list = (data['results'] as List<dynamic>? ?? []);
      _notifications = list.cast<Map<String, dynamic>>();
      _setState(ProviderState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProviderState.error);
    }
  }

  Future<void> loadConversations() async {
    _setState(ProviderState.loading);
    try {
      final list = await _repo.getConversations();
      _conversations = list;
      _setState(ProviderState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProviderState.error);
    }
  }

  // ---------- Complaints Queue ----------
  Future<void> loadQueue({String? status, String? search}) async {
    _setState(ProviderState.loading);
    try {
      final data = await _repo.getComplaints(status: status, search: search);
      final list = (data['complaints'] as List<dynamic>? ?? []);
      _complaints = list.map((e) => HospitalComplaint.fromJson(e as Map<String, dynamic>)).toList();
      _queueTotalCount = data['total_count'] ?? 0;
      _queueNewCount = data['new_count'] ?? 0;
      _queueReviewCount = data['review_count'] ?? 0;
      _queueRespondedCount = data['responded_count'] ?? 0;
      _queueResolvedCount = data['resolved_count'] ?? 0;
      _setState(ProviderState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProviderState.error);
    }
  }

  // ---------- Complaint Detail ----------
  Future<HospitalComplaint?> loadComplaintDetail(int id) async {
    _setState(ProviderState.loading);
    try {
      final data = await _repo.getComplaintDetail(id);
      final complaint = HospitalComplaint.fromJson(data);
      _setState(ProviderState.loaded);
      return complaint;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProviderState.error);
      return null;
    }
  }

  // ---------- Update Status ----------
  Future<bool> updateStatus(int id, String newStatus) async {
    try {
      await _repo.updateComplaintStatus(id, newStatus);
      return true;
    } catch (_) {
      return false;
    }
  }

    // ---------- Respond to Complaint ----------
  Future<bool> respondToComplaint(int id, String message, {bool isPrivate = false}) async {
    try {
      await _repo.respondToComplaint(id, message, isPrivate: isPrivate);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ---------- Change Password ----------
  Future<String?> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await _repo.changePassword(currentPassword: currentPassword, newPassword: newPassword);
      return null;
    } catch (e) {
      final err = e.toString();
      _errorMessage = err;
      notifyListeners();
      return err;
    }
  }

  

  // ---------- Hospital Feed ----------
  Future<void> loadHospitalFeed() async {
    _setState(ProviderState.loading);
    try {
      final data = await _repo.getHospitalFeed();
      final list = (data['results'] as List<dynamic>? ?? []);
      _feed = list.map((e) => HospitalPost.fromJson(e as Map<String, dynamic>)).toList();
      _setState(ProviderState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProviderState.error);
    }
  }

  // ---------- Notification handling ----------
  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      await _repo.markNotificationRead(notificationId);
      // Refresh notifications list
      await loadNotifications();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------- Utilities ----------
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
