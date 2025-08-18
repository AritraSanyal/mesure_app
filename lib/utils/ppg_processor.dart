import 'dart:math';

class PPGProcessor {
  static List<double> smooth(List<double> signal, int windowSize) {
    List<double> smoothed = [];
    for (int i = 0; i < signal.length - windowSize + 1; i++) {
      double avg =
          signal.sublist(i, i + windowSize).reduce((a, b) => a + b) /
          windowSize;
      smoothed.add(avg);
    }
    return smoothed;
  }

  static int calculateHeartRate(List<double> signal, int durationSeconds) {
    if (signal.length < 3) return 0;
    List<double> smoothed = smooth(signal, 5);
    int peakCount = 0;

    for (int i = 1; i < smoothed.length - 1; i++) {
      if (smoothed[i] > smoothed[i - 1] && smoothed[i] > smoothed[i + 1]) {
        peakCount++;
      }
    }

    return ((peakCount / durationSeconds) * 60).round();
  }

  static double calculateHRV(List<int> rrIntervals) {
    if (rrIntervals.length < 2) return 0;
    List<double> diffs = [];
    for (int i = 1; i < rrIntervals.length; i++) {
      diffs.add((rrIntervals[i] - rrIntervals[i - 1]).toDouble());
    }

    double sumSquares = diffs.map((d) => d * d).reduce((a, b) => a + b);
    return sqrt(sumSquares / diffs.length);
  }

  static String estimateBloodPressure(int hr, double hrv) {
    double sbp = 0.72 * hr + 0.5 * hrv + 80;
    double dbp = 0.4 * hr + 0.3 * hrv + 50;
    return "${sbp.round()}/${dbp.round()}";
  }
}
