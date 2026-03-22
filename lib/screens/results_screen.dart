import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/ppg_processor.dart';
import '../utils/app_theme.dart';
import '../widgets/vital_card.dart';

class ResultsScreen extends StatelessWidget {
  final PPGResult result;

  const ResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Your Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareResults(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Overall status
              BigStatusDisplay(
                emoji: _overallEmoji,
                label: _overallLabel,
                color: AppTheme.statusColor(_overallStatus),
                description: _overallDescription,
              ),

              const SizedBox(height: 24),

              // Signal quality note
              if (result.signalQuality < 50)
                _buildQualityWarning(context),

              const SizedBox(height: 8),

              // Blood Pressure (full width)
              BPCard(
                systolic: result.systolicBP,
                diastolic: result.diastolicBP,
                status: result.bpClassification,
              ),

              const SizedBox(height: 16),

              // 2-column grid: HR + SpO2
              Row(
                children: [
                  Expanded(
                    child: VitalCard(
                      label: 'HEART RATE',
                      value: result.heartRate.toInt().toString(),
                      unit: 'BPM',
                      status: result.hrClassification,
                      icon: Icons.monitor_heart_outlined,
                      accentColor: AppTheme.coral,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: VitalCard(
                      label: 'OXYGEN SAT.',
                      value: result.spo2.toStringAsFixed(1),
                      unit: '%',
                      status: result.spo2 >= 95 ? 'Normal' : 'Low',
                      icon: Icons.air,
                      accentColor: AppTheme.teal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // HRV section
              _buildHRVSection(context),

              const SizedBox(height: 16),

              // RR interval chart
              if (result.rrIntervals.length >= 4)
                _buildRRChart(context),

              const SizedBox(height: 28),

              // Disclaimer
              _buildDisclaimer(context),

              const SizedBox(height: 16),

              // New measurement button
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('NEW MEASUREMENT'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _overallStatus {
    if (result.bpClassification == 'Normal' &&
        result.hrClassification == 'Normal') return 'Good';
    if (result.bpClassification.startsWith('High Stage 2') ||
        result.heartRate > 120 ||
        result.heartRate < 50) return 'High Stage 2';
    return 'Moderate';
  }

  String get _overallEmoji {
    switch (_overallStatus) {
      case 'Good':
        return '😊';
      case 'Moderate':
        return '😐';
      default:
        return '⚠️';
    }
  }

  String get _overallLabel {
    switch (_overallStatus) {
      case 'Good':
        return 'Looks Good!';
      case 'Moderate':
        return 'Slightly Elevated';
      default:
        return 'See a Doctor';
    }
  }

  String get _overallDescription {
    switch (_overallStatus) {
      case 'Good':
        return 'Your vitals appear within normal range.';
      case 'Moderate':
        return 'Some values are slightly outside normal range. Consider resting.';
      default:
        return 'Some values need attention. Please consult a healthcare provider.';
    }
  }

  Widget _buildQualityWarning(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Signal quality was ${result.signalQuality.toInt()}% — results may be less accurate. Try again with better finger placement.',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHRVSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart,
                    color: AppTheme.teal, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'HEART RATE VARIABILITY',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.teal,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.statusColor(result.hrvStatus)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  result.hrvStatus,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.statusColor(result.hrvStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HRVMetricTile(
                label: 'SDNN',
                value: result.hrv.sdnn.toInt().toString(),
                unit: 'ms',
                tooltip: 'Overall HRV',
              ),
              _HRVMetricTile(
                label: 'RMSSD',
                value: result.hrv.rmssd.toInt().toString(),
                unit: 'ms',
                tooltip: 'Vagal tone',
              ),
              _HRVMetricTile(
                label: 'pNN50',
                value: result.hrv.pnn50.toStringAsFixed(1),
                unit: '%',
                tooltip: 'Beat variation',
              ),
              _HRVMetricTile(
                label: 'LF/HF',
                value: result.hrv.lfhf.toStringAsFixed(2),
                unit: '',
                tooltip: 'Autonomic balance',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRRChart(BuildContext context) {
    final rr = result.rrIntervals;
    final spots = rr
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final minY = rr.reduce((a, b) => a < b ? a : b) - 50;
    final maxY = rr.reduce((a, b) => a > b ? a : b) + 50;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RR INTERVALS (Tachogram)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.teal,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Time between heartbeats',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.divider,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        if (v.toInt() % 5 != 0) return const SizedBox();
                        return Text(
                          '#${v.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.teal,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: AppTheme.teal,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.teal.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navyLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This app is for wellness monitoring only and is NOT a medical device. '
              'Results are estimates and should not replace clinical diagnosis. '
              'Consult a healthcare professional for medical advice.',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareResults(BuildContext context) {
    final text = '''
Mesure App Results — ${result.timestamp}

❤️  Heart Rate: ${result.heartRate.toInt()} BPM (${result.hrClassification})
🩸  Blood Pressure: ${result.systolicBP.toInt()}/${result.diastolicBP.toInt()} mmHg (${result.bpClassification})
🫁  SpO2: ${result.spo2.toStringAsFixed(1)}%
📊  HRV RMSSD: ${result.hrv.rmssd.toInt()} ms (${result.hrvStatus})

⚠️ Not a medical device — for wellness monitoring only.
''';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Results copied to clipboard'),
        backgroundColor: AppTheme.teal,
      ),
    );
  }
}

class _HRVMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String tooltip;

  const _HRVMetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value$unit',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.teal,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            tooltip,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
