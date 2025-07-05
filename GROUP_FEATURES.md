# resQlink Group Features

## Overview

The enhanced group feature in resQlink provides real-time communication and coordination capabilities for families, teams, and communities during emergencies. Groups work entirely offline using BLE mesh networking, ensuring connectivity even when all conventional communication infrastructure is down.

## Key Features

### 1. Real-time Group Communication
- **BLE Mesh Integration**: All group messages are transmitted via BLE mesh network
- **Offline Operation**: Works without internet, cellular, or Wi-Fi
- **Message Relay**: Messages automatically propagate through nearby devices
- **TTL Management**: Messages have configurable time-to-live to prevent infinite relaying

### 2. Group SOS Broadcasting
- **Emergency Alerts**: Send SOS messages to all group members instantly
- **Location Sharing**: Automatically includes GPS coordinates with SOS
- **Priority Handling**: SOS messages have higher TTL and priority
- **Haptic Feedback**: Triggers device vibration for immediate attention

### 3. Member Status Tracking
- **Real-time Status**: Track member status (OK, SOS, HELP, OFFLINE)
- **Location Updates**: Monitor member locations when available
- **Last Seen**: Track when members were last active
- **Online Status**: Show which members are currently online

### 4. Resource Coordination
- **Need Broadcasting**: Request specific resources (water, medicine, shelter, etc.)
- **Offer Broadcasting**: Offer available resources to group members
- **Location-based**: Include location with resource requests/offers
- **Quick Categories**: Predefined resource types for rapid communication

### 5. Health Check-ins
- **Periodic Updates**: Automatic health check messages every 5 minutes
- **Status Verification**: Confirm members are still active and safe
- **Battery Efficient**: Low-power health check messages with minimal TTL

## Group Management

### Creating Groups
1. Navigate to Groups tab
2. Tap "Create Group" button
3. Enter group name and optional description
4. Group is created with you as admin
5. Share group ID or QR code with members

### Joining Groups
1. Navigate to Groups tab
2. Tap "Join Group" button
3. Enter group ID manually or scan QR code
4. Automatically added as member
5. Start receiving group messages

### Group Operations
- **View Members**: See all group members with status and location
- **Send SOS**: Emergency alert to all group members
- **Status Updates**: Send "I'm OK" or custom status messages
- **Resource Requests**: Request specific help or resources
- **Resource Offers**: Offer available resources to group

## Quick Actions Screen

The Group Quick Actions screen provides rapid access to emergency functions:

### Emergency SOS
- **One-tap SOS**: Send emergency alert to all groups instantly
- **Automatic Location**: Includes current GPS coordinates
- **Haptic Feedback**: Device vibration for confirmation
- **Visual Alert**: Red button with emergency icon

### Status Updates
- **I'm OK**: Quick status update to all groups
- **Automatic Location**: Includes current position
- **Green Confirmation**: Visual feedback for safety status

### Help Requests
- **Resource Categories**: Predefined help types (water, first aid, transport, etc.)
- **Custom Descriptions**: Add specific details to requests
- **Location Sharing**: Include location with help requests

### Group Status
- **Member Overview**: View all group members and their status
- **SOS Alerts**: Highlight members who need help
- **Online Count**: Show how many members are active
- **Quick Summary**: Overview of all groups and members

## BLE Message Types

### GROUP_SOS
```json
{
  "type": "GROUP_SOS",
  "groupId": "group123",
  "message": "Emergency SOS - Need immediate help!",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "ttl": 10
}
```

### GROUP_STATUS
```json
{
  "type": "GROUP_STATUS",
  "groupId": "group123",
  "status": "OK",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "message": "I am safe",
  "ttl": 3
}
```

### GROUP_RESOURCE
```json
{
  "type": "GROUP_RESOURCE",
  "groupId": "group123",
  "resourceType": "NEED",
  "resourceName": "Water",
  "description": "Need clean water urgently",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "ttl": 5
}
```

### GROUP_HEALTH
```json
{
  "type": "GROUP_HEALTH",
  "groupId": "group123",
  "isAlive": true,
  "status": "OK",
  "ttl": 2
}
```

## Technical Implementation

### BLE Mesh Integration
- **Message Broadcasting**: Uses BLE advertising packets for message transmission
- **Message Scanning**: Continuously scans for group messages
- **Message Relay**: Automatically rebroadcasts messages with decremented TTL
- **Deduplication**: Prevents message loops using message ID tracking

### Group Manager
- **Centralized Management**: Handles all group operations
- **BLE Integration**: Manages BLE mesh service for group communication
- **Local Storage**: Maintains group data locally for offline operation
- **Supabase Sync**: Syncs with cloud when internet is available

### Message Handling
- **Type-based Routing**: Different handlers for different message types
- **Group Filtering**: Only processes messages for user's groups
- **Status Updates**: Automatically updates member status from messages
- **UI Notifications**: Triggers UI updates for real-time feedback

## Usage Scenarios

### Family Emergency
1. **Create Family Group**: Set up group with family members
2. **Share Group ID**: Share QR code or ID with family
3. **Emergency SOS**: One tap sends SOS to all family members
4. **Status Updates**: Family can confirm they're safe
5. **Resource Coordination**: Request or offer help within family

### Community Response
1. **Join Community Group**: Connect with local community
2. **Monitor Alerts**: Receive SOS and help requests
3. **Offer Assistance**: Respond to resource needs
4. **Coordinate Response**: Work together during emergencies

### Team Operations
1. **Create Team Group**: Set up group for work team
2. **Status Tracking**: Monitor team member locations and status
3. **Resource Sharing**: Coordinate equipment and supplies
4. **Emergency Response**: Rapid team communication during incidents

## Privacy and Security

### Data Protection
- **Local Storage**: All group data stored locally on device
- **Encrypted Messages**: BLE messages can be encrypted (future enhancement)
- **Anonymous IDs**: User IDs are not tied to personal information
- **Consent-based Sync**: Cloud sync only when explicitly enabled

### Message Privacy
- **Group-scoped**: Messages only visible to group members
- **TTL Limits**: Messages expire to prevent long-term tracking
- **No Persistence**: Messages not stored permanently unless needed
- **User Control**: Users control what information to share

## Future Enhancements

### Planned Features
- **Message Encryption**: End-to-end encryption for group messages
- **Voice Messages**: Audio communication via BLE mesh
- **File Sharing**: Small file transfer between group members
- **Group Hierarchies**: Admin roles and permissions
- **Message History**: Local storage of important messages
- **Integration**: Connect with other emergency services

### Advanced Features
- **Mesh Routing**: Intelligent message routing for large networks
- **Battery Optimization**: Power-efficient message transmission
- **Range Extension**: Multi-hop message relay for wider coverage
- **Satellite Integration**: Backup communication via satellite SMS

## Testing

Run the group functionality tests:
```bash
flutter test test/group_test.dart
```

The tests verify:
- Group creation and management
- Member status updates
- BLE message creation and serialization
- Message filtering and expiration
- Group operations and callbacks

## Troubleshooting

### Common Issues
1. **BLE Not Working**: Check device permissions and Bluetooth settings
2. **Messages Not Received**: Verify group membership and BLE scanning
3. **Location Not Updating**: Check location permissions and GPS settings
4. **Group Not Loading**: Verify internet connection for initial sync

### Debug Information
- Check console logs for BLE message transmission
- Verify group manager initialization
- Monitor message TTL and relay behavior
- Check device permissions and settings

## Support

For issues with group functionality:
1. Check device permissions (Bluetooth, Location)
2. Verify group membership and IDs
3. Test BLE functionality in device settings
4. Review console logs for error messages
5. Contact support with specific error details 