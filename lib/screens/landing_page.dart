import 'package:flutter/material.dart';
import 'camera_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  void _navigateToCamera(BuildContext context, String measurementType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(measurementType: measurementType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Top - Last Measurement
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Last Measurement",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "HR: 78 bpm\nBP: 120/80 mmHg\nHRV: 52 ms",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Top Right - Profile Button
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.person, size: 30, color: Colors.white),
                onPressed: () {
                  // Future: Navigate to profile page
                },
              ),
            ),

            // Center Buttons
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOptionButton(
                    context,
                    label: 'Check Heart Rate',
                    icon: Icons.favorite,
                    color: Colors.redAccent,
                    type: 'Heart Rate',
                  ),
                  const SizedBox(height: 20),
                  _buildOptionButton(
                    context,
                    label: 'Check HRV',
                    icon: Icons.insights,
                    color: Colors.greenAccent,
                    type: 'HRV',
                  ),
                  const SizedBox(height: 20),
                  _buildOptionButton(
                    context,
                    label: 'Check Blood Pressure',
                    icon: Icons.bloodtype,
                    color: Colors.blueAccent,
                    type: 'Blood Pressure',
                  ),
                ],
              ),
            ),

            // Bottom - Start Camera Button
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _navigateToCamera(context, 'Heart Rate'),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 32,
                      color: Colors.white,
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

  Widget _buildOptionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    return ElevatedButton.icon(
      onPressed: () => _navigateToCamera(context, type),
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
