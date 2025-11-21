import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitto/shared/widgets/custom_bottom_navigation.dart';
import 'package:habitto/shared/widgets/floating_action_menu.dart';

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
              showAddButton: false,
              isOwnerOrAgent: false,
              onHomeTap: () {},
              onMoreTap: () {},
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

    testWidgets('Floating menu button appears for owner/agent users',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
              currentIndex: 2,
              onTap: (index) {},
              showAddButton: true,
              isOwnerOrAgent: true,
              onHomeTap: () {},
              onMoreTap: () {},
            ),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that the floating menu button is present
      expect(find.byIcon(Icons.home), findsOneWidget);

      // Tap the center button to trigger floating menu
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      // Verify that the floating menu appears
      expect(find.byType(FloatingActionMenu), findsOneWidget);
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
              showAddButton: false,
              isOwnerOrAgent: false,
              onHomeTap: () {},
              onMoreTap: () {},
            ),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Tap on the search icon (index 1)
      await tester.tap(find.byIcon(Icons.search_outlined));
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
              showAddButton: false,
              isOwnerOrAgent: false,
              onHomeTap: () {},
              onMoreTap: () {},
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
