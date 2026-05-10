import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<bool> requestPhonePermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  static Future<bool> checkAllPermissions() async {
    final location = await Permission.location.status;
    final sms = await Permission.sms.status;
    final phone = await Permission.phone.status;
    
    return location.isGranted && sms.isGranted && phone.isGranted;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}