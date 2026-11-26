import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:porcilac/screens/screenLogin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'assets/.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const PorcilacApp());
}

class PorcilacApp extends StatelessWidget {
  const PorcilacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PORCILAC',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFEA4C9A),
      ),
      home: const ScreenLogin(),
    );
  }
}
