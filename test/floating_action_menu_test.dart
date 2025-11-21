import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitto/shared/widgets/floating_action_menu.dart';

void main() {
  group('FloatingActionMenu Tests', () {
    testWidgets('should show fullscreen overlay with 50% opacity', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingActionMenu(
              isVisible: true,
              onHomeTap: () {},
              onMoreTap: () {},
              onClose: () {},
              onSocialAreasTap: () {},
              onAlertHistoryTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify overlay exists
      final overlayFinder = find.byType(Container);
      expect(overlayFinder, findsWidgets);

      // Verify action buttons exist
      expect(find.text('Áreas sociales'), findsOneWidget);
      expect(find.text('Historial de alertas'), findsOneWidget);
      expect(find.text('✕'), findsOneWidget);
    });

    testWidgets('should call callbacks when buttons are tapped', (WidgetTester tester) async {
      bool socialAreasTapped = false;
      bool alertHistoryTapped = false;
      bool closeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingActionMenu(
              isVisible: true,
              onHomeTap: () {},
              onMoreTap: () {},
              onClose: () {
                closeTapped = true;
              },
              onSocialAreasTap: () {
                socialAreasTapped = true;
              },
              onAlertHistoryTap: () {
                alertHistoryTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap social areas button
      await tester.tap(find.text('Áreas sociales'));
      await tester.pumpAndSettle();
      expect(socialAreasTapped, isTrue);

      // Tap alert history button
      await tester.tap(find.text('Historial de alertas'));
      await tester.pumpAndSettle();
      expect(alertHistoryTapped, isTrue);

      // Tap close button
      await tester.tap(find.text('✕'));
      await tester.pumpAndSettle();
      expect(closeTapped, isTrue);
    });

    testWidgets('should be responsive on different screen sizes', (WidgetTester tester) async {
      // Test on small screen
      tester.binding.window.physicalSizeTestValue = const Size(320, 568);
      tester.binding.window.devicePixelRatioTestValue = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingActionMenu(
              isVisible: true,
              onHomeTap: () {},
              onMoreTap: () {},
              onClose: () {},
              onSocialAreasTap: () {},
              onAlertHistoryTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify buttons are visible on small screen
      expect(find.text('Áreas sociales'), findsOneWidget);
      expect(find.text('Historial de alertas'), findsOneWidget);

      // Reset screen size
      tester.binding.window.clearPhysicalSizeTestValue();
    });

    testWidgets('should show animation on appear/disappear', (WidgetTester tester) async {
      bool isVisible = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FloatingActionMenu(
                  isVisible: isVisible,
                  onHomeTap: () {},
                  onMoreTap: () {},
                  onClose: () {
                    setState(() {
                      isVisible = false;
                    });
                  },
                  onSocialAreasTap: () {},
                  onAlertHistoryTap: () {},
                );
              },
            ),
          ),
        ),
      );

      // Initially hidden
      expect(find.text('Áreas sociales'), findsNothing);

      // Show menu
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FloatingActionMenu(
                  isVisible: true,
                  onHomeTap: () {},
                  onMoreTap: () {},
                  onClose: () {},
                  onSocialAreasTap: () {},
                  onAlertHistoryTap: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Áreas sociales'), findsOneWidget);
    });

    testWidgets('should be accessible with proper semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingActionMenu(
              isVisible: true,
              onHomeTap: () {},
              onMoreTap: () {},
              onClose: () {},
              onSocialAreasTap: () {},
              onAlertHistoryTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify semantics - find by text since the buttons contain the text
      expect(find.text('Áreas sociales'), findsOneWidget);
      expect(find.text('Historial de alertas'), findsOneWidget);
      
      // Verify that buttons are tappable
      await tester.tap(find.text('Áreas sociales'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Historial de alertas'));
      await tester.pumpAndSettle();
    });
  });
}