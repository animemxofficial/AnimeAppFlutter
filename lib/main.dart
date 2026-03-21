import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() => runApp(const AnimeMX());

class Anime {
  final String title; final String image; final String views;
  Anime({required this.title, required this.image, required this.views});
}

final List<Anime> animeList = [
  Anime(title: "Classroom of the Elite", image: "https://i.ibb.co/KpsCLmBg/imager.jpg", views: "3.4K"),
  Anime(title: "Solo Leveling", image: "https://i.ibb.co/vxJtwkcX/k.jpg", views: "5.2K"),
  Anime(title: "One Piece", image: "https://i.ibb.co/jvVk3XSY/g.jpg", views: "8.1K"),
  Anime(title: "Naruto", image: "https://i.ibb.co/YFg2hKvf/j.jpg", views: "4.5K"),
];

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(primaryColor: Colors.deepPurple),
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
  final List<Widget> _pages = [const HomeScreen(), const Center(child: Text("Dubbed")), const Center(child: Text("Favourite")), const Center(child: Text("Account"))];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, selectedItemColor: Colors.deepPurple,
        currentIndex: _index, onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: "Dubbed"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favourite"),
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
      appBar: AppBar(
        title: const Text("AnimeMX", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.search, color: Colors.black), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())))],
      ),
      body: ListView(
        children: [
          // 1. Auto Slider (Full Width)
          CarouselSlider.builder(
            itemCount: animeList.length,
            options: CarouselOptions(height: 220, autoPlay: true, viewportFraction: 1.0),
            itemBuilder: (ctx, i, real) => Image.network(animeList[i].image, fit: BoxFit.cover, width: double.infinity),
          ),
          
          // 2. Top Picks (Modern Button)
          Container(
            margin: const EdgeInsets.all(15), padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Top Picks for You", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("New episodes out!", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
              ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text("Watch", style: TextStyle(color: Colors.white, fontSize: 12))),
            ]),
          ),

          // 3. Trending & Most Viewed
          _buildAnimeSection("Trending Now 🔥"),
          _buildAnimeSection("Most Viewed 👁️"),
        ],
      ),
    );
  }

  Widget _buildAnimeSection(String title) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.all(15), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      SizedBox(height: 220, child: ListView.builder( // Lamba card height
        scrollDirection: Axis.horizontal,
        itemCount: animeList.length,
        itemBuilder: (ctx, i) => Container(
          width: 140, // Chaunda card width
          margin: const EdgeInsets.only(left: 15),
          child: Column(children: [
            Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(15), image: DecorationImage(image: NetworkImage(animeList[i].image), fit: BoxFit.cover)))),
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(animeList[i].title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
            Text("${animeList[i].views} views", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ),
      )),
    ]);
  }
}

// Search Page
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Search Anime")), body: const Center(child: Text("Search feature coming soon!")));