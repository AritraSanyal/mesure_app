import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/history_service.dart';
import '../utils/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _service = HistoryService();
  List<HistoryEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _service.loadAll();
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
          : _entries.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppTheme.teal,
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_entries.length >= 3) ...[
                          _buildTrendChart(),
                          const SizedBox(height: 20),
                        ],
                        ..._entries.map(_buildEntry),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📊', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No measurements yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Take your first measurement to see history',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final reversed = _entries.reversed.toList();
    final hrSpots = reversed
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.heartRate))
        .toList();
    final sbpSpots = reversed
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.systolicBP))
        .toList();

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
            'TRENDS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.teal,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _legendDot(AppTheme.coral, 'Heart Rate (BPM)'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.teal, 'Systolic BP (mmHg)'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.divider,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= reversed.length) {
                          return const SizedBox();
                        }
                        return Text(
                          DateFormat('M/d').format(reversed[idx].timestamp),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: hrSpots,
                    isCurved: true,
                    color: AppTheme.coral,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.coral.withOpacity(0.06),
                    ),
                  ),
                  LineChartBarData(
                    spots: sbpSpots,
                    isCurved: true,
                    color: AppTheme.teal,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.teal.withOpacity(0.06),
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

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEntry(HistoryEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          // Date
          Column(
            children: [
              Text(
                DateFormat('MMM').format(e.timestamp).toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.teal,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                DateFormat('dd').format(e.timestamp),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(e.timestamp),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: AppTheme.divider,
          ),
          // Vitals
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _statChip('❤️', '${e.heartRate.toInt()} bpm'),
                _statChip(
                    '🩸', '${e.systolicBP.toInt()}/${e.diastolicBP.toInt()}'),
                _statChip('🫁', '${e.spo2.toStringAsFixed(0)}%'),
                _statChip('📊', 'HRV ${e.rmssd.toInt()}ms'),
              ],
            ),
          ),
          // Quality dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: e.signalQuality > 70
                  ? AppTheme.green
                  : e.signalQuality > 40
                      ? AppTheme.gold
                      : AppTheme.coral,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String emoji, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Clear History?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('All saved measurements will be deleted.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.coral)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _service.clear();
      _load();
    }
  }
}
