import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ResultScreen extends StatelessWidget {
  final int heartRate;
  final String bloodPressure;
  final double hrv;
  final List<double> hrData;
  final List<double> hrvData;
  final List<double> bpData;

  const ResultScreen({
    Key? key,
    required this.heartRate,
    required this.bloodPressure,
    required this.hrv,
    required this.hrData,
    required this.hrvData,
    required this.bpData,
  }) : super(key: key);

  Widget _buildGraph(String title, List<double> data, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value))
                      .toList(),
                  isCurved: true,
                  color: color,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Measurement Results")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Heart Rate: $heartRate BPM",
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                "Blood Pressure: $bloodPressure mmHg",
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                "HRV: ${hrv.toStringAsFixed(2)} ms",
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 24),
              _buildGraph("Heart Rate Graph", hrData, Colors.redAccent),
              _buildGraph("HRV Graph", hrvData, Colors.blueAccent),
              _buildGraph("Blood Pressure Graph", bpData, Colors.purple),
            ],
          ),
        ),
      ),
    );
  }
}
