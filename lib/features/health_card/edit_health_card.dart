import 'package:flutter/material.dart';
import '../../core/models/user_profile.dart';
import '../../core/storage/local_storage.dart';
import 'package:uuid/uuid.dart';

class EditHealthCardScreen extends StatefulWidget {
  const EditHealthCardScreen({Key? key}) : super(key: key);

  @override
  State<EditHealthCardScreen> createState() => _EditHealthCardScreenState();
}

class _EditHealthCardScreenState extends State<EditHealthCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedBloodGroup = 'A+';
  final List<String> _allergies = [];
  final List<String> _chronicConditions = [];
  
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    final profile = LocalStorage.getUserProfile();
    if (profile != null) {
      _nameController.text = profile.name;
      _ageController.text = profile.age.toString();
      _selectedBloodGroup = profile.bloodGroup;
      _allergies.addAll(profile.allergies);
      _chronicConditions.addAll(profile.chronicConditions);
      _emergencyContactController.text = profile.emergencyContact;
      _emergencyPhoneController.text = profile.emergencyPhone;
      _notesController.text = profile.notes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Health Card'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildMedicalInfoSection(),
              const SizedBox(height: 24),
              _buildEmergencyContactSection(),
              const SizedBox(height: 24),
              _buildNotesSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save Health Card',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your age';
                }
                final age = int.tryParse(value);
                if (age == null || age <= 0 || age > 150) {
                  return 'Please enter a valid age';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedBloodGroup,
              decoration: const InputDecoration(
                labelText: 'Blood Group',
                border: OutlineInputBorder(),
              ),
              items: _bloodGroups.map((group) {
                return DropdownMenuItem(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBloodGroup = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medical Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildListSection('Allergies', _allergies, 'Add Allergy'),
            const SizedBox(height: 16),
            _buildListSection('Chronic Conditions', _chronicConditions, 'Add Condition'),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items, String addButtonText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        if (items.isNotEmpty)
          ...items.map((item) => Card(
            child: ListTile(
              title: Text(item),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    items.remove(item);
                  });
                },
              ),
            ),
          )),
        TextButton.icon(
          onPressed: () => _addListItem(items, title),
          icon: const Icon(Icons.add),
          label: Text(addButtonText),
        ),
      ],
    );
  }

  Widget _buildEmergencyContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyContactController,
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter emergency contact name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyPhoneController,
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter emergency contact phone';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                hintText: 'Any additional medical information...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  void _addListItem(List<String> items, String title) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  items.add(controller.text.trim());
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final profile = UserProfile(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        bloodGroup: _selectedBloodGroup,
        allergies: List.from(_allergies),
        chronicConditions: List.from(_chronicConditions),
        emergencyContact: _emergencyContactController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim(),
        notes: _notesController.text.trim(),
      );

      LocalStorage.saveUserProfile(profile);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Health card saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    }
  }
} 