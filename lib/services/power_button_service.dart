import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alert_service.dart';
import '../models/user_model.dart';

class PowerButtonService {
  static const platform = MethodChannel('power_button_channel');
  Timer? _debounceTimer;
  int _pressCount = 0;
  DateTime? _lastPressTime;
  bool _isListening = false;
  
  static final PowerButtonService _instance = PowerButtonService._internal();
  factory PowerButtonService() => _instance;
  PowerButtonService._internal();

  void startListening() {
    if (_isListening) return;
    
    _isListening = true;
    platform.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'power_button_pressed':
        _handlePowerButtonPress();
        break;
    }
  }

  void _handlePowerButtonPress() {
    final now = DateTime.now();
    
    // Reset if more than 1 second between presses
    if (_lastPressTime == null || now.difference(_lastPressTime!).inSeconds > 1) {
      _pressCount = 1;
    } else {
      _pressCount++;
    }
    
    _lastPressTime = now;
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Set new timer for debounce (1.5 seconds)
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _processPressCount(_pressCount);
      _pressCount = 0;
    });
  }

  Future<void> _processPressCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('emergency_enabled') ?? false;
    
    if (!isEnabled) return;
    
    switch (count) {
      case 2:
        await AlertService.sendAlertToContacts();
        break;
      case >= 5:
        await AlertService.sendCriticalAlert();
        break;
    }
  }
}