import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitto/shared/widgets/custom_network_image.dart';

void main() {
  testWidgets('CustomNetworkImage renders correctly with placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomNetworkImage(
            imageUrl: 'https://example.com/image.jpg',
            width: 100,
            height: 100,
          ),
        ),
      ),
    );

    // It should find the placeholder (CircularProgressIndicator) initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('CustomNetworkImage shows error widget for empty url', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomNetworkImage(
            imageUrl: '',
            width: 100,
            height: 100,
          ),
        ),
      ),
    );

    // It should find the error widget (Icon)
    expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
  });
}
