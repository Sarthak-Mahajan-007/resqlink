import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ztwyxwehmfimtclnawyq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp0d3l4d2VobWZpbXRjbG5hd3lxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE1NTg2ODMsImV4cCI6MjA2NzEzNDY4M30.fnqR9dkhY4kV_6k_PV3rbA4XbCeBB4ImOIx8vNX2GBs',
  );
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const ResQlinkApp(),
    ),
  );
}
