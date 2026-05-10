import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/power_button_service.dart';
import '../utils/permissions.dart';
import 'home_screen.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animation
    _animationController.forward();

    // Initialize services
    await _initializeServices();
    
    // Check permissions and delay navigation
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      _navigateToHome();
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Request permissions
      await Permissions.checkAllPermissions();
      
      // Initialize power button service
      PowerButtonService().startListening();
      
      // Load user preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_initialized', true);
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Splash screen initialization error: $e');
    }
  }

  Future<void> _navigateToHome() async {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main Logo Animation
                Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withOpacity(0.5),
                        blurRadius: 50,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Lottie.asset(
                      'assets/animations/splash-shield.json',
                      height: 250,
                      width: 250,
                      fit: BoxFit.cover,
                      repeat: true,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // App Name
                const Text(
                  'iGoSafely',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 4),
                        blurRadius: 10,
                        color: Color(0xFF000000),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Tagline
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 1000),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                  child: const Text(
                    'Your Silent Guardian',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Loading Indicator
                if (!_isInitialized)
                  Column(
                    children: [
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Initializing Safety Services...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      const Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ready to Protect You',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 30),
                
                // Power instructions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.power_settings_new, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '2x Power = Contacts | 5x Power = Police',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}