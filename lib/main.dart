import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() => runApp(const AnimeMX());

// Data Model
class Anime {
  final String title, image, rating, dubStatus, season, status, views;
  final bool isNew;

  Anime({
    required this.title,
    required this.image,
    this.rating = "13+",
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
  Anime(title: "Eminence in Shadow", image: "https://i.ibb.co/L0x9WvY/the-eminence-in-shadow.jpg", views: "202"),
  Anime(title: "Classroom of Elite", image: "https://i.ibb.co/vxJtwkcX/k.jpg", season: "Season 3", status: "Completed", views: "3.8K"),
  Anime(title: "Tokyo Revengers", image: "https://i.ibb.co/YFg2hKvf/j.jpg", views: "4.1K"),
  Anime(title: "Wang Ling", image: "https://i.ibb.co/yFRNxJbG/o.jpg", views: "3.1K", dubStatus: "MIX"),
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
  final List<Widget> _pages =[const HomeScreen(), const Center(child: Text("Browse")), const Center(child: Text("Dubs")), const Center(child: Text("Profile"))];

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
        // YAHAN CARDS KI HEIGHT KAM KI HAI (260 se 210 ki)
        SizedBox(
          height: 210, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return AnimePosterCard(anime: list[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class AnimePosterCard extends StatelessWidget {
  final Anime anime;
  const AnimePosterCard({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    // CLICK KARNE PAR DETAILS PAGE OPEN HOGA
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsPage(anime: anime)));
      },
      child: Container(
        width: 170, // YAHAN WIDTH BADHA DI HAI (155 se 170 ki, chouda karne ke liye)
        margin: const EdgeInsets.only(right: 14, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16),
          boxShadow:[
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children:[
              Image.network(anime.image, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:[Colors.black.withOpacity(0.9), Colors.transparent],
                      begin: Alignment.bottomCenter, end: Alignment.center,
                    ),
                  ),
                ),
              ),

              // TOP BADGES (Sirf DUB tag rakha hai, 13+ hata diya hai)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF6A5AE0), borderRadius: BorderRadius.circular(6)),
                  child: Text(anime.dubStatus, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ),
              
              Positioned(
                bottom: 12, left: 10, right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children:[
                    Text(anime.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("${anime.season} • ${anime.views} Views", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// NAYA DETAILS PAGE JO CLICK KARNE PAR KHULEGA
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Image.network(anime.image, width: double.infinity, height: 260, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Text(anime.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text("${anime.season} • ${anime.views} Views • ${anime.dubStatus}", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 24),
                  
                  // Watch Now Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A5AE0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      onPressed: () {
                        // Yahan aage chalkar Video Player add hoga
                      }, 
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      label: const Text("Watch Episode 1", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text("Synopsis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text("A thrilling journey of ${anime.title}. Dive into the fantastic world filled with amazing characters and an unforgettable storyline. Watch it now on AnimeMX in high quality.", style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}