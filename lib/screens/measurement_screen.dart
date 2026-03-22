import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/ppg_processor.dart';
import '../services/history_service.dart';
import '../utils/app_theme.dart';
import '../widgets/ppg_waveform_widget.dart';
import 'results_screen.dart';

class MeasurementScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const MeasurementScreen({super.key, required this.cameras});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen>
    with WidgetsBindingObserver {
  CameraController? _camCtrl;
  final PPGProcessor _processor = PPGProcessor();
  final HistoryService _history = HistoryService();

  bool _isRecording = false;
  bool _fingerDetected = false;
  int _secondsElapsed = 0;
  Timer? _timer;
  double _signalQuality = 0;
  List<double> _displaySignal = [];

  static const int measureDurationSec = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopRecording();
    _camCtrl?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;
    // Use back camera (index 0)
    final cam = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    _camCtrl = CameraController(
      cam,
      ResolutionPreset.low, // Low res for performance
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _camCtrl!.initialize();
    if (mounted) setState(() {});
  }

  void _startRecording() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;

    _processor.reset();
    setState(() {
      _isRecording = true;
      _secondsElapsed = 0;
      _fingerDetected = false;
    });

    WakelockPlus.enable();
    HapticFeedback.mediumImpact();

    // Turn on torch flash for finger PPG
    await _camCtrl!.setFlashMode(FlashMode.torch);

    // Start image stream
    await _camCtrl!.startImageStream(_processFrame);

    // Countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsElapsed++);
      if (_secondsElapsed >= measureDurationSec) {
        _finishRecording();
      }
    });
  }

  void _processFrame(CameraImage img) {
    // Extract average pixel values from the Y (luminance) plane and RGB planes
    double red = 0, green = 0, blue = 0;
    int count = 0;

    if (img.format.group == ImageFormatGroup.yuv420) {
      // YUV420: Y plane gives luminance (proxy for red in torch-lit finger)
      final yPlane = img.planes[0];
      final uPlane = img.planes[1];
      final vPlane = img.planes[2];

      final int w = img.width;
      final int h = img.height;
      final int centerX = w ~/ 2;
      final int centerY = h ~/ 2;
      final int roi = 30; // 60x60 central ROI

      for (int y = centerY - roi; y < centerY + roi; y++) {
        for (int x = centerX - roi; x < centerX + roi; x++) {
          if (x < 0 || y < 0 || x >= w || y >= h) continue;
          final int yIdx = y * yPlane.bytesPerRow + x;
          final int uvIdx = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2);
          final int yVal = yPlane.bytes[yIdx];
          final int uVal = uPlane.bytes[uvIdx] - 128;
          final int vVal = vPlane.bytes[uvIdx] - 128;

          // YUV -> RGB
          final int r = (yVal + 1.402 * vVal).round().clamp(0, 255);
          final int g =
              (yVal - 0.344 * uVal - 0.714 * vVal).round().clamp(0, 255);
          final int b = (yVal + 1.772 * uVal).round().clamp(0, 255);
          red += r;
          green += g;
          blue += b;
          count++;
        }
      }
    } else if (img.format.group == ImageFormatGroup.bgra8888) {
      // BGRA on iOS
      final plane = img.planes[0];
      final int w = img.width;
      final int h = img.height;
      final int centerX = w ~/ 2;
      final int centerY = h ~/ 2;
      final int roi = 30;

      for (int y = centerY - roi; y < centerY + roi; y++) {
        for (int x = centerX - roi; x < centerX + roi; x++) {
          if (x < 0 || y < 0 || x >= w || y >= h) continue;
          final int idx = (y * plane.bytesPerRow) + (x * 4);
          blue += plane.bytes[idx];
          green += plane.bytes[idx + 1];
          red += plane.bytes[idx + 2];
          count++;
        }
      }
    }

    if (count == 0) return;
    red /= count;
    green /= count;
    blue /= count;

    // Finger detection heuristic: green channel dominates with finger coverage
    final bool fingerNow =
        green > 50 && green > red * 0.8 && green > blue * 0.8;

    _processor.addFrame(red: red, green: green, blue: blue);

    if (mounted) {
      setState(() {
        _fingerDetected = fingerNow;
        _signalQuality = _processor.signal.length > 30
            ? (_processor.computeResult()?.signalQuality ?? 0)
            : 0;
        // Show last 300 samples
        final sig = _processor.signal;
        _displaySignal = sig.length > 300 ? sig.sublist(sig.length - 300) : sig;
      });
    }
  }

  void _stopRecording() async {
    _timer?.cancel();
    _timer = null;
    if (_camCtrl?.value.isStreamingImages == true) {
      await _camCtrl!.stopImageStream();
    }
    await _camCtrl?.setFlashMode(FlashMode.off);
    WakelockPlus.disable();
    setState(() => _isRecording = false);
  }

  void _finishRecording() async {
    _stopRecording();
    final result = _processor.computeResult();
    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough data. Please try again.'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
      return;
    }

    await _history.save(result);
    HapticFeedback.heavyImpact();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(result: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsElapsed / measureDurationSec;

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Measure Vitals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            _stopRecording();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Camera preview card
              _buildCameraCard(),

              const SizedBox(height: 20),

              // Waveform
              PPGWaveformWidget(
                signal: _displaySignal,
                quality: _signalQuality,
                isRecording: _isRecording,
              ),

              const SizedBox(height: 20),

              // Finger placement guide
              if (!_fingerDetected && _isRecording)
                _buildFingerGuide(false)
              else if (_fingerDetected && _isRecording)
                _buildFingerGuide(true),

              const SizedBox(height: 20),

              // Timer progress
              if (_isRecording) _buildTimerProgress(progress),

              const SizedBox(height: 28),

              // Start / Stop button
              _isRecording ? _buildStopButton() : _buildStartButton(),

              const SizedBox(height: 16),

              // Instructions
              _buildInstructions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraCard() {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.teal),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 160,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_camCtrl!),
            // Red overlay when recording
            if (_isRecording)
              Container(
                color: _fingerDetected
                    ? Colors.red.withOpacity(0.3)
                    : Colors.black.withOpacity(0.4),
              ),
            // Center target reticle
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _fingerDetected
                        ? AppTheme.green
                        : Colors.white.withOpacity(0.6),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _isRecording ? (_fingerDetected ? '✓' : '👆') : '📷',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerGuide(bool detected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: detected
            ? AppTheme.green.withOpacity(0.1)
            : AppTheme.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: detected
              ? AppTheme.green.withOpacity(0.3)
              : AppTheme.gold.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            detected ? '✅' : '☝️',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detected ? 'Finger Detected!' : 'Place your finger',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: detected ? AppTheme.green : AppTheme.gold,
                  ),
                ),
                Text(
                  detected
                      ? 'Hold still — measuring...'
                      : 'Cover the camera lens completely',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerProgress(double progress) {
    final remaining = measureDurationSec - _secondsElapsed;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Measuring...',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.teal),
            ),
            Text(
              '${remaining}s remaining',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppTheme.divider,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.teal),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton.icon(
      onPressed: _startRecording,
      icon: const Icon(Icons.play_arrow_rounded, size: 26),
      label: const Text('START MEASUREMENT'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 64),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildStopButton() {
    return OutlinedButton.icon(
      onPressed: _stopRecording,
      icon: const Icon(Icons.stop_rounded, color: AppTheme.coral),
      label: const Text(
        'STOP',
        style: TextStyle(color: AppTheme.coral, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        side: const BorderSide(color: AppTheme.coral),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildInstructions() {
    final steps = [
      ('1', '📱', 'Open app, tap START'),
      ('2', '🔦', 'Place fingertip over back camera with flash'),
      ('3', '🤫', 'Stay still, keep gentle pressure'),
      ('4', '⏱', 'Wait 30 seconds for results'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW TO MEASURE',
            style: TextStyle(
              color: AppTheme.teal,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(s.$2, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.$3,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
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
}
