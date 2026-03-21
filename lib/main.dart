import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() => runApp(const AnimeMX());

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.poppins().fontFamily,
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
    const Center(child: Text("Dubbed Page")), 
    const Center(child: Text("Favourite Page")), 
    const Center(child: Text("Account Page"))
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6A5AE0),
        unselectedItemColor: Colors.grey[400],
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.video_library_rounded), label: "Dubbed"),
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
        title: const Text("AnimeMX", style: TextStyle(color: Color(0xFF6A5AE0), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.search, color: Colors.black), onPressed: () {})],
      ),
      body: ListView(
        children: [
          CarouselSlider.builder(
            itemCount: 4,
            options: CarouselOptions(height: 220, autoPlay: true, viewportFraction: 0.9, enlargeCenterPage: true),
            itemBuilder: (ctx, i, real) => Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]),
              child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network("https://i.ibb.co/7tppGVqq/images.jpg", fit: BoxFit.cover)),
            ),
          ),
          _buildAnimeSection("Trending Now 🔥"),
          _buildAnimeSection("Most Viewed 👁️"),
        ],
      ),
    );
  }

  Widget _buildAnimeSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.all(15), child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        SizedBox(
          height: 240, // Cards thode bade ho gaye
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (ctx, i) => Container(
              width: 150, // Cards thode chaunde (wide) ho gaye
              margin: const EdgeInsets.only(left: 15),
              child: Column(
                children: [
                  Container(
                    height: 190,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                      image: const DecorationImage(image: NetworkImage("https://i.ibb.co/KpsCLmBg/imager.jpg"), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("Anime Name", style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}