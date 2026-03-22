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
        CarouselSlider.builder(itemCount: bannerList.length, itemBuilder: (c, i, r) => ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(bannerList[i].image, fit: BoxFit.cover)), options: CarouselOptions(autoPlay: true, height: 200)),
        const Padding(padding: EdgeInsets.all(15), child: Text("Trending Now", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        SizedBox(height: 200, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: trendingList.length, itemBuilder: (c, i) => Container(width: 130, margin: const EdgeInsets.only(left: 15), child: Column(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(trendingList[i].image, fit: BoxFit.cover))), Text(trendingList[i].title, overflow: TextOverflow.ellipsis)])))),
      ]),
    );
  }
}

// Search Page Logic
class AnimeSearch extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = "")];
  @override
  Widget buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  @override
  Widget buildResults(BuildContext context) => Center(child: Text("Results for $query"));
  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView(children: [
      const Padding(padding: EdgeInsets.all(15), child: Text("Recent Searches", style: TextStyle(fontWeight: FontWeight.bold))),
      ListTile(title: const Text("Naruto"), trailing: const Icon(Icons.close)),
      const Padding(padding: EdgeInsets.all(15), child: Text("Trending Searches", style: TextStyle(fontWeight: FontWeight.bold))),
      const ListTile(leading: Text("1"), title: Text("Solo Leveling")),
      const Padding(padding: EdgeInsets.all(15), child: Text("Browse by Genre", style: TextStyle(fontWeight: FontWeight.bold))),
      Wrap(children: ["Action", "Comedy", "Drama", "Romance"].map((g) => Chip(label: Text(g))).toList()),
    ]);
  }
}