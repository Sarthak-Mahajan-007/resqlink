import 'package:flutter/material.dart';
import '../../core/models/user_profile.dart';
import '../../core/api/profile_api.dart';
import '../../core/models/profile.dart';
import 'edit_health_card.dart';
import '../../theme/app_theme.dart';

class HealthCardScreen extends StatefulWidget {
  const HealthCardScreen({Key? key}) : super(key: key);

  @override
  State<HealthCardScreen> createState() => _HealthCardScreenState();
}

class _HealthCardScreenState extends State<HealthCardScreen> {
  Profile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ProfileApi.fetchProfile(1); // Using user ID 1 for demo
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load health card: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.favorite, color: Colors.redAccent), // heart icon
            const SizedBox(width: 8),
            Text('Health Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: AppTheme.lightBlue), // save icon
            onPressed: () {},
            tooltip: 'Save',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Form Fields
            _FormFieldCard(
              icon: Icons.person,
              label: 'Name',
              child: TextField(
                decoration: InputDecoration(hintText: 'Enter your name'),
                controller: TextEditingController(text: _profile?.bio ?? ''),
              ),
            ),
            _FormFieldCard(
              icon: Icons.calendar_today,
              label: 'Age',
              child: TextField(
                keyboardType: TextInputType.number, 
                decoration: InputDecoration(hintText: 'Enter your age'),
              ),
            ),
            _FormFieldCard(
              icon: Icons.opacity,
              label: 'Blood Type',
              child: DropdownButtonFormField<String>(
                value: _profile?.healthCard?.bloodGroup,
                items: ['A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (v) {},
                decoration: InputDecoration(hintText: 'Select blood type'),
              ),
            ),
            _FormFieldCard(
              icon: Icons.warning,
              label: 'Allergies',
              child: TextField(
                maxLines: 2, 
                decoration: InputDecoration(hintText: 'List allergies'),
                controller: TextEditingController(text: _profile?.healthCard?.allergies ?? ''),
              ),
            ),
            _FormFieldCard(
              icon: Icons.medical_services,
              label: 'Medical Conditions',
              child: TextField(
                maxLines: 2, 
                decoration: InputDecoration(hintText: 'List conditions'),
                controller: TextEditingController(text: _profile?.healthCard?.medicalConditions ?? ''),
              ),
            ),
            _FormFieldCard(
              icon: Icons.phone,
              label: 'Emergency Contact',
              child: TextField(
                decoration: InputDecoration(hintText: 'Enter contact number'),
                controller: TextEditingController(text: _profile?.healthCard?.emergencyContact ?? ''),
              ),
            ),
            const SizedBox(height: 32),
            // QR Code Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[200], // Placeholder for QR code
                    child: Center(child: Icon(Icons.qr_code, size: 80, color: AppTheme.navy)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.qr_code),
                    label: Text('Share Health Info'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightBlue,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48),
                      textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action Buttons
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightBlue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
                textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              child: Text('Save'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.qr_code),
              label: Text('Generate QR'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormFieldCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _FormFieldCard({required this.icon, required this.label, required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.navy),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navy)),
                  const SizedBox(height: 4),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 