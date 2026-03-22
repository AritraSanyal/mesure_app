import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mesure_app/services/history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HistoryService', () {
    test('loadAll returns empty list when no entries', () async {
      final svc = HistoryService();
      final entries = await svc.loadAll();
      expect(entries, isEmpty);
    });

    test('HistoryEntry serializes and deserializes correctly', () {
      final now = DateTime(2025, 6, 1, 12, 30);
      final entry = HistoryEntry(
        timestamp: now,
        heartRate: 72.0,
        systolicBP: 120.0,
        diastolicBP: 80.0,
        spo2: 98.5,
        rmssd: 42.0,
        sdnn: 55.0,
        signalQuality: 85.0,
      );
      final json = entry.toJson();
      final restored = HistoryEntry.fromJson(json);

      expect(restored.heartRate, equals(72.0));
      expect(restored.systolicBP, equals(120.0));
      expect(restored.diastolicBP, equals(80.0));
      expect(restored.spo2, equals(98.5));
      expect(restored.rmssd, equals(42.0));
      expect(restored.sdnn, equals(55.0));
      expect(restored.signalQuality, equals(85.0));
      expect(restored.timestamp, equals(now));
    });

    test('clear removes all entries', () async {
      SharedPreferences.setMockInitialValues({
        'mesure_history': [
          '{"timestamp":"2025-01-01T00:00:00.000","hr":70,"sbp":118,"dbp":76,"spo2":98,"rmssd":45,"sdnn":50,"sq":80}',
        ],
      });
      final svc = HistoryService();
      await svc.clear();
      final entries = await svc.loadAll();
      expect(entries, isEmpty);
    });
  });
}
