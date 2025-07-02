import 'package:flutter/material.dart';
import '../../core/utils/battery_utils.dart';
import '../../core/utils/location_utils.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  String lastSos = 'No SOS sent yet';
  String groupStatus = 'No group joined';
  int batteryLevel = 100;
  bool locationEnabled = true;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final battery = await BatteryUtils.getBatteryLevel();
    final location = await LocationUtils.isLocationServiceEnabled();
    setState(() {
      batteryLevel = battery;
      locationEnabled = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.black),
        ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            // Status Card
            Card(
              color: Color(0xFF181818),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sos, color: Colors.red, size: 32),
                        SizedBox(width: 12),
                        Text('Last SOS:', style: TextStyle(color: Colors.white70, fontSize: 18)),
                        SizedBox(width: 8),
                        Expanded(child: Text(lastSos, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.groups, color: Colors.blue, size: 28),
                        SizedBox(width: 12),
                        Text('Group:', style: TextStyle(color: Colors.white70, fontSize: 18)),
                        SizedBox(width: 8),
                        Expanded(child: Text(groupStatus, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.battery_full, color: batteryLevel <= 20 ? Colors.red : batteryLevel <= 50 ? Colors.orange : Colors.green, size: 28),
                        SizedBox(width: 8),
                        Text('$batteryLevel%', style: TextStyle(color: Colors.white, fontSize: 18)),
                        SizedBox(width: 16),
                        Icon(locationEnabled ? Icons.location_on : Icons.location_off, color: locationEnabled ? Colors.blue : Colors.grey, size: 28),
                        SizedBox(width: 8),
                        Text(locationEnabled ? 'Location On' : 'Location Off', style: TextStyle(color: Colors.white, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Quick Actions Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 1,
              children: [
                _QuickActionCard(
                  icon: Icons.sos,
                  label: 'Send SOS',
                  onTap: () => Navigator.of(context).pushNamed('/sos'),
                  color: Colors.red.shade700,
                ),
                _QuickActionCard(
                  icon: Icons.map,
                  label: 'Offline Map',
                  onTap: () => Navigator.of(context).pushNamed('/map'),
                  color: Colors.blue.shade700,
                ),
                _QuickActionCard(
                  icon: Icons.groups,
                  label: 'Groups',
                  onTap: () => Navigator.of(context).pushNamed('/groups'),
                  color: Colors.green.shade700,
                ),
                _QuickActionCard(
                  icon: Icons.inventory_2,
                  label: 'Resources',
                  onTap: () => Navigator.of(context).pushNamed('/resources'),
                  color: Colors.orange.shade700,
                ),
                _QuickActionCard(
                  icon: Icons.list_alt,
                  label: 'Incident Log',
                  onTap: () => Navigator.of(context).pushNamed('/log'),
                  color: Colors.purple.shade700,
                ),
                _QuickActionCard(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () => Navigator.of(context).pushNamed('/settings'),
                  color: Colors.grey.shade800,
                ),
              ],
            ),
            const SizedBox(height: 120),
          ],
        ),
        // Floating SOS FAB
        Positioned(
          right: 32,
          bottom: 32 + 88, // nav bar height
          child: FloatingActionButton(
            backgroundColor: Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: CircleBorder(),
            onPressed: () => Navigator.of(context).pushNamed('/sos'),
            child: Icon(Icons.sos, size: 48),
            tooltip: 'Send Emergency SOS',
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _QuickActionCard({required this.icon, required this.label, required this.onTap, required this.color});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(label, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
} 