import 'package:flutter/material.dart';

class SimplePage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SimplePage({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(padding: const EdgeInsets.all(16), children: children),
    );
  }
}

