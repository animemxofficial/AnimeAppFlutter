import 'package:flutter/material.dart';

void main() {
  runApp(const AnimeApp());
}

class AnimeApp extends StatelessWidget {
  const AnimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AnimeMX',
      theme: ThemeData.dark(), // Dark theme anime ke liye best hai
      home: const AnimeHomePage(),
    );
  }
}

class AnimeHomePage extends StatelessWidget {
  const AnimeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AnimeMX"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "AnimeMX App Zinda Hai! 🔥\nUI Design shuru ho raha hai...",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}