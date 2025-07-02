import 'package:flutter/material.dart';
import '../../core/models/sos_message.dart';
import '../../core/storage/local_storage.dart';

class SosLog extends StatefulWidget {
  const SosLog({Key? key}) : super(key: key);

  @override
  State<SosLog> createState() => _SosLogState();
}

class _SosLogState extends State<SosLog> {
  List<SosMessage> _sosMessages = [];
  String _filterType = 'all'; // 'all', 'sent', 'received'

  @override
  void initState() {
    super.initState();
    _loadSosLog();
  }

  void _loadSosLog() {
    final messages = LocalStorage.getSosLog();
    setState(() {
      _sosMessages = messages;
    });
  }

  List<SosMessage> get _filteredMessages {
    switch (_filterType) {
      case 'sent':
        return _sosMessages.where((msg) => msg.ttl == 5).toList();
      case 'received':
        return _sosMessages.where((msg) => msg.ttl < 5).toList();
      default:
        return _sosMessages;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Log'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Messages'),
              ),
              const PopupMenuItem(
                value: 'sent',
                child: Text('Sent Only'),
              ),
              const PopupMenuItem(
                value: 'received',
                child: Text('Received Only'),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.filter_list),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSosLog,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChip(),
          Expanded(
            child: _filteredMessages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No SOS messages in log',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredMessages.length,
                    itemBuilder: (context, index) {
                      final message = _filteredMessages[index];
                      return _buildSosMessageCard(message);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Filter: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(_getFilterDisplayName()),
            selected: true,
            onSelected: (selected) {
              // Show filter menu
            },
          ),
          const Spacer(),
          Text('${_filteredMessages.length} messages'),
        ],
      ),
    );
  }

  Widget _buildSosMessageCard(SosMessage message) {
    final isSent = message.ttl == 5;
    final isRelayed = message.ttl < 5 && message.ttl > 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSent 
              ? Colors.red.shade100 
              : isRelayed 
                  ? Colors.orange.shade100 
                  : Colors.blue.shade100,
          child: Icon(
            isSent 
                ? Icons.send 
                : isRelayed 
                    ? Icons.repeat 
                    : Icons.call_received,
            color: isSent 
                ? Colors.red 
                : isRelayed 
                    ? Colors.orange 
                    : Colors.blue,
          ),
        ),
        title: Text(
          message.message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatLocation(message.latitude, message.longitude),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(isSent ? 'SENT' : isRelayed ? 'RELAYED' : 'RECEIVED'),
                  backgroundColor: isSent 
                      ? Colors.red.shade100 
                      : isRelayed 
                          ? Colors.orange.shade100 
                          : Colors.blue.shade100,
                  labelStyle: TextStyle(
                    color: isSent 
                        ? Colors.red 
                        : isRelayed 
                            ? Colors.orange 
                            : Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (isRelayed)
                  Chip(
                    label: Text('TTL: ${message.ttl}'),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: const TextStyle(fontSize: 10),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'copy':
                _copyMessage(message);
                break;
              case 'share':
                _shareMessage(message);
                break;
              case 'delete':
                _deleteMessage(message);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'copy',
              child: Text('Copy Message'),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Text('Share'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterDisplayName() {
    switch (_filterType) {
      case 'sent':
        return 'Sent Only';
      case 'received':
        return 'Received Only';
      default:
        return 'All Messages';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatLocation(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return 'No location';
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  void _copyMessage(SosMessage message) {
    final text = '''
SOS Message:
${message.message}
Time: ${message.timestamp}
Location: ${_formatLocation(message.latitude, message.longitude)}
TTL: ${message.ttl}
''';
    
    // TODO: Implement clipboard copy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }

  void _shareMessage(SosMessage message) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _deleteMessage(SosMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this SOS message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement delete functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _clearLog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear SOS Log'),
        content: const Text('Are you sure you want to clear all SOS messages? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await LocalStorage.clearSosLog();
              Navigator.pop(context);
              _loadSosLog();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SOS log cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
} 