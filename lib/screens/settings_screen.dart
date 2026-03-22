import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/history_service.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _haptics = true;
  bool _simpleView = false; // Simplified "big number" mode for cognitive accessibility
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _haptics = p.getBool('haptics') ?? true;
      _simpleView = p.getBool('simple_view') ?? false;
      _userName = p.getString('user_name') ?? '';
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('haptics', _haptics);
    await p.setBool('simple_view', _simpleView);
    await p.setString('user_name', _userName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader('PROFILE'),
            _card([
              Padding(
                padding: const EdgeInsets.all(4),
                child: TextField(
                  controller: TextEditingController(text: _userName),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Your Name (optional)',
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.teal),
                  ),
                  onChanged: (v) {
                    _userName = v;
                    _save();
                  },
                ),
              ),
            ]),

            const SizedBox(height: 20),
            _sectionHeader('ACCESSIBILITY'),
            _card([
              _toggle(
                icon: Icons.remove_red_eye_outlined,
                title: 'Simple View',
                subtitle: 'Large numbers and emoji status only',
                value: _simpleView,
                onChanged: (v) {
                  setState(() => _simpleView = v);
                  _save();
                },
              ),
              _divider(),
              _toggle(
                icon: Icons.vibration,
                title: 'Haptic Feedback',
                subtitle: 'Vibrate on measurement start/end',
                value: _haptics,
                onChanged: (v) {
                  setState(() => _haptics = v);
                  _save();
                },
              ),
            ]),

            const SizedBox(height: 20),
            _sectionHeader('DATA'),
            _card([
              _action(
                icon: Icons.delete_outline,
                iconColor: AppTheme.coral,
                title: 'Clear All History',
                subtitle: 'Remove all saved measurements',
                onTap: _confirmClear,
              ),
            ]),

            const SizedBox(height: 20),
            _sectionHeader('ABOUT'),
            _card([
              _info('App Version', '1.0.0'),
              _divider(),
              _info('Measurement Duration', '30 seconds'),
              _divider(),
              _info('Max History Entries', '100 readings'),
              _divider(),
              _info('BP Method', 'PPG feature regression'),
              _divider(),
              _info('HRV Methods', 'SDNN, RMSSD, pNN50, LF/HF'),
              _divider(),
              _info('SpO2 Method', 'Ratio-of-Ratios (R/B channels)'),
            ]),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.navyLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Text(
                '⚠️  This app is for wellness monitoring ONLY. It is not a medical device and has not been cleared by any health authority. Do not use it to diagnose or treat any medical condition. Always consult a qualified healthcare professional.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.teal,
            letterSpacing: 1,
          ),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(children: children),
      );

  Widget _divider() => Divider(
        height: 1,
        color: AppTheme.divider,
        indent: 16,
        endIndent: 16,
      );

  Widget _toggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.teal, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, color: AppTheme.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.teal,
            ),
          ],
        ),
      );

  Widget _action({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, color: AppTheme.textPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
            ],
          ),
        ),
      );

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Clear All History?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete All',
                  style: TextStyle(color: AppTheme.coral))),
        ],
      ),
    );
    if (ok == true) {
      await HistoryService().clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History cleared'),
            backgroundColor: AppTheme.teal,
          ),
        );
      }
    }
  }
}
