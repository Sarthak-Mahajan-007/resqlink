import 'package:flutter/material.dart';

class VolunteerModeScreen extends StatelessWidget {
  const VolunteerModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volunteer Mode')),
      body: Center(
        child: Text(
          'Volunteer Mode Coming Soon!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
} 