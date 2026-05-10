import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static final StreamController<Position> _positionController = StreamController<Position>.broadcast();
  static Stream<Position> get positionStream => _positionController.stream;
  static bool _isTracking = false;
  static Timer? _trackingTimer;

  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<String> generateLiveTrackingLink() async {
    final location = await getCurrentLocation();
    final encodedLocation = base64Encode(utf8.encode('$location.latitude,${location.longitude}'));
    return 'https://maps.google.com/?q=$encodedLocation';
  }

  static void startContinuousTracking(String userId) {
    if (_isTracking) return;
    
    _isTracking = true;
    _trackingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final position = await getCurrentLocation();
        _positionController.add(position);
        
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'lastLocation': {
            'lat': position.latitude,
            'lng': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
          }
        });
      } catch (e) {
        print('Location tracking error: $e');
      }
    });
  }

  static void stopTracking() {
    _isTracking = false;
    _trackingTimer?.cancel();
  }

  static void startLocationTracking() {
    // Simple location tracking without Firestore updates
    if (_isTracking) return;
    
    _isTracking = true;
    _trackingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final position = await getCurrentLocation();
        _positionController.add(position);
      } catch (e) {
        print('Location tracking error: $e');
      }
    });
  }
}