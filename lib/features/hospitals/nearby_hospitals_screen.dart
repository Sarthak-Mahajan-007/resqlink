import 'package:flutter/material.dart';

class NearbyHospitalsScreen extends StatelessWidget {
  const NearbyHospitalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        children: [
          // Emergency Numbers Widget
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _EmergencyButton(label: 'Ambulance', icon: Icons.local_hospital),
              _EmergencyButton(label: 'Police', icon: Icons.local_police),
              _EmergencyButton(label: 'Fire', icon: Icons.local_fire_department),
            ],
          ),
          const SizedBox(height: 32),
          // Hospital List
          ...List.generate(3, (i) => _HospitalCard(selected: i == 0)),
        ],
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  final String label;
  final IconData icon;
  const _EmergencyButton({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFFD32F2F),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final bool selected;
  const _HospitalCard({this.selected = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF232323),
        borderRadius: BorderRadius.circular(24),
        border: selected ? Border.all(color: Color(0xFFD32F2F), width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('City Hospital', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('123 Main St, District', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          const SizedBox(height: 8),
          Text('2.1 km away', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              _PillButton(label: 'Directions', color: Color(0xFF444CFF)),
              const SizedBox(width: 16),
              _PillButton(label: 'Emergency', color: Color(0xFFD32F2F)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color color;
  const _PillButton({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(label, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
} 