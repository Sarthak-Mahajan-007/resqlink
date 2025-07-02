import 'package:flutter/material.dart';

class FirstAidAssistantScreen extends StatelessWidget {
  const FirstAidAssistantScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('First Aid Assistant')),
      body: Center(child: Text('First Aid Assistant Screen')),
    );
  }
} 