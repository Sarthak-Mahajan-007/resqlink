import 'dart:async';
import 'dart:convert';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/sos_message.dart';

// BLE mesh logic: advertising, scanning, relay
class BleMeshService {
  // BLE Peripheral for advertising
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  final Set<String> _seenMessages = {};
  StreamSubscription? _scanSubscription;
  bool _isAdvertising = false;

  // Start advertising an SOS message
  Future<void> advertiseSos(SosMessage sos) async {
    try {
      final payload = sos.toPayload();
      // BLE advertising payload is limited, so we use manufacturer data
      final manufacturerData = utf8.encode(payload);
      final advertisement = AdvertiseData(
        includeDeviceName: false,
        manufacturerId: 0xFFFF, // Custom manufacturer ID
        manufacturerData: manufacturerData,
      );
      await _blePeripheral.start(advertiseData: advertisement);
      _isAdvertising = true;
      print('Started advertising SOS: \\${sos.id}');
    } catch (e) {
      print('Error advertising SOS: \\${e}');
    }
  }

  // Start scanning for SOS messages
  Future<void> startScanning(Function(SosMessage) onMessage) async {
    try {
      await FlutterBluePlus.startScan(
        // No filter, scan for all
        timeout: const Duration(seconds: 0), // Continuous scan
      );
      _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
        for (final result in results) {
          _processScanResult(result, onMessage);
        }
      });
      print('Started scanning for SOS messages');
    } catch (e) {
      print('Error starting scan: \\${e}');
    }
  }

  // Process scan result and extract SOS messages
  void _processScanResult(ScanResult result, Function(SosMessage) onMessage) {
    try {
      final manufacturerData = result.advertisementData.manufacturerData;
      if (manufacturerData.isEmpty) return;
      final data = manufacturerData[0xFFFF];
      if (data == null) return;
      final payload = utf8.decode(data);
      final sos = SosMessage.fromPayload(payload);
      if (!_seenMessages.contains(sos.id)) {
        _seenMessages.add(sos.id);
        onMessage(sos);
        if (sos.ttl > 0) {
          relaySos(sos);
        }
      }
    } catch (e) {
      print('Error processing scan result: \\${e}');
    }
  }

  // Relay received SOS message (deduplication, TTL decrement)
  Future<void> relaySos(SosMessage sos) async {
    try {
      final relayedSos = SosMessage(
        id: sos.id,
        timestamp: sos.timestamp,
        latitude: sos.latitude,
        longitude: sos.longitude,
        message: sos.message,
        ttl: sos.ttl - 1,
      );
      if (relayedSos.ttl > 0) {
        await advertiseSos(relayedSos);
        print('Relayed SOS: \\${sos.id} (TTL: \\${relayedSos.ttl})');
      }
    } catch (e) {
      print('Error relaying SOS: \\${e}');
    }
  }

  // Stop all BLE operations
  Future<void> stop() async {
    try {
      if (_isAdvertising) {
        await _blePeripheral.stop();
        _isAdvertising = false;
      }
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      print('Stopped BLE operations');
    } catch (e) {
      print('Error stopping BLE: \\${e}');
    }
  }
} 