import 'package:flutter/material.dart';

class ExistScreen extends StatelessWidget {
  const ExistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text(
          'Lütfen oyundan çıkma la oyuncu lazım!',
          style: TextStyle(fontSize: 20, color: Colors.grey[700]),
        ),
      ),
    );
  }
}
