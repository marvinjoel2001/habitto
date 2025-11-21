import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitto/shared/widgets/tenant_floating_menu.dart';

void main() {
  group('TenantFloatingMenu Tests', () {
    testWidgets('Menu appears with 50% opacity overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.white), // Background
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
      );

      await tester.pumpAndSettle();

      // Verify overlay exists with 50% opacity
      final overlay = tester.widget<Container>(find.descendant(
        of: find.byType(GestureDetector).first,
        matching: find.byType(Container),
      ));
      expect(overlay.color, equals(Colors.black.withValues(alpha: 0.5)));
    });

    testWidgets('Menu buttons are positioned correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.white),
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
      );

      await tester.pumpAndSettle();

      // Verify all action buttons are present
      expect(find.byIcon(Icons.rotate_left), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);

      // Verify buttons are positioned in a wrap layout
      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.alignment, equals(WrapAlignment.center));
    });

    testWidgets('Menu appears immediately without delay', (WidgetTester tester) async {
      bool menuVisible = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Stack(
                  children: [
                    Container(color: Colors.white),
                    TenantFloatingMenu(
                      isVisible: menuVisible,
                      onClose: () {
                        setState(() => menuVisible = false);
                      },
                      onSwipeLeft: () {},
                      onSwipeRight: () {},
                      onGoBack: () {},
                      onAddFavorite: () {},
                    ),
                    Positioned(
                      bottom: 20,
                      child: ElevatedButton(
                        onPressed: () => setState(() => menuVisible = true),
                        child: const Text('Show Menu'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Initially menu should not be visible
      expect(find.byIcon(Icons.rotate_left), findsNothing);

      // Tap button to show menu
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Start animation

      // Menu should start appearing immediately
      expect(find.byIcon(Icons.rotate_left), findsOneWidget);
    });

    testWidgets('Menu closes when overlay is tapped', (WidgetTester tester) async {
      bool menuVisible = true;
      bool menuClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.white),
                TenantFloatingMenu(
                  isVisible: menuVisible,
                  onClose: () {
                    menuVisible = false;
                    menuClosed = true;
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

      // Tap on overlay (first GestureDetector)
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(menuClosed, isTrue);
    });

    testWidgets('All action buttons trigger their callbacks', (WidgetTester tester) async {
      bool swipeLeftCalled = false;
      bool swipeRightCalled = false;
      bool goBackCalled = false;
      bool addFavoriteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.white),
                TenantFloatingMenu(
                  isVisible: true,
                  onClose: () {},
                  onSwipeLeft: () => swipeLeftCalled = true,
                  onSwipeRight: () => swipeRightCalled = true,
                  onGoBack: () => goBackCalled = true,
                  onAddFavorite: () => addFavoriteCalled = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test each button
      await tester.tap(find.byIcon(Icons.rotate_left));
      expect(goBackCalled, isTrue);

      await tester.tap(find.byIcon(Icons.close));
      expect(swipeLeftCalled, isTrue);

      await tester.tap(find.byIcon(Icons.favorite));
      expect(swipeRightCalled, isTrue);

      await tester.tap(find.byIcon(Icons.star));
      expect(addFavoriteCalled, isTrue);
    });

    testWidgets('Menu positioned correctly above navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.white),
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
      );

      await tester.pumpAndSettle();

      // Verify menu is positioned at bottom: 100
      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.bottom, equals(100));
      expect(positioned.left, equals(0));
      expect(positioned.right, equals(0));
    });

    testWidgets('Menu handles visibility changes smoothly', (WidgetTester tester) async {
      bool menuVisible = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Stack(
                  children: [
                    Container(color: Colors.white),
                    TenantFloatingMenu(
                      isVisible: menuVisible,
                      onClose: () {
                        setState(() => menuVisible = false);
                      },
                      onSwipeLeft: () {},
                      onSwipeRight: () {},
                      onGoBack: () {},
                      onAddFavorite: () {},
                    ),
                    Positioned(
                      bottom: 20,
                      child: ElevatedButton(
                        onPressed: () => setState(() => menuVisible = !menuVisible),
                        child: const Text('Toggle Menu'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Initially hidden
      expect(find.byIcon(Icons.rotate_left), findsNothing);

      // Show menu
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.rotate_left), findsOneWidget);

      // Hide menu
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.rotate_left), findsNothing);
    });

    testWidgets('Menu works with different screen sizes', (WidgetTester tester) async {
      // Test with small screen
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320, // iPhone SE width
              height: 568,
              child: Stack(
                children: [
                  Container(color: Colors.white),
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

      // Verify menu fits on small screen
      expect(find.byIcon(Icons.rotate_left), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}