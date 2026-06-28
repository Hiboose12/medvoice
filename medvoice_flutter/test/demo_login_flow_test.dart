import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvoice_flutter/app/medvoice_app.dart';
import 'package:medvoice_flutter/features/auth/data/mock_auth_data.dart';

void main() {
  const accounts = [
    (username: 'johndoe', dashboardText: 'Welcome back, John!'),
    (username: 'cityhospital', dashboardText: 'Recent complaints assigned to your hospital'),
    (username: 'healthauth', dashboardText: 'Escalations requiring oversight'),
    (username: 'superadmin', dashboardText: 'Platform governance queue'),
  ];

  for (final account in accounts) {
    testWidgets('${account.username} opens the expected dashboard', (
      tester,
    ) async {
      await tester.pumpWidget(const MedVoiceApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'LOGIN / REGISTER'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), account.username);
      await tester.enterText(
        find.byType(TextField).at(1),
        MockAuthData.demoPassword,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(account.dashboardText), findsOneWidget);
    });
  }
}
