import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('resQlink', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Disaster-Resilient Emergency Mesh', style: TextStyle(fontSize: 18)),
            SizedBox(height: 24),
            Text('Version: 1.0.0'),
            SizedBox(height: 12),
            Text('Developed by Your Team Name'),
            SizedBox(height: 24),
            Text('resQlink is an open-source project to help communities stay connected and safe during disasters, even without internet.'),
          ],
        ),
      ),
    );
  }
} 