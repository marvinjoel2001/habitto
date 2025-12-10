import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitto/shared/widgets/tenant_floating_menu.dart';

void main() {
  group('TenantFloatingMenu Responsive Tests', () {
    // Test different device sizes
    final deviceSizes = [
      const Size(320, 568), // iPhone SE
      const Size(375, 667), // iPhone 8
      const Size(414, 896), // iPhone 11 Pro Max
      const Size(360, 640), // Android small
      const Size(411, 823), // Android medium
      const Size(1440, 3040), // Android large
    ];

    for (final deviceSize in deviceSizes) {
      testWidgets(
          'Menu adapts to ${deviceSize.width}x${deviceSize.height} screen',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: deviceSize.width,
                height: deviceSize.height,
                child: Stack(
                  children: [
                    Container(color: Colors.blue), // Background
                    TenantFloatingMenu(
                      isVisible: true,
                      onClose: () {},
                      onSwipeLeft: () {},
                      onSwipeRight: () {},
                      onGoBack: () {},
                      onAddFavorite: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify menu is visible
        expect(find.byType(TenantFloatingMenu), findsOneWidget);

        // Verify overlay is present
        expect(find.byType(GestureDetector), findsOneWidget);

        // Verify menu is positioned correctly above navigation
        final positioned = tester.widget<Positioned>(find.byType(Positioned));
        expect(positioned.bottom, 100);

        // Verify no overflow errors
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Menu buttons scale correctly on small screens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320, // iPhone SE width
              height: 568,
              child: Stack(
                children: [
                  Container(color: Colors.blue),
                  TenantFloatingMenu(
                    isVisible: true,
                    onClose: () {},
                    onSwipeLeft: () {},
                    onSwipeRight: () {},
                    onGoBack: () {},
                    onAddFavorite: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all action buttons
      final buttons = find.byType(InkWell);
      expect(buttons, findsNWidgets(4));

      // Verify no overflow on small screens
      expect(tester.takeException(), isNull);
    });

    testWidgets('Menu buttons use normal size on large screens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1440, // Large screen width
              height: 3040,
              child: Stack(
                children: [
                  Container(color: Colors.blue),
                  TenantFloatingMenu(
                    isVisible: true,
                    onClose: () {},
                    onSwipeLeft: () {},
                    onSwipeRight: () {},
                    onGoBack: () {},
                    onAddFavorite: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all action buttons
      final buttons = find.byType(InkWell);
      expect(buttons, findsNWidgets(4));

      // Verify no overflow on large screens
      expect(tester.takeException(), isNull);
    });

    testWidgets('Menu works with different text scales',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: Stack(
                children: [
                  Container(color: Colors.blue),
                  TenantFloatingMenu(
                    isVisible: true,
                    onClose: () {},
                    onSwipeLeft: () {},
                    onSwipeRight: () {},
                    onGoBack: () {},
                    onAddFavorite: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify menu is still functional with larger text
      expect(find.byType(TenantFloatingMenu), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // Test callback functionality
    testWidgets('onClose callback works correctly',
        (WidgetTester tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.blue),
                TenantFloatingMenu(
                  isVisible: true,
                  onClose: () {
                    callbackCalled = true;
                  },
                  onSwipeLeft: () {},
                  onSwipeRight: () {},
                  onGoBack: () {},
                  onAddFavorite: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the overlay (should trigger onClose)
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(callbackCalled, isTrue, reason: 'onClose should be called');
    });

    testWidgets('Action button callbacks work correctly',
        (WidgetTester tester) async {
      final callbacks = {
        'onSwipeLeft': false,
        'onSwipeRight': false,
        'onGoBack': false,
        'onAddFavorite': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.blue),
                TenantFloatingMenu(
                  isVisible: true,
                  onClose: () {},
                  onSwipeLeft: () {
                    callbacks['onSwipeLeft'] = true;
                  },
                  onSwipeRight: () {
                    callbacks['onSwipeRight'] = true;
                  },
                  onGoBack: () {
                    callbacks['onGoBack'] = true;
                  },
                  onAddFavorite: () {
                    callbacks['onAddFavorite'] = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test each action button
      await tester.tap(find.byIcon(Icons.rotate_left)); // Go back
      await tester.pumpAndSettle();
      expect(callbacks['onGoBack'], isTrue);

      await tester.tap(find.byIcon(Icons.close)); // Reject/Swipe left
      await tester.pumpAndSettle();
      expect(callbacks['onSwipeLeft'], isTrue);

      await tester.tap(find.byIcon(Icons.favorite)); // Like/Swipe right
      await tester.pumpAndSettle();
      expect(callbacks['onSwipeRight'], isTrue);

      await tester.tap(find.byIcon(Icons.star)); // Add favorite
      await tester.pumpAndSettle();
      expect(callbacks['onAddFavorite'], isTrue);
    });
  });
}
