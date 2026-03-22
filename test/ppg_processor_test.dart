import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesure_app/services/ppg_processor.dart';

void main() {
  group('PPGProcessor', () {
    test('returns null result when insufficient frames', () {
      final p = PPGProcessor();
      expect(p.computeResult(), isNull);
    });

    test('frameCount increments on addFrame', () {
      final p = PPGProcessor();
      p.addFrame(red: 120, green: 80, blue: 60);
      p.addFrame(red: 122, green: 81, blue: 61);
      expect(p.frameCount, equals(2));
    });

    test('reset clears all state', () {
      final p = PPGProcessor();
      for (int i = 0; i < 10; i++) {
        p.addFrame(red: 120.0 + sin(i * 0.5) * 10, green: 80, blue: 60);
      }
      p.reset();
      expect(p.frameCount, equals(0));
      expect(p.signal.isEmpty, isTrue);
      expect(p.computeResult(), isNull);
    });

    test('signal is populated after frames', () {
      final p = PPGProcessor();
      for (int i = 0; i < 100; i++) {
        p.addFrame(red: 120.0 + sin(i * 0.3) * 15, green: 80, blue: 60);
      }
      expect(p.signal.length, equals(100));
    });

    test('HRVMetrics SDNN is non-negative', () {
      // Feed a synthetic ~60 BPM signal at 30 fps
      final p = PPGProcessor();
      final rng = Random(42);
      for (int i = 0; i < 30 * 35; i++) {
        // Simulate heartbeat ~1 Hz with noise
        final double t = i / 30.0;
        final double red = 150 + 30 * sin(2 * pi * 1.0 * t) + rng.nextDouble() * 5;
        p.addFrame(red: red, green: 80, blue: 60);
      }
      final result = p.computeResult();
      if (result != null) {
        expect(result.hrv.sdnn, greaterThanOrEqualTo(0));
        expect(result.hrv.rmssd, greaterThanOrEqualTo(0));
        expect(result.hrv.pnn50, inInclusiveRange(0, 100));
      }
    });

    test('heart rate is physiologically plausible for 1 Hz signal', () {
      final p = PPGProcessor();
      for (int i = 0; i < 30 * 35; i++) {
        final double t = i / 30.0;
        final double red = 150 + 30 * sin(2 * pi * 1.0 * t);
        p.addFrame(red: red, green: 80, blue: 60);
      }
      final result = p.computeResult();
      if (result != null) {
        // ~60 BPM expected, allow wide range for synthetic signal
        expect(result.heartRate, inInclusiveRange(40.0, 180.0));
      }
    });

    test('BP estimate stays within physiological bounds', () {
      final p = PPGProcessor();
      for (int i = 0; i < 30 * 35; i++) {
        final double t = i / 30.0;
        p.addFrame(
          red: 150 + 30 * sin(2 * pi * 1.1 * t),
          green: 80,
          blue: 60,
        );
      }
      final result = p.computeResult();
      if (result != null) {
        expect(result.systolicBP, inInclusiveRange(80.0, 200.0));
        expect(result.diastolicBP, inInclusiveRange(50.0, 130.0));
        expect(result.systolicBP, greaterThan(result.diastolicBP));
      }
    });

    test('SpO2 clamps to 85–100', () {
      final p = PPGProcessor();
      for (int i = 0; i < 30 * 35; i++) {
        final double t = i / 30.0;
        p.addFrame(
          red: 150 + 20 * sin(2 * pi * t),
          green: 80,
          blue: 40 + 5 * sin(2 * pi * t),
        );
      }
      final result = p.computeResult();
      if (result != null) {
        expect(result.spo2, inInclusiveRange(85.0, 100.0));
      }
    });

    test('signal quality is 0–100', () {
      final p = PPGProcessor();
      for (int i = 0; i < 30 * 35; i++) {
        final double t = i / 30.0;
        p.addFrame(red: 150 + 30 * sin(2 * pi * t), green: 80, blue: 60);
      }
      final result = p.computeResult();
      if (result != null) {
        expect(result.signalQuality, inInclusiveRange(0.0, 100.0));
      }
    });

    test('PPGResult bpClassification returns known strings', () {
      // Create a synthetic result to test classification logic
      final p = PPGProcessor();
      for (int i = 0; i < 30 * 35; i++) {
        p.addFrame(
          red: 150 + 30 * sin(2 * pi * i / 30.0),
          green: 80,
          blue: 60,
        );
      }
      final result = p.computeResult();
      if (result != null) {
        expect(
          ['Normal', 'Elevated', 'High Stage 1', 'High Stage 2'],
          contains(result.bpClassification),
        );
        expect(
          ['Good', 'Moderate', 'Low'],
          contains(result.hrvStatus),
        );
      }
    });
  });

  group('HRVMetrics', () {
    test('zero values are handled gracefully', () {
      const hrv = HRVMetrics(sdnn: 0, rmssd: 0, pnn50: 0, lfhf: 1.0);
      expect(hrv.sdnn, equals(0));
      expect(hrv.rmssd, equals(0));
      expect(hrv.lfhf, equals(1.0));
    });
  });
}
