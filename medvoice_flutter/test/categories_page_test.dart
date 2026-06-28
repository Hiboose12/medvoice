import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvoice_flutter/features/operations/presentation/screens/operational_screen.dart';
import 'package:provider/provider.dart';
import 'package:medvoice_flutter/features/admin/presentation/providers/admin_provider.dart';
import 'package:medvoice_flutter/features/admin/data/admin_repository.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';

void main() {
  testWidgets('Test CategoriesPage', (WidgetTester tester) async {
    final mockRepo = AdminRepository();
    final provider = AdminProvider(repository: mockRepo);
    
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<AdminProvider>.value(
              value: provider,
              child: const OperationalScreen(
                role: OperationalRole.admin, 
                page: OperationalPage.categories
              ),
            ),
          ),
        ),
      );
      
      expect(find.byType(Column), findsWidgets);
    } catch (e) {
      print("CRASH: $e");
      throw e;
    }
  });
}
