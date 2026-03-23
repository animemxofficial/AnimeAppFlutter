import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const AnimeMX());
}

// Data Model (Added dubColor for dynamic tags)
class Anime {
  final String title, image, rating, dubStatus, season, status, views;
  final bool isNew;
  final Color dubColor;

  Anime({
    required this.title,
    required this.image,
    this.rating = "PG-13",
    this.dubStatus = "DUB",
    this.isNew = false,
    this.season = "Season 1",
    this.status = "Ongoing",
    this.views = "1.1M",
    this.dubColor = const Color(0xFFFF4D4D), // Default Red
  });
}

// Dummy Data with Specific Tag Colors
final List<Anime> animeData =[
  Anime(title: "Jujutsu Kaisen", image: "https://i.ibb.co/KpsCLmBg/imager.jpg", views: "5.2K", dubColor: const Color(0xFFFF4D4D)), // Red
  Anime(title: "Eminence in Shadow", image: "https://i.ibb.co/L0x9WvY/the-eminence-in-shadow.jpg", views: "202", dubColor: const Color(0xFF7A5CFF)), // Purple
  Anime(title: "Classroom of Elite", image: "https://i.ibb.co/vxJtwkcX/k.jpg", season: "Season 3", status: "Completed", views: "3.8K", dubColor: const Color(0xFF4DA6FF)), // Blue
  Anime(title: "Tokyo Revengers", image: "https://i.ibb.co/YFg2hKvf/j.jpg", views: "4.1K", dubColor: const Color(0xFFFF9F43)), // Orange
  Anime(title: "Wang Ling", image: "https://i.ibb.co/yFRNxJbG/o.jpg", views: "3.1K", dubStatus: "MIX", dubColor: const Color(0xFF00C853)), // Green
];

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        primaryColor: const Color(0xFF6A5AE0),
        useMaterial3: true,
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
  final List<Widget> _pages =[const HomeScreen(), const BrowseScreen(), const Center(child: Text("Dubs")), const Center(child: Text("Profile"))];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedItemColor: const Color(0xFF6A5AE0),
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const[
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: "Explore"),
            BottomNavigationBarItem(icon: Icon(Icons.manage_search_outlined), activeIcon: Icon(Icons.manage_search), label: "Browse"),
            BottomNavigationBarItem(icon: Icon(Icons.headphones_outlined), activeIcon: Icon(Icons.headphones), label: "Dubs"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:[
                        const Text("AnimeMX", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF6A5AE0), letterSpacing: -0.5)),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children:[
                          Icon(Icons.search, color: Colors.grey[600]),
                          const SizedBox(width: 10),
                          Text("Search anime, movies, series...", style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Icon(Icons.mic_none, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              CarouselSlider.builder(
                itemCount: 3,
                options: CarouselOptions(height: 180, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.9),
                itemBuilder: (ctx, i, real) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network("https://i.ibb.co/rW2Zk9B/images.jpg", fit: BoxFit.cover, width: double.infinity)),
                ),
              ),

              const SizedBox(height: 24),
              
              _buildCategorySection("🔥 Trending Now", animeData),
              _buildCategorySection("👀 Most Viewed", animeData.reversed.toList()),
              _buildCategorySection("⏰ Latest Episodes", animeData),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, List<Anime> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
        // YAHAN HEIGHT 280 KI HAI TAAKI CARD (250px) AUR SHADOW FIT HO SAKE
        SizedBox(
          height: 280, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Vertical padding for shadow
            itemCount: list.length,
            itemBuilder: (context, index) {
              return AnimePosterCard(anime: list[index]);
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ==========================================
// 🔥 NEW WHITE THEME ANIME CARD DESIGN 🔥
// ==========================================
class AnimePosterCard extends StatefulWidget {
  final Anime anime;
  const AnimePosterCard({super.key, required this.anime});

  @override
  State<AnimePosterCard> createState() => _AnimePosterCardState();
}

class _AnimePosterCardState extends State<AnimePosterCard> {
  bool _isTapped = false; // Hover/Tap Animation Handle Karne Ke Liye

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) {
        setState(() => _isTapped = false);
        Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsPage(anime: widget.anime)));
      },
      onTapCancel: () => setState(() => _isTapped = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        // Scale Animation on Tap
        transform: Matrix4.identity()..scale(_isTapped ? 0.97 : 1.0),
        width: 170, // Exact Width requested
        height: 250, // Exact Height requested
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF), // White Theme Background
          borderRadius: BorderRadius.circular(18), // 18px radius
          boxShadow:[
            BoxShadow(
              color: Colors.black.withOpacity(0.08), // 0.08 opacity shadow
              blurRadius: 20, 
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              // TOP 70% AREA: POSTER
              Expanded(
                flex: 7, 
                child: Stack(
                  children:[
                    // Poster Image
                    Image.network(widget.anime.image, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                    
                    // Light Gradient Overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                            begin: Alignment.bottomCenter, 
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),

                    // PG-13 Tag (Top Left)
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(20)),
                        child: Text(widget.anime.rating, style: const TextStyle(color: Color(0xFF333333), fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    
                    // DUB Tag (Top Right - Dynamic Colored)
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: widget.anime.dubColor, borderRadius: BorderRadius.circular(20)),
                        child: Text(widget.anime.dubStatus, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),

              // BOTTOM 30% AREA: TEXT INFO
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:[
                      // Anime Name
                      Text(widget.anime.title, style: const TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w700, fontSize: 15, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      // Season Info
                      Text("${widget.anime.season} • ${widget.anime.status}", style: const TextStyle(color: Color(0xFF666666), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      // Views Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children:[
                          const Icon(Icons.remove_red_eye_rounded, color: Color(0xFF888888), size: 14),
                          const SizedBox(width: 5),
                          Text("${widget.anime.views} Views", style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  final Anime anime;
  const DetailsPage({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(anime.title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(child: Text("Details page for ${anime.title} coming soon!")),
    );
  }
}

// BROWSE SCREEN (Unchanged)
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Color(0xFFF8F9FA), body: Center(child: Text("Browse Page")));
  }
}