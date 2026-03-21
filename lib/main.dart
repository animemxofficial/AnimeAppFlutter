import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() => runApp(const AnimeMX());

class Anime {
  final String title;
  final String image;
  final String views;
  Anime({required this.title, required this.image, required this.views});
}

final List<Anime> animeList = [
  Anime(title: "Demon Slayer", image: "https://i.ibb.co/yFRNxJbG/o.jpg", views: "3.4K"),
  Anime(title: "Jujutsu Kaisen", image: "https://i.ibb.co/KpsCLmBg/imager.jpg", views: "5.2K"),
  Anime(title: "Solo Leveling", image: "https://i.ibb.co/vxJtwkcX/k.jpg", views: "2.8K"),
  Anime(title: "One Piece", image: "https://i.ibb.co/jvVk3XSY/g.jpg", views: "8.1K"),
];

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple, scaffoldBackgroundColor: Colors.white),
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
  final List<Widget> _pages = [const HomeScreen(), const Center(child: Text("Dubbed")), const Center(child: Text("Favourite")), const AccountPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
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
      appBar: AppBar(title: const Text("AnimeMX", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0),
      body: ListView(
        children: [
          // 1. Auto Slider
          CarouselSlider.builder(
            itemCount: animeList.length,
            options: CarouselOptions(height: 200, autoPlay: true, enlargeCenterPage: true),
            itemBuilder: (ctx, i, real) => ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(animeList[i].image, fit: BoxFit.cover, width: double.infinity)),
          ),
          // 2. Top Picks Box
          Container(margin: const EdgeInsets.all(15), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Top Picks", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("New episodes!", style: TextStyle(color: Colors.grey, fontSize: 12))]), ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, minimumSize: const Size(70, 30)), child: const Text("Watch", style: TextStyle(color: Colors.black, fontSize: 10)))])),
          // 3. Trending Header
          const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Text("Trending Now 🔥", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          _buildAnimeGrid(animeList),
          // 4. Most Viewed
          const Padding(padding: EdgeInsets.all(15), child: Text("Most Viewed 👁️", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          _buildAnimeGrid(animeList.reversed.toList()),
        ],
      ),
    );
  }

  Widget _buildAnimeGrid(List<Anime> list) {
    return SizedBox(height: 220, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: list.length, itemBuilder: (ctx, i) => Container(width: 140, margin: const EdgeInsets.only(left: 15), child: Column(children: [Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(list[i].image), fit: BoxFit.cover)))), Text(list[i].title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)), Text("${list[i].views} views", style: const TextStyle(fontSize: 10, color: Colors.grey))]))));
  }
}

// Account Page
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Account")), body: ListView(children: const [ListTile(leading: Icon(Icons.receipt), title: Text("Activity")), ListTile(leading: Icon(Icons.settings), title: Text("Settings")), ListTile(leading: Icon(Icons.logout), title: Text("Log Out"))]));
  }
}