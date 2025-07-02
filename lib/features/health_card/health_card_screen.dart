import 'package:flutter/material.dart';
import '../../core/models/user_profile.dart';
import '../../core/storage/local_storage.dart';
import 'edit_health_card.dart';

class HealthCardScreen extends StatefulWidget {
  const HealthCardScreen({Key? key}) : super(key: key);

  @override
  State<HealthCardScreen> createState() => _HealthCardScreenState();
}

class _HealthCardScreenState extends State<HealthCardScreen> {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final profile = LocalStorage.getUserProfile();
    setState(() {
      _profile = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF232323),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFF181818),
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile!.name,
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _profile!.bloodGroup,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Editable Fields
          _EditableField(label: 'Age', value: '${_profile!.age} years'),
          _EditableField(label: 'Allergies', value: _profile!.allergies.join(', ')),
          _EditableField(label: 'Conditions', value: _profile!.chronicConditions.join(', ')),
          const SizedBox(height: 32),
          // Emergency Contacts
          Text(
            'Emergency Contacts',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _ContactTile(name: 'Emergency Contact', phone: _profile!.emergencyContact),
          _ContactTile(name: 'Phone', phone: _profile!.emergencyPhone),
          const SizedBox(height: 32),
          // Medical Timeline
          Text(
            'Medical Timeline',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _TimelineEntry(date: '2024-05-01', type: 'Checkup', preview: 'Routine checkup, all clear.'),
          _TimelineEntry(date: '2023-12-10', type: 'Asthma', preview: 'Mild attack, inhaler used.'),
        ],
      ),
    );
  }

  Widget _EditableField({required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Color(0xFF232323),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 18)),
          const SizedBox(width: 24),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Icon(Icons.edit, color: Colors.grey[600], size: 20),
        ],
      ),
    );
  }

  Widget _ContactTile({required String name, required String phone}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFF232323),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: Color(0xFFD32F2F), size: 22),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: TextStyle(color: Colors.white, fontSize: 18))),
          Text(phone, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _TimelineEntry({required String date, required String type, required String preview}) {
    return ExpansionTile(
      backgroundColor: Color(0xFF232323),
      collapsedBackgroundColor: Color(0xFF232323),
      title: Row(
        children: [
          Text(date, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          const SizedBox(width: 16),
          Text(type, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(preview, style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ],
    );
  }
} 