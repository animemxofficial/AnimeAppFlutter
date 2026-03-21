import 'package:flutter/material.dart';

void main() => runApp(const AnimeMX());

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFF47521), // Tera Orange Color
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AnimeMX", style: TextStyle(color: Color(0xFFF47521), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          // 1. Slider Section
          _buildSlider(),
          
          // 2. Dynamic Categories
          _buildAnimeSection("Trending Now 🔥", Colors.orange),
          _buildAnimeSection("Action", Colors.blue),
          _buildAnimeSection("Romance", Colors.pink),
          _buildAnimeSection("Comedy", Colors.green),
        ],
      ),
    );
  }

  // Hero Slider
  Widget _buildSlider() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: PageView.builder(
        itemCount: 3,
        itemBuilder: (ctx, i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(child: Text("Hero Slider Poster")),
        ),
      ),
    );
  }

  // Common Section for Categories
  Widget _buildAnimeSection(String title, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent)),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            itemBuilder: (ctx, i) => Container(
              width: 110,
              margin: const EdgeInsets.only(left: 15),
              child: Column(
                children: [
                  Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text("Anime Title", style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}