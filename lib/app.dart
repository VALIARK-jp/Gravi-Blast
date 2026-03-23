import 'package:flutter/material.dart';

import 'screens/game_screen.dart';

class GraviBlastApp extends StatelessWidget {
  const GraviBlastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GraviBlast',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
