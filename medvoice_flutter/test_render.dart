
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvoice_flutter/features/operations/presentation/screens/operational_screen.dart';
import 'package:medvoice_flutter/features/operations/domain/models/hospital_profile.dart';
import 'package:medvoice_flutter/features/operations/presentation/providers/hospital_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Test hospital profile content', (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      print('FLUTTER ERROR: ');
      print(details.stack);
    };
    final profile = HospitalProfile(
      id: 1,
      hospitalName: 'Apollo Hospital',
      hospitalType: 'General',
      registrationNumber: 'REG123',
      licenseNumber: 'LIC123',
      address: '123 Main St',
      district: 'Cityville',
      state: 'State',
      pincode: '12345',
      contactNumber: '1234567890',
      email: 'apollo@example.com',
      status: 'approved',
    );
    final provider = HospitalProvider();
    // Use a hack to set the profile if there's no setter
    // Assuming there's no setter, we might need a mock, but wait, HospitalProvider extends ChangeNotifier?
    // Let's just build the content method if we can access it. But it's private _buildHospitalContent... 
    // Since we can't access private methods, let's just run OperationalScreen ? Or _ProfilePage?
    // OperationalScreen is public.
  });
}

