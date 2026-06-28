import 'package:flutter/foundation.dart';
import 'package:medvoice_flutter/features/operations/data/authority_repository.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_post.dart';

class AuthorityProvider extends ChangeNotifier {
  AuthorityProvider({AuthorityRepository? repository})
      : _repository = repository ?? AuthorityRepository();

  final AuthorityRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;

  // Dashboard stats
  int _totalHospitals = 0;
  int _activeComplaints = 0;
  int _escalatedComplaints = 0;
  int _resolvedComplaints = 0;
  int _hospitalsWithWarnings = 0;
  int _unreadNotificationsCount = 0;
  int _frozenHospitalsCount = 0;
  List<ComplaintPost> _recentEscalations = [];

  // Data lists
  List<ComplaintPost> _queueComplaints = [];
  List<ComplaintPost> _escalations = [];
  List<dynamic> _hospitals = [];
  List<dynamic> _warnings = [];
  List<dynamic> _notifications = [];

  // Profile
  Map<String, dynamic>? _profile;

  // Settings
  int _responseTimeThreshold = 48;
  int _viewTimeThreshold = 24;
  int _warningThreshold = 3;
  bool _emailNotifications = true;
  bool _escalationAlerts = true;
  bool _warningAlerts = true;
  bool _freezeAlerts = true;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalHospitals => _totalHospitals;
  int get activeComplaints => _activeComplaints;
  int get escalatedComplaints => _escalatedComplaints;
  int get resolvedComplaints => _resolvedComplaints;
  int get hospitalsWithWarnings => _hospitalsWithWarnings;
  int get unreadNotificationsCount => _unreadNotificationsCount;
  int get frozenHospitalsCount => _frozenHospitalsCount;
  List<ComplaintPost> get recentEscalations => _recentEscalations;

  List<ComplaintPost> get queueComplaints => _queueComplaints;
  List<ComplaintPost> get escalations => _escalations;
  List<dynamic> get hospitals => _hospitals;
  List<dynamic> get warnings => _warnings;
  List<dynamic> get notifications => _notifications;

  int get responseTimeThreshold => _responseTimeThreshold;
  int get viewTimeThreshold => _viewTimeThreshold;
  int get warningThreshold => _warningThreshold;
  bool get emailNotifications => _emailNotifications;
  bool get escalationAlerts => _escalationAlerts;
  bool get warningAlerts => _warningAlerts;
  bool get freezeAlerts => _freezeAlerts;

  Map<String, dynamic>? get profile => _profile;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getDashboardStats();
      _totalHospitals = data['total_hospitals'] ?? 0;
      _activeComplaints = data['active_complaints'] ?? 0;
      _escalatedComplaints = data['escalated_complaints'] ?? 0;
      _resolvedComplaints = data['resolved_complaints'] ?? 0;
      _hospitalsWithWarnings = data['hospitals_with_warnings'] ?? 0;
      _unreadNotificationsCount = data['unread_notifications'] ?? 0;
      _frozenHospitalsCount = data['frozen_hospitals'] ?? 0;

      final recent = data['recent_escalations'] as List<dynamic>? ?? [];
      _recentEscalations = recent
          .map((json) => ComplaintPost.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadQueue({String? status, String? severity, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getComplaints(
        status: status,
        severity: severity,
        search: search,
      );
      final list = data['complaints'] as List<dynamic>? ?? [];
      _queueComplaints = list
          .map((json) => ComplaintPost.fromJson(json as Map<String, dynamic>))
          .toList();
      _escalatedComplaints = data['escalated_count'] ?? 0;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEscalations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getEscalations();
      final list = data['complaints'] as List<dynamic>? ?? [];
      _escalations = list
          .map((json) => ComplaintPost.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHospitals({String? status, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getHospitals(status: status, search: search);
      _hospitals = data['hospitals'] as List<dynamic>? ?? [];
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWarnings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getWarnings();
      _warnings = data['warnings'] as List<dynamic>? ?? [];
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getHospitalDetail(int hospitalId) async {
    try {
      return await _repository.getHospitalDetail(hospitalId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getNotifications();
      _notifications = data['notifications'] as List<dynamic>? ?? [];
      _unreadNotificationsCount = 0; // Django marks them as read automatically
    } catch (e) {
      _errorMessage = 'Failed to load notifications';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.getProfile();
    } catch (e) {
      _errorMessage = 'Failed to load profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.updateProfile(data);
    } catch (e) {
      _errorMessage = 'Failed to update profile';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getSettings();
      _responseTimeThreshold = data['response_time_threshold'] ?? 48;
      _viewTimeThreshold = data['view_time_threshold'] ?? 24;
      _warningThreshold = data['warning_threshold'] ?? 3;
      _emailNotifications = data['email_notifications'] ?? true;
      _escalationAlerts = data['escalation_alerts'] ?? true;
      _warningAlerts = data['warning_alerts'] ?? true;
      _freezeAlerts = data['freeze_alerts'] ?? true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateThresholds(int responseTime, int viewTime, int warningLimit) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateSettings({
        'action': 'update_thresholds',
        'response_time_threshold': responseTime,
        'view_time_threshold': viewTime,
        'warning_threshold': warningLimit,
      });
      _responseTimeThreshold = responseTime;
      _viewTimeThreshold = viewTime;
      _warningThreshold = warningLimit;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateNotificationSettings(
    bool email,
    bool escalation,
    bool warning,
    bool freeze,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateSettings({
        'action': 'update_notifications',
        'email_notifications': email,
        'escalation_alerts': escalation,
        'warning_alerts': warning,
        'freeze_alerts': freeze,
      });
      _emailNotifications = email;
      _escalationAlerts = escalation;
      _warningAlerts = warning;
      _freezeAlerts = freeze;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> issueWarning(
    int hospitalId,
    String warningType,
    String reason, {
    int? complaintId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.issueWarning(hospitalId, {
        'warning_type': warningType.toLowerCase(),
        'reason': reason,
        'complaint_id': ?complaintId,
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> freezeHospital(int hospitalId, String reason, String description) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.freezeHospital(hospitalId, {
        'reason': reason.toLowerCase(),
        'description': description,
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> unfreezeHospital(int hospitalId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.unfreezeHospital(hospitalId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _repository.markNotificationRead(notificationId);
      _notifications = _notifications.map((n) {
        if (n['id'] == notificationId) {
          final copy = Map<String, dynamic>.from(n);
          copy['is_read'] = true;
          return copy;
        }
        return n;
      }).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }
}
