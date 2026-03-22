import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

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
];

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Default Font use hoga
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.deepPurple,
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
    const Center(child: Text("Favourite")),
    const Center(child: Text("Account")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: "Dubbed"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: "Favourite"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Account"),
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
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          CarouselSlider.builder(
            itemCount: animeList.length,
            options: CarouselOptions(height: 200, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.9),
            itemBuilder: (ctx, i, real) => Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
              child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(animeList[i].image, fit: BoxFit.cover)),
            ),
          ),
          const Padding(padding: EdgeInsets.all(15), child: Text("Trending Now", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          SizedBox(height: 200, child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: animeList.length,
            itemBuilder: (ctx, i) => Container(
              width: 130, margin: const EdgeInsets.only(left: 15),
              child: Column(children: [
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(animeList[i].image, fit: BoxFit.cover))),
                const SizedBox(height: 8),
                Text(animeList[i].title, style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}