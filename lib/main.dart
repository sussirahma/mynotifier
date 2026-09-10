import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const MyNotifierApp());
}

class MyNotifierApp extends StatelessWidget {
  const MyNotifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyNotifier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}