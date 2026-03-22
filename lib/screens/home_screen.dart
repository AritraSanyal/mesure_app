import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/history_service.dart';
import '../utils/app_theme.dart';
import '../widgets/vital_card.dart';
import 'measurement_screen.dart';
import 'history_screen.dart';
import 'onboarding_screen.dart';
import 'permission_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const HomeScreen({super.key, required this.cameras});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HistoryEntry? _latest;
  bool _loading = true;
  bool _onboardingDone = true;
  bool _cameraGranted = false;

  @override
  void initState() {
    super.initState();
    _loadLatest();
    _checkOnboarding();
    _checkCameraPermission();
  }

  Future<void> _checkOnboarding() async {
    final p = await SharedPreferences.getInstance();
    final done = p.getBool('onboarding_done') ?? false;
    if (!done && mounted) setState(() => _onboardingDone = false);
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (mounted) setState(() => _cameraGranted = status.isGranted);
  }

  Future<void> _loadLatest() async {
    final entries = await HistoryService().loadAll();
    setState(() {
      _latest = entries.isNotEmpty ? entries.first : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show onboarding first run
    if (!_onboardingDone) {
      return OnboardingScreen(onComplete: () {
        setState(() => _onboardingDone = true);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildMeasureButton(),
              const SizedBox(height: 28),
              if (!_loading && _latest != null) ...[
                _buildLastReadings(),
                const SizedBox(height: 24),
              ],
              _buildQuickGuide(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mesure',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      letterSpacing: -1,
                    ),
              ),
            ],
          ),
        ),
        // History button
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ).then((_) => _loadLatest()),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.divider),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppTheme.teal,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Settings button
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.divider),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: AppTheme.textSecondary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasureButton() {
    return GestureDetector(
      onTap: () async {
        // Check/request camera permission before starting
        if (!_cameraGranted) {
          final status = await Permission.camera.request();
          if (!status.isGranted) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PermissionScreen(onGranted: () {
                    setState(() => _cameraGranted = true);
                    Navigator.pop(context);
                    _goToMeasurement();
                  }),
                ),
              );
            }
            return;
          }
          setState(() => _cameraGranted = true);
        }
        _goToMeasurement();
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00B4BC),
              Color(0xFF0D5C6A),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.teal.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Measure Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Place finger on camera • 30 seconds',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastReadings() {
    final e = _latest!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LAST READING',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 1,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ).then((_) => _loadLatest()),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: const Text(
                'See All →',
                style: TextStyle(fontSize: 13, color: AppTheme.teal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BPCard(
          systolic: e.systolicBP,
          diastolic: e.diastolicBP,
          status: _bpClass(e.systolicBP, e.diastolicBP),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: VitalCard(
                label: 'HEART RATE',
                value: e.heartRate.toInt().toString(),
                unit: 'BPM',
                status: _hrClass(e.heartRate),
                icon: Icons.monitor_heart_outlined,
                accentColor: AppTheme.coral,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: VitalCard(
                label: 'SpO2',
                value: e.spo2.toStringAsFixed(0),
                unit: '%',
                status: e.spo2 >= 95 ? 'Normal' : 'Low',
                icon: Icons.air,
                accentColor: AppTheme.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: VitalCard(
                label: 'HRV RMSSD',
                value: e.rmssd.toInt().toString(),
                unit: 'ms',
                status: e.rmssd > 50
                    ? 'Good'
                    : e.rmssd > 20
                        ? 'Moderate'
                        : 'Low',
                icon: Icons.show_chart,
                accentColor: AppTheme.gold,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: VitalCard(
                label: 'HRV SDNN',
                value: e.sdnn.toInt().toString(),
                unit: 'ms',
                status: e.sdnn > 50 ? 'Good' : 'Low',
                icon: Icons.stacked_line_chart,
                accentColor: AppTheme.tealLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickGuide() {
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
            'WHAT DOES THIS MEASURE?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.teal,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _guideRow('❤️', 'Heart Rate',
              'How fast your heart beats per minute'),
          _guideRow(
              '🩸', 'Blood Pressure', 'Estimated pressure in your arteries'),
          _guideRow('🫁', 'SpO2', 'Oxygen level in your blood'),
          _guideRow('📊', 'HRV', 'Variation between heartbeats — stress indicator'),
        ],
      ),
    );
  }

  Widget _guideRow(String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
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

  void _goToMeasurement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeasurementScreen(cameras: widget.cameras),
      ),
    ).then((_) => _loadLatest());
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _bpClass(double s, double d) {
    if (s < 120 && d < 80) return 'Normal';
    if (s < 130 && d < 80) return 'Elevated';
    if (s < 140 || d < 90) return 'High Stage 1';
    return 'High Stage 2';
  }

  String _hrClass(double hr) {
    if (hr < 60) return 'Low';
    if (hr <= 100) return 'Normal';
    return 'High';
  }
}
