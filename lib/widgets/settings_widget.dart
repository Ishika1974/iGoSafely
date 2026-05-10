import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/permissions.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool _locationEnabled = true;
  bool _smsEnabled = true;
  bool _backgroundService = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locationEnabled = prefs.getBool('location_enabled') ?? true;
      _smsEnabled = prefs.getBool('sms_enabled') ?? true;
      _backgroundService = prefs.getBool('background_service') ?? true;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'location_enabled') _locationEnabled = value;
      if (key == 'sms_enabled') _smsEnabled = value;
      if (key == 'background_service') _backgroundService = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 400, maxWidth: 350),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE91E63),
              ),
            ),
            const SizedBox(height: 30),
            
            // Location Permission
            SwitchListTile(
              title: const Text('Location Access'),
              subtitle: const Text('Required for emergency alerts'),
              value: _locationEnabled,
              activeColor: const Color(0xFFE91E63),
              onChanged: (value) async {
                final granted = await Permissions.requestLocationPermission();
                if (granted) {
                  _updateSetting('location_enabled', value);
                }
              },
            ),
            
            // SMS Permission
            SwitchListTile(
              title: const Text('SMS Alerts'),
              subtitle: const Text('Fallback when internet unavailable'),
              value: _smsEnabled,
              activeColor: const Color(0xFFE91E63),
              onChanged: (value) async {
                final granted = await Permissions.requestSmsPermission();
                if (granted) {
                  _updateSetting('sms_enabled', value);
                }
              },
            ),
            
            // Background Service
            SwitchListTile(
              title: const Text('Background Service'),
              subtitle: const Text('Keep app running 24/7'),
              value: _backgroundService,
              activeColor: const Color(0xFFE91E63),
              onChanged: (value) {
                _updateSetting('background_service', value);
              },
            ),
            
            const Spacer(),
            
            // Status Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Location',
                    Icons.location_on,
                    _locationEnabled ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatusCard(
                    'SMS',
                    Icons.sms,
                    _smsEnabled ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save Settings', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}