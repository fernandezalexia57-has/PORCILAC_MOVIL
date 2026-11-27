import 'package:flutter/material.dart';
import 'package:flutter_porcilac/screenReproduccion.dart';
import 'package:flutter_porcilac/screens/screenDestete.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vehverenzjcsfsekeqel.supabase.co',
    anonKey: 'sb_publishable_wynU7pJr_qQzbYrfnx8_Fg_pznPvopo',
  );

  runApp(const PorcilacApp());
}

class PorcilacApp extends StatelessWidget {
  const PorcilacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Porcilac',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFEA4C9A),
      ),
      home: const ScreenReproduccion(),
    );
  }
}