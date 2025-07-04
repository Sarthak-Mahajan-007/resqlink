import 'package:flutter/material.dart';
import 'features/home/home_dashboard.dart';
import 'features/sos/sos_sender.dart';
import 'features/sos/sos_receiver.dart';
import 'features/map/offline_map_screen.dart';
import 'features/group/group_screen.dart';
import 'features/resource_broadcast/resource_broadcast_screen.dart';
import 'features/log/incident_log_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/first_aid/first_aid_assistant_screen.dart';
import 'features/hospitals/nearby_hospitals_screen.dart';
import 'features/health_card/health_card_screen.dart';
import 'core/storage/local_storage.dart';
import 'core/utils/battery_utils.dart';
import 'core/ble/ble_mesh_service.dart';
import 'core/utils/location_utils.dart';
import 'package:provider/provider.dart';
import 'theme/theme_notifier.dart';
import 'features/first_aid/first_aid_screen.dart';
import 'features/qr_code/qr_code_screen.dart';
import 'features/volunteer/volunteer_mode_screen.dart';
import 'features/about/about_screen.dart';

class ResQlinkApp extends StatelessWidget {
  const ResQlinkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      title: 'resQlink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red.shade700,
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5F5),
          foregroundColor: Colors.black,
          elevation: 2,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFF5F5F5),
          selectedItemColor: Color(0xFFD32F2F),
          unselectedItemColor: Color(0xFF888888),
          showUnselectedLabels: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red.shade700,
          brightness: Brightness.dark,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF181818),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF181818),
          selectedItemColor: Color(0xFFD32F2F),
          unselectedItemColor: Color(0xFFCCCCCC),
          showUnselectedLabels: true,
        ),
      ),
      themeMode: themeNotifier.themeMode,
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  bool _isInitialized = false;

  final List<Widget> _screens = [
    const HomeDashboard(),
    const OfflineMapScreen(),
    const GroupScreen(),
    const ResourceBroadcastScreen(),
    const IncidentLogScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Home',
    'Map',
    'Groups',
    'Resources',
    'Log',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await LocalStorage.initialize().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('Initialization timed out, continuing without storage');
          return;
        },
      );
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing app: $e');
      // Continue even if initialization fails
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _openDrawer() {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.red.shade700),
              SizedBox(height: 16),
              Text('Initializing...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          const AppBarStatusIndicators(),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.red.shade700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('resQlink', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Disaster-Resilient Emergency Mesh', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.medical_services),
              title: Text('First Aid Assistant'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FirstAidAssistantScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.medical_services),
              title: Text('First Aid Manual'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FirstAidScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.local_hospital),
              title: Text('Nearby Hospitals'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NearbyHospitalsScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.qr_code),
              title: Text('QR Code'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => QrCodeScreen(data: 'resQlink-user-or-group-id'),
                ));
              },
            ),
            ListTile(
              leading: Icon(Icons.volunteer_activism),
              title: Text('Volunteer Mode'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const VolunteerModeScreen(),
                ));
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('About'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AboutScreen(),
                ));
              },
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Resources'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class AppBarStatusIndicators extends StatefulWidget {
  const AppBarStatusIndicators({Key? key}) : super(key: key);

  @override
  State<AppBarStatusIndicators> createState() => _AppBarStatusIndicatorsState();
}

class _AppBarStatusIndicatorsState extends State<AppBarStatusIndicators> {
  int _batteryLevel = 100;
  bool _isCharging = false;
  bool _meshActive = false;
  bool _locationEnabled = true;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final battery = await BatteryUtils.getBatteryLevel();
    final charging = await BatteryUtils.isCharging();
    // For mesh, you may want to check if scanning/advertising is active. Here, we just set true for demo.
    final mesh = true; // TODO: Integrate with BleMeshService status
    final location = await LocationUtils.isLocationServiceEnabled();
    setState(() {
      _batteryLevel = battery;
      _isCharging = charging;
      _meshActive = mesh;
      _locationEnabled = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _meshActive ? Icons.wifi : Icons.wifi_off,
          color: _meshActive ? Colors.green : Colors.red,
          size: 22,
        ),
        const SizedBox(width: 8),
        Icon(
          _locationEnabled ? Icons.location_on : Icons.location_off,
          color: _locationEnabled ? Colors.blue : Colors.grey,
          size: 22,
        ),
        const SizedBox(width: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              _isCharging ? Icons.battery_charging_full : Icons.battery_full,
              color: _batteryLevel <= 20
                  ? Colors.red
                  : _batteryLevel <= 50
                      ? Colors.orange
                      : Colors.green,
              size: 22,
            ),
            Positioned(
              right: 0,
              child: Text(
                '$_batteryLevel%',
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.refresh, size: 18, color: Colors.white70),
          tooltip: 'Refresh status',
          onPressed: _refreshStatus,
        ),
      ],
    );
  }
} 