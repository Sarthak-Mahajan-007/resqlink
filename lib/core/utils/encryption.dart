import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

// AES encryption/decryption helpers
class EncryptionUtils {
  static const String _defaultKey = 'resQlinkSecretKey2024!@#';
  
  // Generate a random encryption key
  static String generateKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(32, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  // Encrypt data with AES-256
  static String encrypt(String data, {String? key}) {
    try {
      final encryptionKey = key ?? _defaultKey;
      final keyBytes = utf8.encode(encryptionKey.padRight(32, '0').substring(0, 32));
      final iv = IV.fromLength(16);
      
      final encrypter = Encrypter(AES(Key(keyBytes)));
      final encrypted = encrypter.encrypt(data, iv: iv);
      
      // Combine IV and encrypted data
      final combined = iv.bytes + encrypted.bytes;
      return base64.encode(combined);
    } catch (e) {
      print('Encryption error: $e');
      return data; // Return original data if encryption fails
    }
  }

  // Decrypt data with AES-256
  static String decrypt(String encryptedData, {String? key}) {
    try {
      final encryptionKey = key ?? _defaultKey;
      final keyBytes = utf8.encode(encryptionKey.padRight(32, '0').substring(0, 32));
      
      final combined = base64.decode(encryptedData);
      final iv = IV(combined.sublist(0, 16));
      final encrypted = Encrypted(combined.sublist(16));
      
      final encrypter = Encrypter(AES(Key(keyBytes)));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('Decryption error: $e');
      return encryptedData; // Return original data if decryption fails
    }
  }

  // Encrypt JSON data
  static String encryptJson(Map<String, dynamic> data, {String? key}) {
    final jsonString = jsonEncode(data);
    return encrypt(jsonString, key: key);
  }

  // Decrypt JSON data
  static Map<String, dynamic>? decryptJson(String encryptedData, {String? key}) {
    try {
      final decrypted = decrypt(encryptedData, key: key);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      print('JSON decryption error: $e');
      return null;
    }
  }

  // Hash data for integrity checking
  static String hash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verify data integrity
  static bool verifyHash(String data, String expectedHash) {
    final actualHash = hash(data);
    return actualHash == expectedHash;
  }
} 