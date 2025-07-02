import 'package:flutter/material.dart';

class ResourceBroadcastScreen extends StatefulWidget {
  const ResourceBroadcastScreen({Key? key}) : super(key: key);

  @override
  State<ResourceBroadcastScreen> createState() => _ResourceBroadcastScreenState();
}

class _ResourceBroadcastScreenState extends State<ResourceBroadcastScreen> {
  bool volunteerMode = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: Row(
              children: [
                Text('Volunteer Mode', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Switch(
                  value: volunteerMode,
                  onChanged: (v) => setState(() => volunteerMode = v),
                  activeColor: Color(0xFFD32F2F),
                  inactiveThumbColor: Colors.grey[700],
                  inactiveTrackColor: Colors.grey[800],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              children: [
                _ResourcePill(icon: Icons.water_drop, label: 'Need Water'),
                _ResourcePill(icon: Icons.medical_services, label: 'Have Medicine'),
                _ResourcePill(icon: Icons.fastfood, label: 'Need Food'),
                _ResourcePill(icon: Icons.bolt, label: 'Need Power'),
                _ResourcePill(icon: Icons.home, label: 'Have Shelter'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourcePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ResourcePill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFF232323),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
} 