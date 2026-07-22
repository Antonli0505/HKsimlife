import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'game_state.dart';
import 'screens/start_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HKLifeSimulatorApp());
}

class HKLifeSimulatorApp extends StatelessWidget {
  const HKLifeSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState()..init(),
      child: MaterialApp(
        title: '香港生存模擬器',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D1117),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF58A6FF),
            secondary: Color(0xFF238636),
            surface: Color(0xFF161B22),
          ),
          fontFamily: 'system-ui, -apple-system, sans-serif',
          useMaterial3: true,
        ),
        home: const StartScreen(),
      ),
    );
  }
}
