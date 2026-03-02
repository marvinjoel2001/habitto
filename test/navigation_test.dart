import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitto/shared/widgets/custom_bottom_navigation.dart';

void main() {
  group('CustomBottomNavigation Tests', () {
    testWidgets('Text overflow is handled correctly in selected items',
        (WidgetTester tester) async {
      // Build our app with the CustomBottomNavigation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
              currentIndex: 0,
              onTap: (index) {},
              onTenantMenuClose: () {},
              onSwipeLeft: () {},
              onSwipeRight: () {},
              onGoBack: () {},
              userMode: 'inquilino',
            ),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that the text is properly constrained
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final textWidget in textWidgets) {
        expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      }
    });

    testWidgets('Regular navigation items work for tenant users',
        (WidgetTester tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
              currentIndex: 0,
              onTap: (index) {
                tappedIndex = index;
              },
              onTenantMenuClose: () {},
              onSwipeLeft: () {},
              onSwipeRight: () {},
              onGoBack: () {},
              userMode: 'inquilino',
            ),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Tap on the properties icon (index 1)
      await tester.tap(find.byIcon(Icons.home_work_outlined));
      await tester.pumpAndSettle();

      // Verify that the correct index was tapped
      expect(tappedIndex, equals(1));
    });

    testWidgets('Text labels are properly truncated',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
              currentIndex: 3, // Chat selected
              onTap: (index) {},
              onTenantMenuClose: () {},
              onSwipeLeft: () {},
              onSwipeRight: () {},
              onGoBack: () {},
              userMode: 'inquilino',
            ),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Find the selected chat text
      final chatText = tester.widget<Text>(find.text('Chat'));
      expect(chatText.overflow, equals(TextOverflow.ellipsis));
      expect(chatText.maxLines, equals(1));
    });
  });
}
