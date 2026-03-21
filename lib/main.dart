import 'package:flutter/material.dart';

void main() => runApp(const AnimeMX());

class Anime {
  final String title;
  final String image;
  Anime({required this.title, required this.image});
}

final List<Anime> animeList = [
  Anime(title: "Classroom", image: "https://i.ibb.co/KpsCLmBg/imager.jpg"),
  Anime(title: "Solo Leveling", image: "https://i.ibb.co/vxJtwkcX/k.jpg"),
  Anime(title: "One Piece", image: "https://i.ibb.co/jvVk3XSY/g.jpg"),
  Anime(title: "Naruto", image: "https://i.ibb.co/YFg2hKvf/j.jpg"),
];

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(primaryColor: Colors.deepPurple),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AnimeMX", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0),
      body: ListView(
        children: [
          _buildSection("Top Picks For You"),
          _buildSection("Trending Now"),
          _buildMostViewedSection(),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.all(15), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      SizedBox(
        height: 180, // Height set ki hai taaki image dikhe
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: animeList.length,
          itemBuilder: (c, i) => Container(
            width: 120,
            margin: const EdgeInsets.only(left: 15),
            child: Column(children: [
              // Image ko box mein wrap kiya hai
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(animeList[i].image, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.error)))),
              Padding(padding: const EdgeInsets.only(top: 5), child: Text(animeList[i].title, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildMostViewedSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.all(15), child: Text("Most Viewed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7),
        itemCount: 4,
        itemBuilder: (c, i) => Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(animeList[i].image, fit: BoxFit.cover)),
        ),
      ),
    ]);
  }
}