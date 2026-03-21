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
  Anime(title: "Classroom", image: "https://i.ibb.co/KpsCLmBg/imager.jpg", views: "3.4K"),
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
      theme: ThemeData(
        // Purple Gradient Theme
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A5AE0), Color(0xFF7B6CF6), Color(0xFF8B7BFF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: const MainScreen(),
      ),
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
    const Center(child: Text("Dubbed", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Favourite", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Account", style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("AnimeMX", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {})],
      ),
      body: ListView(
        children: [
          CarouselSlider.builder(
            itemCount: animeList.length,
            options: CarouselOptions(height: 200, autoPlay: true, viewportFraction: 1.0),
            itemBuilder: (ctx, i, real) => Image.network(animeList[i].image, fit: BoxFit.cover, width: double.infinity),
          ),
          const Padding(padding: EdgeInsets.all(15), child: Text("Trending Now 🔥", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
          SizedBox(height: 200, child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: animeList.length,
            itemBuilder: (ctx, i) => Container(
              width: 140, margin: const EdgeInsets.only(left: 15),
              child: Column(children: [
                Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(15), image: DecorationImage(image: NetworkImage(animeList[i].image), fit: BoxFit.cover)))),
                Text(animeList[i].title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}