import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() => runApp(const AnimeMX());

// Data Models
class Anime { final String title; final String image; Anime({required this.title, required this.image}); }

final List<Anime> sliderList = [
  Anime(title: "Slice Pizza", image: "https://i.ibb.co/rW2Zk9B/images.jpg"),
  Anime(title: "Solo Leaving", image: "https://i.ibb.co/C3rhjGv3/images-1.jpg"),
  Anime(title: "Girls Like Boy", image: "https://i.ibb.co/kV2jQ279/images-2.jpg"),
  Anime(title: "Best Girls", image: "https://i.ibb.co/DDDJNsFX/images-3.jpg"),
];

final List<Anime> trendingList = [
  Anime(title: "Jujutsu Kaisen", image: "https://i.ibb.co/KpsCLmBg/imager.jpg"),
  Anime(title: "Wang Ling", image: "https://i.ibb.co/yFRNxJbG/o.jpg"),
  Anime(title: "Tokyo Revengers", image: "https://i.ibb.co/YFg2hKvf/j.jpg"),
  Anime(title: "Flight aur Fight", image: "https://i.ibb.co/jvVk3XSY/g.jpg"),
  Anime(title: "Classroom of the elite", image: "https://i.ibb.co/vxJtwkcX/k.jpg"),
];

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark(), home: const MainScreen());
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [const HomeScreen(), const SearchPage(), const Center(child: Text("Categories")), const Center(child: Text("Fav")), const Center(child: Text("Account"))][_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, selectedItemColor: Colors.deepPurple,
        currentIndex: _index, onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Fav"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AnimeMX", style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold))),
      body: ListView(children: [
        CarouselSlider.builder(itemCount: sliderList.length, options: CarouselOptions(height: 200, autoPlay: true), itemBuilder: (c, i, r) => ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(sliderList[i].image, fit: BoxFit.cover))),
        const Padding(padding: EdgeInsets.all(15), child: Text("Trending Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        SizedBox(height: 200, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: trendingList.length, itemBuilder: (c, i) => Container(width: 130, margin: const EdgeInsets.only(left: 15), child: Column(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(trendingList[i].image, fit: BoxFit.cover))), Text(trendingList[i].title, overflow: TextOverflow.ellipsis)])))),
      ]),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search"), backgroundColor: Colors.transparent),
      body: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(decoration: InputDecoration(hintText: "Search anime...", filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 20),
        const Text("Recent Searches", style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(title: const Text("Naruto"), trailing: const Icon(Icons.close)),
        const Text("Trending Searches", style: TextStyle(fontWeight: FontWeight.bold)),
        const Text("1. Solo Leveling\n2. Jujutsu Kaisen"),
      ])),
    );
  }
}