import 'package:flutter/foundation.dart';
import 'package:medvoice_flutter/features/patient/data/patient_repository.dart';
import 'package:medvoice_flutter/features/patient/domain/models/dashboard_stats.dart';

class PatientDashboardProvider extends ChangeNotifier {
  PatientDashboardProvider({PatientRepository? repository})
      : _repository = repository ?? PatientRepository();

  final PatientRepository _repository;

  DashboardStats? _stats;
  List<PatientNotification> _notifications = [];
  bool _isLoading = false;
  bool _showNotificationPanel = false;
  String? _errorMessage;

  DashboardStats? get stats => _stats;
  List<PatientNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get showNotificationPanel => _showNotificationPanel;
  String? get errorMessage => _errorMessage;

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final statsFuture = _repository.getDashboardStats();
      final notificationsFuture = _repository.getNotifications();

      _stats = await statsFuture;
      _notifications = await notificationsFuture;
    } catch (e) {
      _errorMessage = 'Failed to load dashboard: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleNotificationPanel() {
    _showNotificationPanel = !_showNotificationPanel;
    notifyListeners();
  }

  void closeNotificationPanel() {
    if (_showNotificationPanel) {
      _showNotificationPanel = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationRead(int id) async {
    await _repository.markNotificationRead(id);
    _notifications = await _repository.getNotifications();
    notifyListeners();
  }

  Future<void> refresh() => loadDashboard();
  Future<void> retry() => loadDashboard();
}
