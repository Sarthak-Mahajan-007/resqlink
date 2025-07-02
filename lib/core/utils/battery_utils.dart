import 'dart:io';
import 'package:flutter/services.dart';

// Battery optimization helpers
class BatteryUtils {
  static const MethodChannel _channel = MethodChannel('battery_channel');

  // Get current battery level (0-100)
  static Future<int> getBatteryLevel() async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('battery_channel');
        final int result = await platform.invokeMethod('getBatteryLevel');
        return result;
      } else if (Platform.isIOS) {
        const platform = MethodChannel('battery_channel');
        final int result = await platform.invokeMethod('getBatteryLevel');
        return result;
      }
      return 100; // Default for other platforms
    } catch (e) {
      print('Error getting battery level: $e');
      return 100;
    }
  }

  // Check if device is charging
  static Future<bool> isCharging() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        const platform = MethodChannel('battery_channel');
        final bool result = await platform.invokeMethod('isCharging');
        return result;
      }
      return false;
    } catch (e) {
      print('Error checking charging status: $e');
      return false;
    }
  }

  // Get battery optimization recommendations
  static List<String> getBatteryOptimizationTips(int batteryLevel) {
    final tips = <String>[];
    
    if (batteryLevel <= 20) {
      tips.add('Battery critically low! Enable power saving mode.');
      tips.add('Reduce BLE scan frequency to save power.');
      tips.add('Disable non-essential features.');
      tips.add('Consider charging your device.');
    } else if (batteryLevel <= 50) {
      tips.add('Battery level moderate. Consider power saving options.');
      tips.add('Reduce screen brightness.');
      tips.add('Close unnecessary apps.');
    } else if (batteryLevel <= 80) {
      tips.add('Battery level good. Normal operation recommended.');
    }
    
    return tips;
  }

  // Get recommended BLE scan interval based on battery level
  static Duration getRecommendedScanInterval(int batteryLevel) {
    if (batteryLevel <= 20) {
      return const Duration(seconds: 30); // Very conservative
    } else if (batteryLevel <= 50) {
      return const Duration(seconds: 15); // Conservative
    } else {
      return const Duration(seconds: 5); // Normal
    }
  }

  // Get recommended BLE advertising interval based on battery level
  static Duration getRecommendedAdvertisingInterval(int batteryLevel) {
    if (batteryLevel <= 20) {
      return const Duration(seconds: 60); // Very conservative
    } else if (batteryLevel <= 50) {
      return const Duration(seconds: 30); // Conservative
    } else {
      return const Duration(seconds: 10); // Normal
    }
  }

  // Check if power saving mode should be enabled
  static bool shouldEnablePowerSaving(int batteryLevel) {
    return batteryLevel <= 20;
  }

  // Get battery status description
  static String getBatteryStatusDescription(int batteryLevel) {
    if (batteryLevel <= 10) {
      return 'Critical';
    } else if (batteryLevel <= 20) {
      return 'Very Low';
    } else if (batteryLevel <= 50) {
      return 'Low';
    } else if (batteryLevel <= 80) {
      return 'Good';
    } else {
      return 'Excellent';
    }
  }

  // Get battery status color
  static int getBatteryStatusColor(int batteryLevel) {
    if (batteryLevel <= 20) {
      return 0xFFFF0000; // Red
    } else if (batteryLevel <= 50) {
      return 0xFFFFA500; // Orange
    } else {
      return 0xFF00FF00; // Green
    }
  }
} 