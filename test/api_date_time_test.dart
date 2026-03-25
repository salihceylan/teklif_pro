import 'package:flutter_test/flutter_test.dart';
import 'package:teklif_pro/core/api_date_time.dart';

void main() {
  test('parseApiDateTime treats timezone-less API values as UTC', () {
    final parsed = parseApiDateTime('2026-03-25T08:07:49.230529');

    expect(parsed.isUtc, isFalse);
    expect(parsed.year, 2026);
    expect(parsed.month, 3);
    expect(parsed.day, 25);
    expect(parsed.hour, anyOf(8, 11));
  });
}
