import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:offlinetrack/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('OfflineTrackApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OfflineTrackApp());
    expect(find.byType(OfflineTrackApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });
}
