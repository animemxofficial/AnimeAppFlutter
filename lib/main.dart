import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() => runApp(const AnimeMX());

// Data Models
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.black,
          indicatorColor: Colors.deepPurple.withOpacity(0.5),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final List<Widget> _pages = [
    const HomeScreen(),
    const Center(child: Text("Dubbed")),
    const Center(child: Text("Favorites")),
    const Center(child: Text("Account")),
  ];
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
          NavigationDestination(icon: Icon(Icons.favorite), label: "Favorites"),
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
      appBar: AppBar(
        title: const Text("AnimeMX", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => showSearch(context: context, delegate: AnimeSearch()))],
      ),
      body: ListView(
        children: [
          CarouselSlider.builder(
            itemCount: bannerList.length,
            itemBuilder: (c, i, r) => ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(bannerList[i].image, fit: BoxFit.cover)),
            options: CarouselOptions(autoPlay: true, height: 200, viewportFraction: 1.0, enlargeCenterPage: false),
          ),
          const Padding(padding: EdgeInsets.all(15), child: Text("Trending Now", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: trendingList.length,
              itemBuilder: (c, i) => Container(
                width: 130, margin: const EdgeInsets.only(left: 15),
                child: Column(children: [
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(trendingList[i].image, fit: BoxFit.cover))),
                  Text(trendingList[i].title, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimeSearch extends SearchDelegate {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
      ),
    );
  }
  
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = "")];

  @override
  Widget buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => Center(child: Text("Showing results for: $query", style: const TextStyle(fontSize: 18)));
  
  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Recent Searches", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ListTile(title: const Text("Naruto"), trailing: const Icon(Icons.close), onTap: () => query = "Naruto"),
        ListTile(title: const Text("One Piece"), trailing: const Icon(Icons.close), onTap: () => query = "One Piece"),
        const SizedBox(height: 20),
        const Text("Trending Searches", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ListTile(leading: const Text("1"), title: const Text("Solo Leveling"), onTap: () => query = "Solo Leveling"),
        ListTile(leading: const Text("2"), title: const Text("Jujutsu Kaisen"), onTap: () => query = "Jujutsu Kaisen"),
        const SizedBox(height: 20),
        const Text("Browse by Genre", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: ["Action", "Comedy", "Drama", "Romance"]
              .map((g) => Chip(label: Text(g), backgroundColor: Colors.grey[800]))
              .toList(),
        ),
      ],
    );
  }
}