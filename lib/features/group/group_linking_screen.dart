import 'package:flutter/material.dart';

class GroupLinkingScreen extends StatelessWidget {
  const GroupLinkingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text('Group SOS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: Icon(Icons.add, color: Colors.white, size: 32),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),
          ...List.generate(3, (i) => _MemberTile()),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF232323),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xFF181818),
            child: Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alex Smith', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatusBadge(status: 'OK', color: Colors.green),
                    const SizedBox(width: 12),
                    Text('Last seen 2m ago', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(status, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }
} 