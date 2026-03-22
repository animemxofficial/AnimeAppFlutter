import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() => runApp(const AnimeMX());

// Updated Data Model
class Anime {
  final String title, image, rating, dubStatus, season, status, views;
  final double starRating;
  final bool isNew;

  Anime({
    required this.title,
    required this.image,
    this.rating = "PG-13",
    this.starRating = 8.1,
    this.dubStatus = "DUB",
    this.isNew = false,
    this.season = "Season 1",
    this.status = "Ongoing",
    this.views = "1.1M",
  });
}

// Updated Dummy Data
final List<Anime> animeData = [
  Anime(title: "Jujutsu Kaisen", image: "https://i.ibb.co/KpsCLmBg/imager.jpg", views: "5.2K", isNew: true),
  Anime(title: "The Eminence in Shadow", image: "https://i.ibb.co/L0x9WvY/the-eminence-in-shadow.jpg", starRating: 8.3, views: "202"),
  Anime(title: "Wang Ling", image: "https://i.ibb.co/yFRNxJbG/o.jpg", views: "3.1K", dubStatus: "MIX O/D"),
  Anime(title: "Tokyo Revengers", image: "https://i.ibb.co/YFg2hKvf/j.jpg", views: "4.5K"),
  Anime(title: "Classroom of the Elite", image: "https://i.ibb.co/vxJtwkcX/k.jpg", season: "Season 3", status: "Completed", views: "3.4K"),
];

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF0F0F0F)),
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
  final List<Widget> _pages = [const HomeScreen(), const Center(child: Text("Search")), const Center(child: Text("Categories")), const Center(child: Text("Favorites")), const Center(child: Text("Account"))];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.search), label: "Search"),
          NavigationDestination(icon: Icon(Icons.category), label: "Categories"),
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
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CarouselSlider.builder(itemCount: 3, options: CarouselOptions(height: 200, autoPlay: true, enlargeCenterPage: true), itemBuilder: (ctx, i, real) => ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network("https://i.ibb.co/rW2Zk9B/images.jpg", fit: BoxFit.cover, width: double.infinity))),
            const SizedBox(height: 24),
            _buildCategorySection("🔥 Trending Now", animeData),
            _buildCategorySection("🏆 Popular", animeData.reversed.toList()),
            _buildCategorySection("⏰ Latest Episodes", animeData),
            _buildCategorySection("💖 Romance", animeData),
            _buildCategorySection("⚔️ Action", animeData),
            // ... Yahan aur categories add kar sakte ho
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(onPressed: () {}, child: const Text("✨ Explore All Anime")),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, List<Anime> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        SizedBox(height: 250, child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return AnimePosterCard(anime: list[index]);
          },
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}

// Professional Anime Card
class AnimePosterCard extends StatelessWidget {
  final Anime anime;
  const AnimePosterCard({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          // Background Image
          ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(anime.image, fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
          
          // Gradient Overlay
          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [Colors.black.withOpacity(0.8), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter))),

          // Top Badges
          Positioned(
            top: 8, left: 8, right: 8,
            child: Row(
              children: [
                _Badge(text: anime.rating, color: Colors.white.withOpacity(0.8), textColor: Colors.black),
                const Spacer(),
                _Badge(text: anime.dubStatus, color: Colors.brown.withOpacity(0.8)),
              ],
            ),
          ),
          
          // Bottom Info
          Positioned(
            bottom: 8, left: 8, right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(anime.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2),
                const SizedBox(height: 4),
                Text("${anime.season} | ${anime.status}", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.visibility, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(anime.views, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for tags
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const _Badge({required this.text, required this.color, this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}