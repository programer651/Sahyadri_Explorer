import 'package:flutter_test/flutter_test.dart';
import 'package:sahyadri_explorer/main.dart';
import 'dart:io';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('App should load', (WidgetTester tester) async {
    // Shimming for images in tests
    await tester.runAsync(() async {
      await tester.pumpWidget(const ZeniTrekApp());
      await tester.pump();
      expect(find.text('ZeniTrek'), findsWidgets);
    });
  });
}
