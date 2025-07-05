import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scan2pdf/main.dart';
import 'package:scan2pdf/providers/image_provider.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ImageProviderModel(),
        child: const MyApp(),
      ),
    );

    // Verify that our app starts correctly
    expect(find.text('Fast Scan2PDF'), findsOneWidget);
  });
}
