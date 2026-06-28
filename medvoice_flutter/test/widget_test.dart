import 'package:flutter_test/flutter_test.dart';
import 'package:medvoice_flutter/app/medvoice_app.dart';

void main() {
  testWidgets('MedVoiceApp shows splash then welcome', (tester) async {
    await tester.pumpWidget(const MedVoiceApp());
    expect(find.text('Medical Grievance Platform'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME TO MEDVOICE'), findsOneWidget);
  });
}
