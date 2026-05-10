import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? fcmToken;
  final List<EmergencyContact> emergencyContacts;
  final bool isVerified;
  final Map<String, dynamic>? lastLocation;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.fcmToken,
    required this.emergencyContacts,
    required this.isVerified,
    this.lastLocation,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      fcmToken: data['fcmToken'],
      emergencyContacts: (data['emergencyContacts'] as List? ?? [])
          .map((c) => EmergencyContact.fromJson(c))
          .toList(),
      isVerified: data['isVerified'] ?? false,
      lastLocation: data['lastLocation'],
    );
  }

  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId == null) return null;
    
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }
}

class EmergencyContact {
  final String name;
  final String phone;
  final String? fcmToken;

  EmergencyContact({required this.name, required this.phone, this.fcmToken});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'],
      phone: json['phone'],
      fcmToken: json['fcmToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'fcmToken': fcmToken,
    };
  }
}