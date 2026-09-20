import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week4_api/main.dart';

void main() {
  testWidgets('Smoke test render aplikasi', (WidgetTester tester) async {
    // Memuat aplikasi MyApp dengan ProviderScope Riverpod
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Menyelesaikan semua microtask / timer asinkron yang menggantung
    await tester.pumpAndSettle();

    // Memastikan aplikasi berhasil di-render
    expect(find.byType(MyApp), findsOneWidget);
  });
}