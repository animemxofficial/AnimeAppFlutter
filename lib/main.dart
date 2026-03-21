import 'package:flutter/material.dart';

void main() => runApp(const AnimeMX());

// Data Model
class Anime {
  final String title;
  final String image;
  final String genre;
  Anime({required this.title, required this.image, required this.genre});
}

// Data List
final List<Anime> animeList = [
  Anime(title: "Classroom of the Elite", image: "https://i.ibb.co/KpsCLmBg/imager.jpg", genre: "Thriller"),
  Anime(title: "Solo Leveling", image: "https://i.ibb.co/vxJtwkcX/k.jpg", genre: "Action"),
  Anime(title: "One Piece", image: "https://i.ibb.co/jvVk3XSY/g.jpg", genre: "Adventure"),
  Anime(title: "Naruto", image: "https://i.ibb.co/YFg2hKvf/j.jpg", genre: "Action"),
  Anime(title: "Demon Slayer", image: "https://i.ibb.co/yFRNxJbG/o.jpg", genre: "Action"),
];

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
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
        title: const Text("AnimeMX", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.black))],
      ),
      body: ListView(
        children: [
          _buildSlider(),
          _buildSection("Top Picks For You"),
          _buildSection("Trending Now"),
          _buildMostViewedSection(),
        ],
      ),
    );
  }

  Widget _buildSlider() {
    return SizedBox(height: 200, child: PageView.builder(itemCount: 3, itemBuilder: (c, i) => Container(margin: const EdgeInsets.all(10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: DecorationImage(image: NetworkImage(animeList[i].image), fit: BoxFit.cover)))));
  }

  Widget _buildSection(String title) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.all(15), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      SizedBox(height: 150, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: animeList.length, itemBuilder: (c, i) => Container(width: 100, margin: const EdgeInsets.only(left: 15), child: Column(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(animeList[i].image, fit: BoxFit.cover))), Text(animeList[i].title, overflow: TextOverflow.ellipsis)])))),
    ]);
  }

  Widget _buildMostViewedSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.all(15), child: Text("Most Viewed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7),
        itemCount: 4,
        itemBuilder: (c, i) => Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(animeList[i].image, fit: BoxFit.cover)),
        ),
      ),
    ]);
  }
}