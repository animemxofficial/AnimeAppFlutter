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
  Anime(title: "Naruto", image: "https://i.ibb.co/YFg2hKvf/j.jpg"),
  Anime(title: "Demon Slayer", image: "https://i.ibb.co/yFRNxJbG/o.jpg"),
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
  final List<Widget> _pages = [const HomeScreen(), const Center(child: Text("Dubbed")), const Center(child: Text("Fav")), const Center(child: Text("Account"))];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
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
          // Auto Slide Banner
          CarouselSlider.builder(
            itemCount: animeList.length,
            options: CarouselOptions(height: 220, autoPlay: true, enlargeCenterPage: true),
            itemBuilder: (c, i, r) => ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(animeList[i].image, fit: BoxFit.cover, width: double.infinity)),
          ),
          
          // Top Picks
          Container(
            margin: const EdgeInsets.all(15), padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Top Picks for You", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("New episodes now!", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
              ElevatedButton(onPressed: () {}, child: const Text("Watch")),
            ]),
          ),

          // Trending
          const Padding(padding: EdgeInsets.only(left: 15, bottom: 10), child: Text("Trending Now 🔥", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          SizedBox(height: 210, child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: animeList.length,
            itemBuilder: (ctx, i) => Container(
              width: 130, margin: const EdgeInsets.only(left: 15),
              child: Column(children: [
                Container(height: 170, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), image: DecorationImage(image: NetworkImage(animeList[i].image), fit: BoxFit.cover))),
                const SizedBox(height: 5),
                Text(animeList[i].title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}