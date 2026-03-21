import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() => runApp(const AnimeMX());

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
    const Center(child: Text("Dubbed Anime")),
    const Center(child: Text("Favourites")),
    const Center(child: Text("Account")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: "Dubbed"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: "Favourite"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Account"),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<String> slides = const [
    "https://i.ibb.co/7tppGVqq/images.jpg",
    "https://i.ibb.co/bg2q2Ldn/images-1.jpg",
    "https://i.ibb.co/Wvp6sGN0/images-2.jpg",
    "https://i.ibb.co/Cjj478G/images-3.jpg"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AnimeMX", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0),
      body: ListView(
        children: [
          // 1. Auto Slider
          CarouselSlider.builder(
            itemCount: slides.length,
            options: CarouselOptions(height: 200, autoPlay: true, enlargeCenterPage: true),
            itemBuilder: (ctx, i, realIdx) => ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(slides[i], fit: BoxFit.cover, width: double.infinity)),
          ),
          
          // 2. Top Picks (Small Button)
          Container(
            margin: const EdgeInsets.all(15), padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Top Picks for You", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("New episodes now!", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
              SizedBox(height: 30, child: ElevatedButton(onPressed: () {}, child: const Text("Watch", style: TextStyle(fontSize: 10)))),
            ]),
          ),

          // 3. Trending
          const Padding(padding: EdgeInsets.all(15), child: Text("Trending Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          SizedBox(height: 180, child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (ctx, i) => Container(width: 110, margin: const EdgeInsets.only(left: 15), child: Column(children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network("https://i.ibb.co/KpsCLmBg/imager.jpg", fit: BoxFit.cover))),
              const Text("Anime Name", overflow: TextOverflow.ellipsis),
            ])),
          )),
        ],
      ),
    );
  }
}