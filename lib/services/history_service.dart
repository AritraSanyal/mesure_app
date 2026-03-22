import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ppg_processor.dart';

class HistoryEntry {
  final DateTime timestamp;
  final double heartRate;
  final double systolicBP;
  final double diastolicBP;
  final double spo2;
  final double rmssd;
  final double sdnn;
  final double signalQuality;

  HistoryEntry({
    required this.timestamp,
    required this.heartRate,
    required this.systolicBP,
    required this.diastolicBP,
    required this.spo2,
    required this.rmssd,
    required this.sdnn,
    required this.signalQuality,
  });

  factory HistoryEntry.fromResult(PPGResult r) => HistoryEntry(
        timestamp: r.timestamp,
        heartRate: r.heartRate,
        systolicBP: r.systolicBP,
        diastolicBP: r.diastolicBP,
        spo2: r.spo2,
        rmssd: r.hrv.rmssd,
        sdnn: r.hrv.sdnn,
        signalQuality: r.signalQuality,
      );

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'hr': heartRate,
        'sbp': systolicBP,
        'dbp': diastolicBP,
        'spo2': spo2,
        'rmssd': rmssd,
        'sdnn': sdnn,
        'sq': signalQuality,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        timestamp: DateTime.parse(j['timestamp']),
        heartRate: (j['hr'] as num).toDouble(),
        systolicBP: (j['sbp'] as num).toDouble(),
        diastolicBP: (j['dbp'] as num).toDouble(),
        spo2: (j['spo2'] as num).toDouble(),
        rmssd: (j['rmssd'] as num).toDouble(),
        sdnn: (j['sdnn'] as num).toDouble(),
        signalQuality: (j['sq'] as num).toDouble(),
      );
}

class HistoryService {
  static const _key = 'mesure_history';
  static const _maxEntries = 100;

  Future<List<HistoryEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => HistoryEntry.fromJson(jsonDecode(s)))
        .toList()
        .reversed
        .toList();
  }

  Future<void> save(PPGResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    existing.add(jsonEncode(HistoryEntry.fromResult(result).toJson()));
    if (existing.length > _maxEntries) {
      existing.removeAt(0);
    }
    await prefs.setStringList(_key, existing);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
