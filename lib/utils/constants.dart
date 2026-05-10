import 'package:flutter/material.dart';
class AppConstants {
  static const String appName = 'iGoSafely';
  static const String emergencyPhoneIndia = '100';
  static const double nearbyRadiusKm = 1.0;
  static const int powerPressTimeoutMs = 1500;
  static const int locationUpdateIntervalSec = 10;
  
  static const Color primaryColor = Color(0xFFE91E63);
  static const Color accentColor = Color(0xFFFF4081);
  
  static const List<String> policeStationsIndia = [
    '100', // Emergency Police
    '112', // National Emergency
  ];
}