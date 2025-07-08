import 'package:flutter/material.dart';
import '../../core/models/profile.dart';
import '../../core/models/health_card.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/profile_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  bool _isEditing = false;
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  // Editable fields
  late TextEditingController _bioController;
  late TextEditingController _avatarUrlController;
  late TextEditingController _dobController;
  late TextEditingController _genderController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicalConditionsController;
  late TextEditingController _emergencyContactController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfile();
  }

  void _initializeControllers() {
    _bioController = TextEditingController();
    _avatarUrlController = TextEditingController();
    _dobController = TextEditingController();
    _genderController = TextEditingController();
    _bloodGroupController = TextEditingController();
    _allergiesController = TextEditingController();
    _medicalConditionsController = TextEditingController();
    _emergencyContactController = TextEditingController();
  }

  void _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ProfileApi.fetchProfile(1); // Using user ID 1 for demo
      setState(() {
        _profile = profile;
        _bioController.text = profile?.bio ?? '';
        _avatarUrlController.text = profile?.avatarUrl ?? '';
        _dobController.text = profile?.dateOfBirth?.toIso8601String().split('T').first ?? '';
        _genderController.text = profile?.gender ?? '';
        _bloodGroupController.text = profile?.healthCard?.bloodGroup ?? '';
        _allergiesController.text = profile?.healthCard?.allergies ?? '';
        _medicalConditionsController.text = profile?.healthCard?.medicalConditions ?? '';
        _emergencyContactController.text = profile?.healthCard?.emergencyContact ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final updatedHealthCard = HealthCard(
        id: _profile?.healthCard?.id ?? 1,
        bloodGroup: _bloodGroupController.text,
        allergies: _allergiesController.text,
        medicalConditions: _medicalConditionsController.text,
        emergencyContact: _emergencyContactController.text,
        createdAt: _profile?.healthCard?.createdAt ?? DateTime.now(),
      );
      
      final updatedProfile = Profile(
        id: _profile?.id ?? 1,
        userId: _profile?.userId ?? 1,
        healthCardId: updatedHealthCard.id,
        bio: _bioController.text,
        avatarUrl: _avatarUrlController.text,
        dateOfBirth: _dobController.text.isNotEmpty ? DateTime.tryParse(_dobController.text) : null,
        gender: _genderController.text,
        createdAt: _profile?.createdAt ?? DateTime.now(),
        healthCard: updatedHealthCard,
      );
      
      final success = await ProfileApi.saveProfile(updatedProfile);
      if (success) {
        setState(() {
          _profile = updatedProfile;
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved to database!')),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save profile')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  void _callEmergencyContact() async {
    final phone = _emergencyContactController.text;
    if (phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot launch dialer')));
      }
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
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
            tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
          ),
        ],
      ),
      body: _profile == null && !_isEditing
          ? const Center(child: Text('No profile found. Create one by tapping the edit icon.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: _avatarUrlController.text.isNotEmpty
                            ? NetworkImage(_avatarUrlController.text)
                            : null,
                        child: _avatarUrlController.text.isEmpty ? const Icon(Icons.person, size: 48) : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Bio', _bioController, enabled: _isEditing),
                    _buildTextField('Avatar URL', _avatarUrlController, enabled: _isEditing),
                    _buildTextField('Date of Birth (YYYY-MM-DD)', _dobController, enabled: _isEditing),
                    _buildTextField('Gender', _genderController, enabled: _isEditing),
                    const Divider(height: 32),
                    const Text('Health Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    _buildTextField('Blood Group', _bloodGroupController, enabled: _isEditing),
                    _buildTextField('Allergies', _allergiesController, enabled: _isEditing),
                    _buildTextField('Medical Conditions', _medicalConditionsController, enabled: _isEditing),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Emergency Contact', _emergencyContactController, enabled: _isEditing)),
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: _callEmergencyContact,
                        ),
                      ],
                    ),
                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            child: _isLoading 
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(strokeWidth: 2)
                                  )
                                : const Text('Save'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (enabled && label == 'Emergency Contact' && (value == null || value.isEmpty)) {
            return 'Please enter emergency contact';
          }
          return null;
        },
      ),
    );
  }
} 