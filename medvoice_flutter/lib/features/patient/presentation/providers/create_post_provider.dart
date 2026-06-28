import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medvoice_flutter/features/patient/data/patient_repository.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_status.dart';
import 'package:medvoice_flutter/features/patient/domain/models/patient_models.dart';

class CreatePostProvider extends ChangeNotifier {
  CreatePostProvider({required PatientRepository repository})
      : _repository = repository;

  final PatientRepository _repository;
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  String? _errorMessage;

  // Real picked file path (non-null when user has picked something)
  String? _evidenceFilePath;
  String? _evidenceFileName;
  Uint8List? _evidenceBytes;

  bool _showManualHospital = false;
  int? _selectedHospitalId;
  ComplaintSeverity _severity = ComplaintSeverity.medium;
  List<PatientHospitalOption> _hospitals = [];
  List<String> _categories = const [
    'Service Quality',
    'Clinical Quality',
    'Staff Conduct',
    'Access & Billing',
    'Facility & Safety',
    'Patient Rights',
    'General',
  ];

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get evidenceFileName => _evidenceFileName;
  bool get hasEvidence => _evidenceFilePath != null;
  bool get showManualHospital => _showManualHospital;
  int? get selectedHospitalId => _selectedHospitalId;
  ComplaintSeverity get severity => _severity;
  List<PatientHospitalOption> get hospitals => _hospitals;
  List<String> get categories => _categories;

  Future<void> loadOptions() async {
    try {
      final options = await _repository.getComplaintOptions();
      _hospitals = options.hospitals;
      if (options.categories.isNotEmpty) {
        _categories = options.categories.map((c) => c.name).toList();
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading complaint options: $e');
      }
      // Keep local defaults if the metadata request fails.
    }
  }

  void setSeverity(ComplaintSeverity value) {
    _severity = value;
    notifyListeners();
  }

  void setHospitalSelection(String? value) {
    if (value == 'other') {
      _showManualHospital = true;
      _selectedHospitalId = null;
    } else if (value != null && value.isNotEmpty) {
      _showManualHospital = false;
      _selectedHospitalId = int.tryParse(value);
    } else {
      _showManualHospital = false;
      _selectedHospitalId = null;
    }
    notifyListeners();
  }

  /// Opens the native image picker (gallery). Replaces mockPickEvidence.
  Future<void> pickEvidenceFromGallery() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        _evidenceBytes = await picked.readAsBytes();
        _evidenceFilePath = picked.path;
        _evidenceFileName = picked.name;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  /// Opens the native camera. 
  Future<void> pickEvidenceFromCamera() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (picked != null) {
        _evidenceBytes = await picked.readAsBytes();
        _evidenceFilePath = picked.path;
        _evidenceFileName = picked.name;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to capture image: $e';
      notifyListeners();
    }
  }

  void clearEvidence() {
    _evidenceFilePath = null;
    _evidenceFileName = null;
    _evidenceBytes = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _isSubmitting = false;
    _errorMessage = null;
    _evidenceFilePath = null;
    _evidenceFileName = null;
    _evidenceBytes = null;
    _showManualHospital = false;
    _selectedHospitalId = null;
    _severity = ComplaintSeverity.medium;
    notifyListeners();
  }

  Future<bool> submit({
    required String title,
    required String description,
    required String category,
    String? unregisteredHospitalName,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final formData = FormData();
      formData.fields.add(MapEntry('title', title));
      formData.fields.add(MapEntry('description', description));
      formData.fields.add(MapEntry('category', category));
      formData.fields.add(MapEntry('severity', _severity.name));

      if (_selectedHospitalId != null) {
        formData.fields.add(MapEntry('hospital', _selectedHospitalId.toString()));
      }
      if (_showManualHospital && unregisteredHospitalName != null) {
        formData.fields.add(
          MapEntry('unregistered_hospital_name', unregisteredHospitalName),
        );
      }

      // Attach real file if one was picked
      if (_evidenceBytes != null) {
        formData.files.add(MapEntry(
          'evidence',
          MultipartFile.fromBytes(
            _evidenceBytes!,
            filename: _evidenceFileName,
          ),
        ));
      }

      await _repository.uploadComplaint(formData);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
