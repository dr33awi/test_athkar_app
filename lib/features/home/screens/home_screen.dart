// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية'),
      ),
      body: const Center(
        child: Text(
          'مرحباً',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}