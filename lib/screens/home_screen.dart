import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../services/alert_service.dart';
import '../widgets/contacts_management.dart';
import '../widgets/settings_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _emergencyEnabled = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyEnabled = prefs.getBool('emergency_enabled') ?? false;
    });
  }

  Future<void> _toggleEmergency(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('emergency_enabled', enabled);
    setState(() => _emergencyEnabled = enabled);
    
    if (enabled) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE91E63), Color(0xFFFF4081)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'iGoSafely',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your Safety, Our Priority',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Emergency Status
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/animations/safety-shield.json',
                        controller: _animationController,
                        height: 200,
                        onLoaded: (composition) {
                          _animationController.forward();
                        },
                      ),
                      const SizedBox(height: 30),
                      Text(
                        _emergencyEnabled ? 'EMERGENCY MODE\nACTIVE' : 'EMERGENCY MODE\nINACTIVE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _emergencyEnabled ? Colors.white : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Toggle Button
                      GestureDetector(
                        onTap: () => _toggleEmergency(!_emergencyEnabled),
                        child: Container(
                          width: 200,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(35),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _emergencyEnabled ? 'DISABLE' : 'ENABLE',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _emergencyEnabled ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Quick Actions
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickAction(
                      icon: Icons.contacts,
                      label: 'Contacts',
                      onTap: () => _showContactsDialog(),
                    ),
                    _buildQuickAction(
                      icon: Icons.settings,
                      label: 'Settings',
                      onTap: () => _showSettings(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 30, color: const Color(0xFFE91E63)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showContactsDialog() {
    showDialog(
      context: context,
      builder: (context) => const ContactsManagementDialog(),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }
}