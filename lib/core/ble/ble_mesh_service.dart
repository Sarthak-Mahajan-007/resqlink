import 'dart:async';
import 'dart:convert';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/sos_message.dart';
import 'ble_message.dart';
import '../models/group.dart';
import '../models/user_profile.dart';

// BLE mesh logic: advertising, scanning, relay
class BleMeshService {
  // BLE Peripheral for advertising
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  final Set<String> _seenMessages = {};
  StreamSubscription? _scanSubscription;
  bool _isAdvertising = false;
  
  // Group-related callbacks
  Function(BleMessage)? _onGroupMessage;
  Function(BleMessage)? _onGroupSos;
  Function(BleMessage)? _onGroupStatus;
  Function(BleMessage)? _onGroupResource;
  
  // User profile for message sending
  UserProfile? _userProfile;
  
  // Active groups for filtering messages
  List<String> _activeGroupIds = [];

  // Set user profile and active groups
  void setUserProfile(UserProfile profile, List<String> activeGroupIds) {
    _userProfile = profile;
    _activeGroupIds = activeGroupIds;
  }

  // Set callbacks for group messages
  void setGroupCallbacks({
    Function(BleMessage)? onGroupMessage,
    Function(BleMessage)? onGroupSos,
    Function(BleMessage)? onGroupStatus,
    Function(BleMessage)? onGroupResource,
  }) {
    _onGroupMessage = onGroupMessage;
    _onGroupSos = onGroupSos;
    _onGroupStatus = onGroupStatus;
    _onGroupResource = onGroupResource;
  }

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
      print('Started advertising SOS: ${sos.id}');
    } catch (e) {
      print('Error advertising SOS: $e');
    }
  }

  // Start advertising a BLE message (SOS, Group, Resource, etc.)
  Future<void> advertiseMessage(BleMessage message) async {
    try {
      final payload = message.toPayload();
      // Ensure payload fits in BLE advertising packet (31 bytes limit)
      if (payload.length > 25) { // Leave some room for encoding overhead
        print('Warning: Message payload too large for BLE advertising: ${payload.length} bytes');
        // Truncate or compress if needed
      }
      
      final manufacturerData = utf8.encode(payload);
      final advertisement = AdvertiseData(
        includeDeviceName: false,
        manufacturerId: 0xFFFF, // Custom manufacturer ID
        manufacturerData: manufacturerData,
      );
      await _blePeripheral.start(advertiseData: advertisement);
      _isAdvertising = true;
      print('Started advertising ${message.type}: ${message.id}');
    } catch (e) {
      print('Error advertising message: $e');
    }
  }

  // Send group SOS message
  Future<void> sendGroupSos(String groupId, String message, {double? lat, double? lng}) async {
    if (_userProfile == null) {
      print('Error: User profile not set for group SOS');
      return;
    }
    
    final groupSos = BleMessage.groupSos(
      senderId: _userProfile!.id,
      groupId: groupId,
      message: message,
      latitude: lat,
      longitude: lng,
    );
    
    await advertiseMessage(groupSos);
  }

  // Send group status update
  Future<void> sendGroupStatus(String groupId, String status, {double? lat, double? lng, String? customMessage}) async {
    if (_userProfile == null) {
      print('Error: User profile not set for group status');
      return;
    }
    
    final statusMessage = BleMessage.groupStatus(
      senderId: _userProfile!.id,
      groupId: groupId,
      status: status,
      latitude: lat,
      longitude: lng,
      customMessage: customMessage,
    );
    
    await advertiseMessage(statusMessage);
  }

  // Send group resource message
  Future<void> sendGroupResource(String groupId, String resourceType, String resourceName, {String? description, double? lat, double? lng}) async {
    if (_userProfile == null) {
      print('Error: User profile not set for group resource');
      return;
    }
    
    final resourceMessage = BleMessage.groupResource(
      senderId: _userProfile!.id,
      groupId: groupId,
      resourceType: resourceType,
      resourceName: resourceName,
      description: description,
      latitude: lat,
      longitude: lng,
    );
    
    await advertiseMessage(resourceMessage);
  }

  // Send group health check
  Future<void> sendGroupHealthCheck(String groupId, {bool isAlive = true, String? status}) async {
    if (_userProfile == null) {
      print('Error: User profile not set for group health check');
      return;
    }
    
    final healthMessage = BleMessage.groupHealthCheck(
      senderId: _userProfile!.id,
      groupId: groupId,
      isAlive: isAlive,
      status: status,
    );
    
    await advertiseMessage(healthMessage);
  }

  // Start scanning for SOS messages and group messages
  Future<void> startScanning(Function(SosMessage) onSosMessage) async {
    try {
      await FlutterBluePlus.startScan(
        // No filter, scan for all
        timeout: const Duration(seconds: 0), // Continuous scan
      );
      _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
        for (final result in results) {
          _processScanResult(result, onSosMessage);
        }
      });
      print('Started scanning for SOS and group messages');
    } catch (e) {
      print('Error starting scan: $e');
    }
  }

  // Process scan result and extract messages
  void _processScanResult(ScanResult result, Function(SosMessage) onSosMessage) {
    try {
      final manufacturerData = result.advertisementData.manufacturerData;
      if (manufacturerData.isEmpty) return;
      final data = manufacturerData[0xFFFF];
      if (data == null) return;
      final payload = utf8.decode(data);
      
      // Try to parse as BLE message first
      try {
        final bleMessage = BleMessage.fromPayload(payload);
        _handleBleMessage(bleMessage);
        return;
      } catch (e) {
        // If not a BLE message, try as legacy SOS message
      }
      
      // Legacy SOS message handling
      final sos = SosMessage.fromPayload(payload);
      if (!_seenMessages.contains(sos.id)) {
        _seenMessages.add(sos.id);
        onSosMessage(sos);
        if (sos.ttl > 0) {
          relaySos(sos);
        }
      }
    } catch (e) {
      print('Error processing scan result: $e');
    }
  }

  // Handle BLE messages (group, resource, etc.)
  void _handleBleMessage(BleMessage message) {
    // Check if message is expired
    if (message.isExpired) {
      print('Ignoring expired message: ${message.id}');
      return;
    }
    
    // Check if we've seen this message before
    if (_seenMessages.contains(message.id)) {
      return;
    }
    
    _seenMessages.add(message.id);
    
    // Handle different message types
    switch (message.type) {
      case 'GROUP_SOS':
        _handleGroupSos(message);
        break;
      case 'GROUP_STATUS':
        _handleGroupStatus(message);
        break;
      case 'GROUP_RESOURCE':
        _handleGroupResource(message);
        break;
      case 'GROUP_HEALTH':
        _handleGroupHealth(message);
        break;
      default:
        print('Unknown message type: ${message.type}');
    }
    
    // Relay message if TTL > 0 and it's for one of our groups
    if (message.ttl > 0 && _shouldRelayMessage(message)) {
      relayMessage(message);
    }
  }

  // Handle group SOS messages
  void _handleGroupSos(BleMessage message) {
    print('Received group SOS: ${message.payload['message']} from group ${message.groupId}');
    _onGroupSos?.call(message);
    _onGroupMessage?.call(message);
  }

  // Handle group status messages
  void _handleGroupStatus(BleMessage message) {
    print('Received group status: ${message.payload['status']} from group ${message.groupId}');
    _onGroupStatus?.call(message);
    _onGroupMessage?.call(message);
  }

  // Handle group resource messages
  void _handleGroupResource(BleMessage message) {
    print('Received group resource: ${message.payload['resourceType']} ${message.payload['resourceName']} from group ${message.groupId}');
    _onGroupResource?.call(message);
    _onGroupMessage?.call(message);
  }

  // Handle group health check messages
  void _handleGroupHealth(BleMessage message) {
    print('Received group health check: ${message.payload['isAlive']} from group ${message.groupId}');
    // Update member status in local storage
    // This could trigger UI updates
  }

  // Determine if we should relay a message
  bool _shouldRelayMessage(BleMessage message) {
    // Always relay SOS messages
    if (message.type == 'GROUP_SOS') return true;
    
    // Relay group messages if we're a member of that group
    if (message.groupId != null && _activeGroupIds.contains(message.groupId)) {
      return true;
    }
    
    return false;
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
        print('Relayed SOS: ${sos.id} (TTL: ${relayedSos.ttl})');
      }
    } catch (e) {
      print('Error relaying SOS: $e');
    }
  }

  // Relay BLE message with decremented TTL
  Future<void> relayMessage(BleMessage message) async {
    try {
      final relayedMessage = BleMessage(
        id: message.id,
        type: message.type,
        senderId: message.senderId,
        timestamp: message.timestamp,
        payload: message.payload,
        ttl: message.ttl - 1,
      );
      
      if (relayedMessage.ttl > 0) {
        await advertiseMessage(relayedMessage);
        print('Relayed ${message.type}: ${message.id} (TTL: ${relayedMessage.ttl})');
      }
    } catch (e) {
      print('Error relaying message: $e');
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
      print('Error stopping BLE: $e');
    }
  }

  // Get current advertising status
  bool get isAdvertising => _isAdvertising;

  // Clear seen messages cache (useful for testing)
  void clearMessageCache() {
    _seenMessages.clear();
  }
} 