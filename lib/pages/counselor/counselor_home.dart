import 'package:flutter/material.dart';

class CounselorHome extends StatelessWidget {
  const CounselorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home'), centerTitle: true),
      body: const Center(child: Text('Welcome to the Home Page!')),
    );
  }
}
