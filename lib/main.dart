import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() => runApp(const AnimeMX());

class Anime {
  final String title, image;
  Anime({required this.title, required this.image});
}

// Data
final List<Anime> bannerList = [
  Anime(title: "Slice Pizza", image: "https://i.ibb.co/rW2Zk9B/images.jpg"),
  Anime(title: "Solo Leaving", image: "https://i.ibb.co/C3rhjGv3/images-1.jpg"),
];

final List<Anime> trendingList = [
  Anime(title: "Jujutsu Kaisen", image: "https://i.ibb.co/KpsCLmBg/imager.jpg"),
  Anime(title: "Wang Ling", image: "https://i.ibb.co/yFRNxJbG/o.jpg"),
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
  final List<Widget> _pages = [const HomeScreen(), const Center(child: Text("Dubbed")), const Center(child: Text("Fav")), const Center(child: Text("Acc"))];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.play_circle), label: "Dubbed"),
          NavigationDestination(icon: Icon(Icons.favorite), label: "Fav"),
          NavigationDestination(icon: Icon(Icons.person), label: "Account"),
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
      appBar: AppBar(title: const Text("AnimeMX"), actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => showSearch(context: context, delegate: AnimeSearch()))]),
      body: ListView(children: [
        // SLIDER KA CHANGE YAHAN HAI:
        CarouselSlider.builder(
          itemCount: bannerList.length,
          itemBuilder: (c, i, r) => ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(bannerList[i].image, fit: BoxFit.cover)),
          options: CarouselOptions(
            autoPlay: true, 
            height: 200, 
            viewportFraction: 1.0, // Yeh card ko poori width dega
            enlargeCenterPage: false,
          ),
        ),
        const Padding(padding: EdgeInsets.all(15), child: Text("Trending Now", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        SizedBox(height: 200, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: trendingList.length, itemBuilder: (c, i) => Container(width: 130, margin: const EdgeInsets.only(left: 15), child: Column(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(trendingList[i].image, fit: BoxFit.cover))), Text(trendingList[i].title, overflow: TextOverflow.ellipsis)])))),
      ]),
    );
  }
}

class AnimeSearch extends SearchDelegate {
  // ... Search wala code waisa hi hai ...
}