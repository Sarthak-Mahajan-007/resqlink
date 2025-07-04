import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/models/contact.dart';
import '../core/storage/local_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Contact> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await LocalStorage.getContacts();
    setState(() {
      _contacts = contacts;
      _loading = false;
    });
  }

  Future<void> _addOrEditContact({Contact? contact, int? index}) async {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final result = await showDialog<Contact>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contact == null ? 'Add Contact' : 'Edit Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) return;
              Navigator.pop(context, Contact(name: nameController.text.trim(), phone: phoneController.text.trim()));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      if (index == null) {
        await LocalStorage.addContact(result);
      } else {
        await LocalStorage.updateContact(index, result);
      }
      _loadContacts();
    }
  }

  Future<void> _deleteContact(int index) async {
    await LocalStorage.deleteContact(index);
    _loadContacts();
  }

  void _callContact(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _messageContact(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.phone, color: AppTheme.lightBlue),
            const SizedBox(width: 8),
            const Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add, color: AppTheme.success),
            onPressed: () => _addOrEditContact(),
            tooltip: 'Add Contact',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick Dial Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _QuickDialButton(
                        color: AppTheme.lightBlue,
                        icon: Icons.shield,
                        label: 'Police',
                        onTap: () => _callContact('100'),
                      ),
                      _QuickDialButton(
                        color: AppTheme.danger,
                        icon: Icons.local_fire_department,
                        label: 'Fire',
                        onTap: () => _callContact('101'),
                      ),
                      _QuickDialButton(
                        color: AppTheme.success,
                        icon: Icons.favorite,
                        label: 'Medical',
                        onTap: () => _callContact('102'),
                      ),
                    ],
                  ),
                ),
                // Contact List
                Expanded(
                  child: _contacts.isEmpty
                      ? const Center(child: Text('No contacts added.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _contacts.length,
                          itemBuilder: (context, index) => _ContactCard(
                            name: _contacts[index].name,
                            phone: _contacts[index].phone,
                            onCall: () => _callContact(_contacts[index].phone),
                            onMessage: () => _messageContact(_contacts[index].phone),
                            onEdit: () => _addOrEditContact(contact: _contacts[index], index: index),
                            onDelete: () => _deleteContact(index),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.success,
          child: const Icon(Icons.person_add),
        onPressed: () => _addOrEditContact(),
        tooltip: 'Add Contact',
      ),
    );
  }
}

class _QuickDialButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickDialButton({required this.color, required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(100, 48),
        elevation: 2,
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onPressed: onTap,
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final String phone;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ContactCard({required this.name, required this.phone, required this.onCall, required this.onMessage, required this.onEdit, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.navy,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.navy)),
                  Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.phone, color: AppTheme.success),
                  onPressed: onCall,
                  tooltip: 'Call',
                ),
                IconButton(
                  icon: Icon(Icons.message, color: AppTheme.lightBlue),
                  onPressed: onMessage,
                  tooltip: 'Message',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 