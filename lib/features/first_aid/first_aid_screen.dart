import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FirstAidScreen extends StatelessWidget {
  const FirstAidScreen({Key? key}) : super(key: key);

  static final List<_FirstAidTopic> topics = [
    _FirstAidTopic('CPR (Cardiopulmonary Resuscitation)', '1. Check responsiveness and breathing.\n2. Call emergency services.\n3. Start chest compressions: 30 compressions, 2 breaths.\n4. Continue until help arrives.'),
    _FirstAidTopic('Bleeding', '1. Apply direct pressure to the wound.\n2. Elevate the injured area.\n3. Use a clean cloth or bandage.\n4. Seek medical help if bleeding is severe.'),
    _FirstAidTopic('Burns', '1. Cool the burn under running water for 10+ minutes.\n2. Cover with a sterile, non-fluffy dressing.\n3. Do not apply creams or break blisters.\n4. Seek medical help for severe burns.'),
    _FirstAidTopic('Choking', '1. Ask if the person can cough or speak.\n2. If not, give 5 back blows.\n3. If still choking, give 5 abdominal thrusts.\n4. Repeat until clear or help arrives.'),
    _FirstAidTopic('Fractures', '1. Immobilize the injured area.\n2. Apply a splint if trained.\n3. Avoid moving the person.\n4. Seek medical help.'),
    _FirstAidTopic('Heat Stroke', '1. Move to a cool place.\n2. Remove excess clothing.\n3. Cool with damp cloths or a fan.\n4. Give sips of water if conscious.\n5. Seek medical help.'),
    _FirstAidTopic('Poisoning', '1. Call emergency services immediately.\n2. Do not induce vomiting unless instructed.\n3. Keep the person calm and still.\n4. Provide information about the poison if possible.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        elevation: 0,
        title: const Text('First Aid Manual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: topics.length,
        separatorBuilder: (context, i) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final topic = topics[i];
          return Card(
            color: AppTheme.card,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.medical_services, color: AppTheme.navy),
              title: Text(topic.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () => _showDetails(context, topic),
            ),
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, _FirstAidTopic topic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(topic.title),
        content: SingleChildScrollView(
          child: Text(
            topic.details.replaceAll('\\n', '\n'),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _FirstAidTopic {
  final String title;
  final String details;
  const _FirstAidTopic(this.title, this.details);
} 