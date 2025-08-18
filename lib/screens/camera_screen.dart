import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/ppg_processor.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  final String measurementType;
  const CameraScreen({Key? key, required this.measurementType})
    : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isFingerDetected = false;
  bool _isButtonVisible = false;
  bool _isLoading = true;
  bool _isMeasuring = false;
  int _timer = 60;
  Timer? _countdownTimer;
  List<double> brightnessValues = [];

  int frameCounter = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    WakelockPlus.enable();
  }

  Future<void> _initializeCamera() async {
    WidgetsFlutterBinding.ensureInitialized();
    _cameras = await availableCameras();
    final backCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );
    _controller = CameraController(
      backCamera,
      ResolutionPreset.low,
      enableAudio: false,
    );
    await _controller!.initialize();
    _controller!.startImageStream(_processCameraImage);
    setState(() => _isLoading = false);
  }

  void _processCameraImage(CameraImage image) {
    frameCounter++;

    if (frameCounter % 2 != 0) return;

    int avg = _getAverageBrightness(image);
    if (_isMeasuring) {
      setState(() {
        brightnessValues.add(avg.toDouble());
      });
    } else {
      if (avg < 50) {
        if (!_isFingerDetected) {
          setState(() {
            _isFingerDetected = true;
            _isButtonVisible = true;
          });
        }
      } else {
        if (_isFingerDetected) {
          setState(() {
            _isFingerDetected = false;
            _isButtonVisible = false;
          });
        }
      }
    }
  }

  int _getAverageBrightness(CameraImage image) {
    try {
      final bytes = image.planes[0].bytes;
      int sum = 0;
      for (int i = 0; i < bytes.length; i += 20) {
        sum += bytes[i] & 0xFF;
      }
      return sum ~/ (bytes.length ~/ 20);
    } catch (e) {
      return 255;
    }
  }

  void _startMeasurement() {
    setState(() {
      _isMeasuring = true;
      _isButtonVisible = false;
      brightnessValues.clear();
      _timer = 60;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _timer--);
      if (_timer == 0) {
        timer.cancel();
        _endMeasurement();
      }
    });
  }

  void _endMeasurement() {
    int hr = PPGProcessor.calculateHeartRate(brightnessValues, 60);
    double hrv = PPGProcessor.calculateHRV([
      860,
      870,
      850,
      865,
    ]); // Simulated RR
    String bp = PPGProcessor.estimateBloodPressure(hr, hrv);
    List<double> bpValues = bp.split('/').map((e) => double.parse(e)).toList();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          heartRate: hr,
          bloodPressure: bp,
          hrv: hrv,
          hrData: brightnessValues,
          hrvData: [50.1, 51.5, 49.9], // Simulated HRV graph
          bpData: bpValues,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _countdownTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: CameraPreview(_controller!)),

            if (!_isMeasuring)
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isFingerDetected ? Colors.green : Colors.red,
                      width: 6,
                    ),
                  ),
                ),
              ),

            if (_isMeasuring)
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "$_timer sec",
                    style: const TextStyle(fontSize: 28, color: Colors.white),
                  ),
                ),
              ),

            if (_isButtonVisible && !_isMeasuring)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton(
                    onPressed: _startMeasurement,
                    child: const Text(
                      "Start Measuring",
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

            if (_isMeasuring)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 150,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: LineChart(
                      LineChartData(
                        backgroundColor: Colors.transparent,
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: brightnessValues
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value))
                                .toList(),
                            isCurved: true,
                            color: Colors.greenAccent,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                            barWidth: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
