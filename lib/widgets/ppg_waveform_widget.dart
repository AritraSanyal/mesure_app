import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class PPGWaveformWidget extends StatefulWidget {
  final List<double> signal;
  final double quality; // 0–100
  final bool isRecording;

  const PPGWaveformWidget({
    super.key,
    required this.signal,
    required this.quality,
    required this.isRecording,
  });

  @override
  State<PPGWaveformWidget> createState() => _PPGWaveformWidgetState();
}

class _PPGWaveformWidgetState extends State<PPGWaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isRecording
              ? AppTheme.teal.withOpacity(0.4)
              : AppTheme.divider,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _RecordingDot(isRecording: widget.isRecording),
                const SizedBox(width: 8),
                Text(
                  widget.isRecording ? 'LIVE PPG' : 'PPG SIGNAL',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                _QualityBadge(quality: widget.quality),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: widget.signal.isEmpty
                ? _PlaceholderWaveform(controller: _pulseController)
                : CustomPaint(
                    painter: _WaveformPainter(
                      signal: widget.signal,
                      color: AppTheme.teal,
                      quality: widget.quality,
                    ),
                    size: Size.infinite,
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _RecordingDot extends StatefulWidget {
  final bool isRecording;
  const _RecordingDot({required this.isRecording});

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppTheme.textSecondary,
          shape: BoxShape.circle,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppTheme.coral.withOpacity(_anim.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.coral.withOpacity(0.5 * _anim.value),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityBadge extends StatelessWidget {
  final double quality;
  const _QualityBadge({required this.quality});

  @override
  Widget build(BuildContext context) {
    final color = quality > 70
        ? AppTheme.green
        : quality > 40
            ? AppTheme.gold
            : AppTheme.coral;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.signal_cellular_alt, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            quality > 0
                ? '${quality.toInt()}% quality'
                : 'Waiting...',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderWaveform extends StatelessWidget {
  final AnimationController controller;
  const _PlaceholderWaveform({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => Opacity(
          opacity: 0.3 + 0.3 * controller.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app_outlined,
                  color: AppTheme.teal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Place finger over camera',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> signal;
  final Color color;
  final double quality;

  _WaveformPainter({
    required this.signal,
    required this.color,
    required this.quality,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (signal.isEmpty) return;

    // Show last N samples to fit width
    final int visible = min(signal.length, 300);
    final data = signal.sublist(signal.length - visible);

    final double minV = data.reduce(min);
    final double maxV = data.reduce(max);
    final double range = (maxV - minV).abs() + 1e-9;

    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.85);

    // Glow paint
    final glowPaint = Paint()
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    final glowPath = Path();

    for (int i = 0; i < data.length; i++) {
      final double x = i / (data.length - 1) * size.width;
      final double y =
          size.height - (data[i] - minV) / range * (size.height * 0.75) -
              size.height * 0.1;

      if (i == 0) {
        path.moveTo(x, y);
        glowPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        glowPath.lineTo(x, y);
      }
    }

    canvas.drawPath(glowPath, glowPaint);
    canvas.drawPath(path, paint);

    // Baseline
    canvas.drawLine(
      Offset(0, size.height - 8),
      Offset(size.width, size.height - 8),
      Paint()
        ..color = AppTheme.divider
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.signal != signal || old.quality != quality;
}
