import 'package:flutter/material.dart';
import '../../core/models/resource_model.dart';
import '../../core/storage/local_storage.dart';
import '../../core/ble/ble_mesh_service.dart';
import 'package:uuid/uuid.dart';

class ResourceBroadcastScreen extends StatefulWidget {
  const ResourceBroadcastScreen({Key? key}) : super(key: key);

  @override
  State<ResourceBroadcastScreen> createState() => _ResourceBroadcastScreenState();
}

class _ResourceBroadcastScreenState extends State<ResourceBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  ResourceType _selectedType = ResourceType.need;
  ResourceCategory _selectedCategory = ResourceCategory.medical;
  bool _isUrgent = false;
  final List<ResourceModel> _receivedResources = [];
  final BleMeshService _bleMeshService = BleMeshService();

  @override
  void initState() {
    super.initState();
    _loadReceivedResources();
    _startScanning();
  }

  void _loadReceivedResources() {
    final resources = LocalStorage.getAllResources();
    setState(() {
      _receivedResources.addAll(resources);
    });
  }

  void _startScanning() {
    _bleMeshService.startScanning((_) {
      // Handle SOS messages if needed
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _bleMeshService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resource Broadcast'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Broadcast', icon: Icon(Icons.broadcast_on_personal)),
              Tab(text: 'Received', icon: Icon(Icons.list)),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildBroadcastTab(),
            _buildReceivedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelection(),
            const SizedBox(height: 24),
            _buildCategorySelection(),
            const SizedBox(height: 24),
            _buildFormFields(),
            const SizedBox(height: 24),
            _buildUrgencyToggle(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _broadcastResource,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Broadcast Resource',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<ResourceType>(
                    title: const Text('Need'),
                    value: ResourceType.need,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<ResourceType>(
                    title: const Text('Offer'),
                    value: ResourceType.offer,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ResourceCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
              ),
              items: ResourceCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_getCategoryDisplayName(category)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                hintText: 'Brief description of what you need/offer',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'Detailed description...',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencyToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.priority_high, color: Colors.red),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Mark as Urgent',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Switch(
              value: _isUrgent,
              onChanged: (value) {
                setState(() {
                  _isUrgent = value;
                });
              },
              activeColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Received Resources',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _refreshResources,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _receivedResources.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No resources received yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _receivedResources.length,
                  itemBuilder: (context, index) {
                    final resource = _receivedResources[index];
                    return _buildResourceCard(resource);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildResourceCard(ResourceModel resource) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: resource.type == ResourceType.need 
              ? Colors.red.shade100 
              : Colors.green.shade100,
          child: Icon(
            resource.type == ResourceType.need 
                ? Icons.help 
                : Icons.volunteer_activism,
            color: resource.type == ResourceType.need 
                ? Colors.red 
                : Colors.green,
          ),
        ),
        title: Text(
          resource.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: resource.isUrgent ? Colors.red : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resource.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(resource.categoryName),
                  backgroundColor: Colors.blue.shade100,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(resource.typeName),
                  backgroundColor: resource.type == ResourceType.need 
                      ? Colors.red.shade100 
                      : Colors.green.shade100,
                ),
                if (resource.isUrgent) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text('URGENT'),
                    backgroundColor: Colors.red,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Received: ${_formatTimestamp(resource.timestamp)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(ResourceCategory category) {
    switch (category) {
      case ResourceCategory.medical:
        return 'Medical';
      case ResourceCategory.food:
        return 'Food';
      case ResourceCategory.water:
        return 'Water';
      case ResourceCategory.shelter:
        return 'Shelter';
      case ResourceCategory.transportation:
        return 'Transportation';
      case ResourceCategory.communication:
        return 'Communication';
      case ResourceCategory.other:
        return 'Other';
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

  void _refreshResources() {
    _loadReceivedResources();
  }

  void _broadcastResource() {
    if (_formKey.currentState!.validate()) {
      final userProfile = LocalStorage.getUserProfile();
      final resource = ResourceModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        category: _selectedCategory,
        userId: userProfile?.id ?? 'anonymous',
        timestamp: DateTime.now(),
        ttl: 10,
        isUrgent: _isUrgent,
      );

      // Save locally
      LocalStorage.saveResource(resource);
      
      // Add to received list for immediate display
      setState(() {
        _receivedResources.insert(0, resource);
      });

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _isUrgent = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${resource.typeName} broadcasted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
} 