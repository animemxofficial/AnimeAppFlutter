import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() => runApp(const AnimeMX());

// Data Model
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

// Dummy Data
final List<Anime> animeData =[
  Anime(title: "Jujutsu Kaisen", image: "https://i.ibb.co/KpsCLmBg/imager.jpg", views: "5.2K", isNew: true),
  Anime(title: "The Eminence in Shadow", image: "https://i.ibb.co/L0x9WvY/the-eminence-in-shadow.jpg", starRating: 8.3, views: "202"),
  Anime(title: "Classroom of the Elite", image: "https://i.ibb.co/vxJtwkcX/k.jpg", season: "Season 3", status: "Completed", views: "3.8K"),
  Anime(title: "Tokyo Revengers", image: "https://i.ibb.co/YFg2hKvf/j.jpg", views: "4.1K"),
  Anime(title: "Wang Ling", image: "https://i.ibb.co/yFRNxJbG/o.jpg", views: "3.1K", dubStatus: "MIX O/D"),
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
  final List<Widget> _pages =[const HomeScreen(), const Center(child: Text("Search")), const Center(child: Text("Categories")), const Center(child: Text("Favorites")), const Center(child: Text("Account"))];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const[
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
          children:[
            CarouselSlider.builder(itemCount: 3, options: CarouselOptions(height: 200, autoPlay: true, enlargeCenterPage: true), itemBuilder: (ctx, i, real) => ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network("https://i.ibb.co/rW2Zk9B/images.jpg", fit: BoxFit.cover, width: double.infinity))),
            const SizedBox(height: 24),
            
            // Sections
            _buildCategorySection("🔥 Trending Now", animeData),
            _buildCategorySection("🏆 Popular", animeData.reversed.toList()),
            _buildCategorySection("⏰ Latest Episodes", animeData),
            _buildCategorySection("💖 Romance", animeData),
            _buildCategorySection("⚔️ Action", animeData),
            
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
      children:[
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        // YAHAN CARD KI HEIGHT BADHA DI HAI TAAYKI LAMBA CARD FIT HO SAKE
        SizedBox(height: 270, child: ListView.builder(
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

// EXACT MATCH ANIME CARD DESIGN
class AnimePosterCard extends StatelessWidget {
  final Anime anime;
  const AnimePosterCard({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165, // Card ki width badhayi (screenshot match karne ke liye)
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Faint outline jo screenshot mein hai
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1), 
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children:[
            // Background Image
            Image.network(anime.image, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            
            // Smooth Dark Gradient Overlay (Neeche andhera taaki text dikhe)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:[Colors.black.withOpacity(0.95), Colors.black.withOpacity(0.4), Colors.transparent],
                  stops: const[0.0, 0.5, 1.0],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),

            // Top Badges (PG-13 and DUB)
            Positioned(
              top: 10, left: 10, right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  // PG-13 (White Solid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(8)),
                    child: Text(anime.rating, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  // DUB (Translucent Glassmorphism)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15), 
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(anime.dubStatus, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            // Bottom Info (Title, Season, Views)
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children:[
                  Text(anime.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text("${anime.season} • ${anime.status}", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children:[
                      Icon(Icons.remove_red_eye_outlined, color: Colors.white.withOpacity(0.7), size: 14),
                      const SizedBox(width: 4),
                      Text("${anime.views} Views", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}