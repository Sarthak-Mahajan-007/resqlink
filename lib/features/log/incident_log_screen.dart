import 'package:flutter/material.dart';

class IncidentLogScreen extends StatelessWidget {
  const IncidentLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        children: [
          _DateHeader(date: 'Today'),
          _EventCard(type: 'SOS Sent', icon: Icons.warning, time: '10:12', color: Color(0xFFD32F2F)),
          _EventCard(type: 'Relay', icon: Icons.sync, time: '09:58', color: Colors.grey[400]!),
          _EventCard(type: 'Sync', icon: Icons.cloud_upload, time: '09:30', color: Colors.grey[400]!),
          _DateHeader(date: 'Yesterday'),
          _EventCard(type: 'SOS Sent', icon: Icons.warning, time: '22:14', color: Color(0xFFD32F2F)),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String date;
  const _DateHeader({required this.date});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String type;
  final IconData icon;
  final String time;
  final Color color;
  const _EventCard({required this.type, required this.icon, required this.time, required this.color});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Color(0xFF232323),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 32),
                      const SizedBox(width: 16),
                      Text(type, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Details about this event...', style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 16),
                  Text('Timestamp: $time', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF232323),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Text(type, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 18)),
          ],
        ),
      ),
    );
  }
} 