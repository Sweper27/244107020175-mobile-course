// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Menggunakan nama package proyek Anda
import 'package:pertemuan_2/main.dart';

void main() {
  testWidgets('Dashboard satu kolom di layar sempit', (tester) async {
    // 1. Atur layar menjadi sempit (400px)
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // 2. Jalankan aplikasi
    await tester.pumpWidget(const DashboardApp());

    // 3. Verifikasi lebar kartu
    final width = tester.getSize(find.byType(Card).first).width;
    expect(width, lessThan(700));
  });

  testWidgets('Dashboard dua kolom di layar lebar', (tester) async {
    // 1. Atur layar menjadi lebar (1200px)
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // 2. Jalankan aplikasi
    await tester.pumpWidget(const DashboardApp());

    // 3. Verifikasi lebar kartu
    final width = tester.getSize(find.byType(Card).first).width;
    expect(width, greaterThan(500));
  });
}
