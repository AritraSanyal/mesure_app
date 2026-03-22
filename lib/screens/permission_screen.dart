import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_theme.dart';

/// Shown the first time before a measurement to request camera permission
class PermissionScreen extends StatefulWidget {
  final VoidCallback onGranted;
  const PermissionScreen({super.key, required this.onGranted});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _checking = false;

  Future<void> _requestPermission() async {
    setState(() => _checking = true);

    final status = await Permission.camera.request();

    setState(() => _checking = false);

    if (status.isGranted) {
      widget.onGranted();
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.card,
            title: const Text('Camera Permission Required',
                style: TextStyle(color: AppTheme.textPrimary)),
            content: const Text(
              'Camera access was permanently denied. Please enable it in your device settings to use Mesure.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Open Settings',
                    style: TextStyle(color: AppTheme.teal)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('📷', style: TextStyle(fontSize: 64), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Text(
                'Camera Access Needed',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Mesure uses your phone\'s camera and flash to measure your heart rate and blood pressure by detecting tiny color changes in your fingertip.\n\nNo photos or videos are ever stored.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _checking ? null : _requestPermission,
                child: _checking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.navy,
                        ),
                      )
                    : const Text('Allow Camera Access'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
