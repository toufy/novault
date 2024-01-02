import 'package:flutter/material.dart';

import 'home.dart';

void main() {
  runApp(const Novault());
}

class Novault extends StatelessWidget {
  const Novault({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'novault',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.amber,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          cardTheme: const CardTheme(surfaceTintColor: Colors.lightBlueAccent)),
      home: const LoginPage(),
    );
  }
}
