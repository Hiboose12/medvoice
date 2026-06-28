import 'package:flutter/foundation.dart';
import 'package:medvoice_flutter/features/admin/data/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider({AdminRepository? repository})
      : _repository = repository ?? AdminRepository();

  final AdminRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;

  bool _isLoadingProfile = false;
  String? _profileErrorMessage;
  Map<String, dynamic>? _profileData;

  // State variables
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _users = [];
  Map<String, dynamic>? _userDetail;
  List<dynamic> _pendingEntities = [];
  List<dynamic> _auditLogs = [];
  List<dynamic> _securityAlerts = [];
  
  int _usersPage = 1;
  int _usersTotalPages = 1;
  int _usersTotal = 0;
  int _usersStartIndex = 0;
  int _usersEndIndex = 0;
  bool _hasNextUsers = false;
  bool _hasPreviousUsers = false;

  int _auditLogsPage = 1;
  int _auditLogsTotalPages = 1;
  
  int _securityAlertsPage = 1;
  int _securityAlertsTotalPages = 1;

  // Security alert counts
  int _openAlertsCount = 0;
  int _criticalAlertsCount = 0;
  int _recentAlertsCount24h = 0;

  // Security settings
  bool _twoFaEnabled = false;
  int _sessionTimeout = 1209600;
  int _maxLoginAttempts = 5;

  // Categories state
  List<dynamic> _categories = [];
  int _categoriesPage = 1;
  int _categoriesTotalPages = 1;
  int _categoriesTotal = 0;
  int _categoriesStartIndex = 0;
  int _categoriesEndIndex = 0;
  bool _hasNextCategories = false;
  bool _hasPreviousCategories = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? get dashboardData => _dashboardData;

  List<dynamic> get users => _users;
  Map<String, dynamic>? get userDetail => _userDetail;
  List<dynamic> get pendingEntities => _pendingEntities;
  List<dynamic> get auditLogs => _auditLogs;
  List<dynamic> get securityAlerts => _securityAlerts;

  int get usersPage => _usersPage;
  int get usersTotalPages => _usersTotalPages;
  int get usersTotal => _usersTotal;
  int get usersStartIndex => _usersStartIndex;
  int get usersEndIndex => _usersEndIndex;
  bool get hasNextUsers => _hasNextUsers;
  bool get hasPreviousUsers => _hasPreviousUsers;
  int get auditLogsPage => _auditLogsPage;
  int get auditLogsTotalPages => _auditLogsTotalPages;
  int get securityAlertsPage => _securityAlertsPage;
  int get securityAlertsTotalPages => _securityAlertsTotalPages;

  int get openAlertsCount => _openAlertsCount;
  int get criticalAlertsCount => _criticalAlertsCount;
  int get recentAlertsCount24h => _recentAlertsCount24h;

  bool get twoFaEnabled => _twoFaEnabled;
  int get sessionTimeout => _sessionTimeout;
  int get maxLoginAttempts => _maxLoginAttempts;

  // Categories getters
  List<dynamic> get categories => _categories;
  int get categoriesPage => _categoriesPage;
  int get categoriesTotalPages => _categoriesTotalPages;
  int get categoriesTotal => _categoriesTotal;
  int get categoriesStartIndex => _categoriesStartIndex;
  int get categoriesEndIndex => _categoriesEndIndex;
  bool get hasNextCategories => _hasNextCategories;
  bool get hasPreviousCategories => _hasPreviousCategories;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboardData = await _repository.getSuperadminDashboard();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers({String? search, String? role, String? status, int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.fetchUsers(
        search: search,
        role: role,
        status: status,
        page: page,
      );
      _users = data['users'] as List<dynamic>? ?? [];
      _usersPage = data['page'] ?? 1;
      _usersTotalPages = data['total_pages'] ?? 1;
      _usersTotal = data['total_users'] ?? 0;
      _usersStartIndex = data['start_index'] ?? 0;
      _usersEndIndex = data['end_index'] ?? 0;
      _hasNextUsers = data['has_next'] ?? false;
      _hasPreviousUsers = data['has_previous'] ?? false;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserDetail(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userDetail = await _repository.fetchUserDetail(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> modifyUserStatus(int userId, String action, {String? reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.modifyUserStatus(userId, action, reason: reason);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEntityVerification({String? search, String? verification}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.fetchEntityVerification(
        search: search,
        verification: verification,
      );
      _pendingEntities = data['items'] as List<dynamic>? ?? [];
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> loadEntityVerificationDetail(String entityType, int entityId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.fetchEntityVerificationDetail(entityType, entityId);
      return data;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyEntity(String entityType, int entityId, String action, {String? reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.verifyEntity(entityType, entityId, action, reason: reason);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAuditLogs({String? search, String? action, String? date, String? role, int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.fetchAuditLogs(
        search: search,
        action: action,
        date: date,
        role: role,
        page: page,
      );
      _auditLogs = data['logs'] as List<dynamic>? ?? [];
      _auditLogsPage = data['page'] ?? 1;
      _auditLogsTotalPages = data['total_pages'] ?? 1;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchUserActivity(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _repository.fetchUserActivity(userId);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveHospitalAppeal(int freezeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.approveHospitalAppeal(freezeId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectHospitalAppeal(int freezeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.rejectHospitalAppeal(freezeId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> executeUserAction(int userId, String action, {String? reason}) async {
    try {
      await _repository.executeUserAction(userId, action, reason: reason);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<void> loadSecurityAlerts({String? severity, String? resolved, int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.fetchSecurityAlerts(
        severity: severity,
        resolved: resolved,
        page: page,
      );
      _securityAlerts = data['alerts'] as List<dynamic>? ?? [];
      _securityAlertsPage = data['page'] ?? 1;
      _securityAlertsTotalPages = data['total_pages'] ?? 1;
      _openAlertsCount = data['open_count'] ?? 0;
      _criticalAlertsCount = data['critical_count'] ?? 0;
      _recentAlertsCount24h = data['recent_count_24h'] ?? 0;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resolveSecurityAlert(int alertId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.resolveSecurityAlert(alertId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> triggerExportAuditLogs({String? action, String? date}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> triggerSecurityScan() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.triggerSecurityScan();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSecuritySettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.fetchSecuritySettings();
      _twoFaEnabled = data['two_fa_enabled'] ?? false;
      _sessionTimeout = data['session_timeout'] ?? 1209600;
      _maxLoginAttempts = data['max_login_attempts'] ?? 5;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSecuritySettings({
    required bool twoFaEnabled,
    required int sessionTimeout,
    required int maxLoginAttempts,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateSecuritySettings({
        'two_fa_enabled': twoFaEnabled,
        'session_timeout': sessionTimeout,
        'max_login_attempts': maxLoginAttempts,
      });
      _twoFaEnabled = twoFaEnabled;
      _sessionTimeout = sessionTimeout;
      _maxLoginAttempts = maxLoginAttempts;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories({String? search, int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.fetchCategories(
        search: search,
        page: page,
      );
      _categories = data['categories'] as List<dynamic>? ?? [];
      _categoriesPage = data['page'] ?? 1;
      _categoriesTotalPages = data['total_pages'] ?? 1;
      _categoriesTotal = data['total_categories'] ?? 0;
      _categoriesStartIndex = data['start_index'] ?? 0;
      _categoriesEndIndex = data['end_index'] ?? 0;
      _hasNextCategories = data['has_next'] ?? false;
      _hasPreviousCategories = data['has_previous'] ?? false;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(String name, String description) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.addCategory(name, description);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(int categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteCategory(categoryId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> loadUserActivity(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _repository.fetchUserActivity(userId);
      return data;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> performUserAction(int userId, String action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.performUserAction(userId, action);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Support Tickets State
  List<dynamic> _supportTickets = [];
  String _supportStatusFilter = 'all';

  List<dynamic> get supportTickets => _supportTickets;
  String get supportStatusFilter => _supportStatusFilter;

  void setSupportStatusFilter(String status) {
    if (_supportStatusFilter != status) {
      _supportStatusFilter = status;
      loadSupportTickets(status: status);
    }
  }

  Future<void> loadSupportTickets({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    if (status != null) {
      _supportStatusFilter = status;
    }
    notifyListeners();

    try {
      final data = await _repository.fetchSupportTickets(status: _supportStatusFilter);
      _supportTickets = data['tickets'] as List<dynamic>? ?? [];
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitSupportReply(int ticketId, String reply) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.replyToSupportTicket(ticketId, reply);
      // Reload tickets after reply
      await loadSupportTickets();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Notifications State
  List<dynamic> _notifications = [];
  bool _isLoadingNotifications = false;

  List<dynamic> get notifications => _notifications;
  bool get isLoadingNotifications => _isLoadingNotifications;

  Future<void> loadNotifications() async {
    _isLoadingNotifications = true;
    notifyListeners();

    try {
      final data = await _repository.fetchNotifications();
      _notifications = data['notifications'] as List<dynamic>? ?? [];
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _repository.markNotificationRead(notificationId);
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        final Map<String, dynamic> updatedNotification = Map<String, dynamic>.from(_notifications[index]);
        updatedNotification['is_read'] = true;
        _notifications[index] = updatedNotification;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Profile
  bool get isLoadingProfile => _isLoadingProfile;
  String? get profileErrorMessage => _profileErrorMessage;
  Map<String, dynamic>? get profileData => _profileData;

  Future<void> loadProfile() async {
    _isLoadingProfile = true;
    _profileErrorMessage = null;
    notifyListeners();

    try {
      _profileData = await _repository.fetchProfile();
    } catch (e) {
      _profileErrorMessage = e.toString();
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }
}