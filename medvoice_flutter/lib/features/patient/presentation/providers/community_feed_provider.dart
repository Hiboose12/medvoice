import 'package:flutter/foundation.dart';
import 'package:medvoice_flutter/features/patient/data/patient_repository.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_post.dart';

class CommunityFeedProvider extends ChangeNotifier {
  CommunityFeedProvider({PatientRepository? repository})
      : _repository = repository ?? PatientRepository();

  final PatientRepository _repository;

  List<ComplaintPost> _posts = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _showCreateModal = false;
  String? _errorMessage;

  List<ComplaintPost> get posts => _posts;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get showCreateModal => _showCreateModal;
  String? get errorMessage => _errorMessage;

  Future<void> loadFeed() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _repository.getComplaintFeed(query: _searchQuery);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    await loadFeed();
  }

  void openCreateModal() {
    _showCreateModal = true;
    notifyListeners();
  }

  void closeCreateModal() {
    _showCreateModal = false;
    notifyListeners();
  }

  Future<void> toggleLike(int postId) async {
    await _repository.toggleLike(postId);
    await loadFeed();
  }

  void prependPost(ComplaintPost post) {
    _posts = [post, ..._posts];
    notifyListeners();
  }

  Future<void> retry() => loadFeed();
}
