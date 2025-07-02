import 'package:flutter/material.dart';

class SosBroadcastScreen extends StatelessWidget {
  const SosBroadcastScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For demo, heartbeat/flash not animated
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'BROADCAST\nSOS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ToggleChip(label: 'Fall Detect', icon: Icons.directions_walk),
                        const SizedBox(width: 16),
                        _ToggleChip(label: 'Shake Detect', icon: Icons.vibration),
                        const SizedBox(width: 16),
                        _ToggleChip(label: 'Attach Health Card', icon: Icons.credit_card),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Flash alert bar (hidden by default)
            // Container(height: 8, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ToggleChip({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFF232323),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 20)),
        ],
      ),
    );
  }
} 