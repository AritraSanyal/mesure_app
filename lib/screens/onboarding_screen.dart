import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;

  static const _steps = [
    _OnboardingStep(
      emoji: '👋',
      title: 'Welcome to Mesure',
      body:
          'Mesure helps you check your heart rate, blood pressure, and oxygen level — all from your phone camera.',
      color: AppTheme.teal,
    ),
    _OnboardingStep(
      emoji: '☝️',
      title: 'Place Your Finger',
      body:
          'Gently rest your fingertip over the back camera lens. The flash light will shine through your finger.',
      color: AppTheme.coral,
    ),
    _OnboardingStep(
      emoji: '🤫',
      title: 'Stay Still',
      body:
          'Keep your finger still and press gently. Moving too much will affect the reading. It only takes 30 seconds.',
      color: AppTheme.gold,
    ),
    _OnboardingStep(
      emoji: '📊',
      title: 'See Your Results',
      body:
          'After 30 seconds you\'ll see your readings. Results are saved so you can track changes over time.',
      color: AppTheme.green,
    ),
    _OnboardingStep(
      emoji: '⚠️',
      title: 'Important Notice',
      body:
          'Mesure is a wellness tool only. It is NOT a medical device and cannot replace a doctor\'s advice. Always consult a healthcare professional for medical concerns.',
      color: AppTheme.textSecondary,
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _steps.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text(
                  'Skip',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _StepPage(step: _steps[i]),
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? _steps[_page].color
                        : AppTheme.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Next / Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _steps[_page].color,
                  foregroundColor: AppTheme.navy,
                ),
                child: Text(
                  _page == _steps.length - 1 ? "Let's Start" : 'Next',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  final _OnboardingStep step;
  const _StepPage({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(step.emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 32),
          Text(
            step.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: step.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            step.body,
            style: const TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  final String emoji;
  final String title;
  final String body;
  final Color color;
  const _OnboardingStep({
    required this.emoji,
    required this.title,
    required this.body,
    required this.color,
  });
}
