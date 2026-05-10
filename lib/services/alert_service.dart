import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:telephony/telephony.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import 'location_service.dart';
import '../utils/crypto_utils.dart';

class AlertService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // static final Telephony _telephony = Telephony.instance;
  
  static Future<void> sendAlertToContacts() async {
    final user = await UserModel.getCurrentUser();
    final location = await LocationService.getCurrentLocation();
    final trackingLink = await LocationService.generateLiveTrackingLink();
    
    final alertData = {
      'userId': user!.id,
      'name': user!.name,
      'location': {
        'lat': location.latitude,
        'lng': location.longitude,
      },
      'trackingLink': trackingLink,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'contact_alert',
      'status': 'active',
    };
    
    // Send to emergency contacts
    await _sendToEmergencyContacts(user!, alertData);
    
    // Save to Firestore
    await _firestore.collection('alerts').add(alertData);
  }

  static Future<void> sendCriticalAlert() async {
    final user = await UserModel.getCurrentUser();
    final location = await LocationService.getCurrentLocation();
    final nearestPolice = await _findNearestPoliceStation(location);
    final trackingLink = await LocationService.generateLiveTrackingLink();
    
    final alertData = {
      'userId': user!.id,
      'name': user!.name,
      'location': {
        'lat': location.latitude,
        'lng': location.longitude,
      },
      'trackingLink': trackingLink,
      'nearestPolice': nearestPolice,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'critical_alert',
      'status': 'active',
    };
    
    // Send to all responders
    await _sendToEmergencyContacts(user!, alertData);
    await _sendToNearbyHelpers(location, alertData);
    await _sendToPolice(nearestPolice, alertData);
    
    // Save to Firestore
    await _firestore.collection('alerts').add(alertData);
    
    // Start continuous location sharing
    LocationService.startContinuousTracking(user!.id);
  }

  static Future<void> _sendToEmergencyContacts(UserModel user, Map<String, dynamic> alertData) async {
    final contacts = user.emergencyContacts;
    
    for (var contact in contacts) {
      // Send SMS
      final message = '''
🚨 EMERGENCY ALERT from ${user.name} 🚨
📍 Location: ${alertData['location']['lat']}, ${alertData['location']['lng']}
🔗 Live Tracking: ${alertData['trackingLink']}
⏰ Time: ${DateTime.now()}
      ''';
      
      // await _telephony.sendSms(to: contact.phone, message: message);
      
      // Send Push Notification
      await _sendPushNotification(contact.fcmToken, 'Emergency Alert', message);
    }
  }

  static Future<void> _sendToNearbyHelpers(Position location, Map<String, dynamic> alertData) async {
    final helpersSnapshot = await _firestore
        .collection('users')
        .where('isVerified', isEqualTo: true)
        .where('lastLocation.lat', isGreaterThanOrEqualTo: location.latitude - 0.01)
        .where('lastLocation.lat', isLessThanOrEqualTo: location.latitude + 0.01)
        .get();
    
    for (var helperDoc in helpersSnapshot.docs) {
      final helperToken = helperDoc['fcmToken'];
      await _sendPushNotification(
        helperToken,
        'Help Needed Nearby!',
        'Someone needs help within 1km. Check app for details.',
      );
    }
  }

  static Future<Map<String, dynamic>> _findNearestPoliceStation(Position location) async {
    // Google Places API integration for nearest police station
    // For demo, returning mock data
    return {
      'name': 'Local Police Station',
      'phone': '+91-100',
      'address': 'Nearest Police Station',
    };
  }

  static Future<void> _sendPushNotification(String? token, String title, String body) async {
    if (token == null) return;
    
    await _messaging.sendMessage(
      to: token,
      data: {'title': title, 'body': body},
      // android: const AndroidMessage(
      //   priority: AndroidMessagePriority.high,
      // ),
    );
  }

  static Future<void> _sendToPolice(Map<String, dynamic> police, Map<String, dynamic> alertData) async {
    final message = '''
🚨 CRITICAL EMERGENCY 🚨
Name: ${alertData['name']}
Location: ${alertData['location']['lat']}, ${alertData['location']['lng']}
Live Tracking: ${alertData['trackingLink']}
    ''';
    
    // await _telephony.sendSms(to: police['phone'], message: message);
  }
}