import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoUtils {
  static const String _key = 'iGoSafelySecretKey32'; // 32 bytes for AES
  static const String _iv = 'iGoSafelyIV16Bytes';   // 16 bytes for IV

  static encrypt.AES _getAES() {
    final key = encrypt.Key.fromUtf8(_key);
    final iv = encrypt.IV.fromUtf8(_iv);
    return encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7');
  }

  static String encryptLocation(double lat, double lng) {
    final aes = _getAES();
    final data = '$lat,$lng';
    final encrypter = encrypt.Encrypter(aes);
    final encrypted = encrypter.encrypt(data, iv: encrypt.IV.fromUtf8(_iv));
    return encrypted.base64;
  }

  static Map<String, double> decryptLocation(String encryptedData) {
    final aes = _getAES();
    final encrypter = encrypt.Encrypter(aes);
    final decrypted = encrypter.decrypt64(encryptedData, iv: encrypt.IV.fromUtf8(_iv));
    final parts = decrypted.split(',');
    return {
      'lat': double.parse(parts[0]),
      'lng': double.parse(parts[1]),
    };
  }

  static String encryptAlertData(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final aes = _getAES();
    final encrypter = encrypt.Encrypter(aes);
    final encrypted = encrypter.encrypt(jsonString, iv: encrypt.IV.fromUtf8(_iv));
    return encrypted.base64;
  }

  static Map<String, dynamic> decryptAlertData(String encryptedData) {
    final aes = _getAES();
    final encrypter = encrypt.Encrypter(aes);
    final decryptedJson = encrypter.decrypt64(encryptedData, iv: encrypt.IV.fromUtf8(_iv));
    return jsonDecode(decryptedJson);
  }
}