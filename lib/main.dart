
import 'package:flutter/material.dart';

void main() => runApp(const ArizaApp());

class ArizaApp extends StatelessWidget {
  const ArizaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arıza Takip',
      debugShowCheckedModeBanner: false,
      home: const PlaceholderPage(),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Türksoy M. - Yavuz Ö."),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Text(
          "Tasarım eklenecek proje altyapısı hazır.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
