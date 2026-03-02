import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitto/shared/widgets/custom_bottom_navigation.dart';

void main() {
  group('CustomBottomNavigation Overflow Tests', () {
    testWidgets('No overflow with normal text scale',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.0)),
              child: CustomBottomNavigation(
                currentIndex: 3, // Chat selected - the problematic one
                onTap: (index) {},
                onTenantMenuClose: () {},
                onSwipeLeft: () {},
                onSwipeRight: () {},
                onGoBack: () {},
                userMode: 'inquilino',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      // Verify Chat text is present and properly constrained
      final chatText = tester.widget<Text>(find.text('Chat'));
      expect(chatText.overflow, equals(TextOverflow.ellipsis));
      expect(chatText.maxLines, equals(1));
    });

    testWidgets('No overflow with large text scale',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: CustomBottomNavigation(
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
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors even with large text
      expect(tester.takeException(), isNull);
    });

    testWidgets('No overflow with extra large text scale',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: CustomBottomNavigation(
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
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow errors even with extra large text
      expect(tester.takeException(), isNull);
    });

    testWidgets('No overflow with different selected items',
        (WidgetTester tester) async {
      for (int i = 0; i < 4; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: CustomBottomNavigation(
                currentIndex: i,
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

        await tester.pumpAndSettle();

        // Verify no overflow errors for any selected item
        expect(tester.takeException(), isNull,
            reason: 'Overflow detected when item $i is selected');
      }
    });

    testWidgets('Text scaling works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: CustomBottomNavigation(
                currentIndex: 1, // Buscar selected
                onTap: (index) {},
                onTenantMenuClose: () {},
                onSwipeLeft: () {},
                onSwipeRight: () {},
                onGoBack: () {},
                userMode: 'inquilino',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify text is scaled but not overflowing
      expect(tester.takeException(), isNull);

      // Find the Propiedades text
      final buscarText = tester.widget<Text>(find.text('Propiedades'));
      expect(buscarText.style!.fontSize, greaterThan(12));
      expect(buscarText.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('Small screen size handling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320, // iPhone SE width
              child: CustomBottomNavigation(
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
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow on small screens
      expect(tester.takeException(), isNull);
    });

    testWidgets('All navigation items fit within constraints',
        (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Find all navigation items
      final items = find.byType(InkWell);
      expect(items, findsNWidgets(4));

      // Verify no overflow
      expect(tester.takeException(), isNull);
    });
  });
}
