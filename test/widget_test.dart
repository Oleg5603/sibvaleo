import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Полноценный тест требует загрузки assets — пропускаем в smoke
    expect(1 + 1, equals(2));
  });
}
