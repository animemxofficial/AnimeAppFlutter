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

// Data Model
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
    this.dubColor = const Color(0xFFFF4D4D),
  });
}

// Dummy Data
final List<Anime> animeData =[
  Anime(title: "Jujutsu Kaisen", image: "https://i.ibb.co/KpsCLmBg/imager.jpg", views: "5.2K", dubColor: const Color(0xFFFF4D4D)), 
  Anime(title: "Eminence in Shadow", image: "https://i.ibb.co/L0x9WvY/the-eminence-in-shadow.jpg", views: "202", dubColor: const Color(0xFF7A5CFF)), 
  Anime(title: "Classroom of Elite", image: "https://i.ibb.co/vxJtwkcX/k.jpg", season: "Season 3", status: "Completed", views: "3.8K", dubColor: const Color(0xFF4DA6FF)), 
  Anime(title: "Tokyo Revengers", image: "https://i.ibb.co/YFg2hKvf/j.jpg", views: "4.1K", dubColor: const Color(0xFFFF9F43)), 
  Anime(title: "Wang Ling", image: "https://i.ibb.co/yFRNxJbG/o.jpg", views: "3.1K", dubStatus: "MIX", dubColor: const Color(0xFF00C853)), 
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
                  children:[
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
        SizedBox(
          height: 280, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
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

class AnimePosterCard extends StatefulWidget {
  final Anime anime;
  const AnimePosterCard({super.key, required this.anime});

  @override
  State<AnimePosterCard> createState() => _AnimePosterCardState();
}

class _AnimePosterCardState extends State<AnimePosterCard> {
  bool _isTapped = false; 

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
        transform: Matrix4.identity()..scale(_isTapped ? 0.97 : 1.0),
        width: 170, 
        height: 250, 
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF), 
          borderRadius: BorderRadius.circular(18), 
          boxShadow:[
            BoxShadow(
              color: Colors.black.withOpacity(0.08), 
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
              Expanded(
                flex: 7, 
                child: Stack(
                  children:[
                    Image.network(widget.anime.image, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
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
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(20)),
                        child: Text(widget.anime.rating, style: const TextStyle(color: Color(0xFF333333), fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
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
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:[
                      Text(widget.anime.title, style: const TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w700, fontSize: 15, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text("${widget.anime.season} • ${widget.anime.status}", style: const TextStyle(color: Color(0xFF666666), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const Spacer(),
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

// ==========================================
// 🔥 NEW PREMIUM DETAILS PAGE 🔥
// ==========================================
class DetailsPage extends StatelessWidget {
  final Anime anime;
  const DetailsPage({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    // Theme Colors based on screenshot
    const Color softBgColor = Color(0xFFEFEAF5); // Soft Lavender background
    const Color darkPurpleText = Color(0xFF1C0D35); // Deep Purple text
    const Color tagBgColor = Color(0xFFD6C8EE); // Light purple for tags
    const Color activeBtnColor = Color(0xFF5B3C88); // Dark Purple for buttons

    return Scaffold(
      backgroundColor: softBgColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            // 1. Hero Image with Overlay and Back Button
            Stack(
              children:[
                Image.network(
                  anime.image, 
                  width: double.infinity, 
                  height: 250, 
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                // Gradient blending to background
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [softBgColor, Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                ),
                // Back Button
                Positioned(
                  top: 45, left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, shadows:[Shadow(color: Colors.black45, blurRadius: 10)]),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  // 2. Anime Title
                  Text(
                    anime.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: darkPurpleText, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 14),

                  // 3. Genre & Info Tags
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children:[
                      _buildTag(Icons.closed_caption, "Dub", tagBgColor, darkPurpleText),
                      _buildTag(Icons.verified_user_rounded, "U/A 16+", tagBgColor, darkPurpleText),
                      _buildTag(null, "Thriller", tagBgColor, darkPurpleText),
                      _buildTag(null, "Mystery", tagBgColor, darkPurpleText),
                      _buildTag(null, "Drama", tagBgColor, darkPurpleText),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 4. Description
                  Text(
                    "Kiyotaka Ayanokouji enters the prestigious Tokyo Metropolitan Advanced Nurturing High School, which is dedicated to fostering the best students...",
                    style: TextStyle(fontSize: 14, color: darkPurpleText.withOpacity(0.85), height: 1.5),
                  ),
                  const SizedBox(height: 6),
                  const Text("Read More", style: TextStyle(color: activeBtnColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 30),

                  // 5. Seasons Section
                  const Text("Seasons", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: darkPurpleText)),
                  const SizedBox(height: 14),
                  Row(
                    children:[
                      _buildSeasonTab("Season 1", true, activeBtnColor, tagBgColor),
                      const SizedBox(width: 10),
                      _buildSeasonTab("Season 2", false, darkPurpleText, tagBgColor),
                      const SizedBox(width: 10),
                      _buildSeasonTab("Season 3", false, darkPurpleText, tagBgColor),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 6. Episodes List
                  const Text("Episodes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: darkPurpleText)),
                  const SizedBox(height: 14),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return _buildEpisodeItem(index + 1, anime.image, darkPurpleText);
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(IconData? icon, String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:[
          if (icon != null) ...[Icon(icon, size: 14, color: textColor), const SizedBox(width: 6)],
          Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSeasonTab(String text, bool isActive, Color activeColor, Color inactiveBg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : activeColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEpisodeItem(int episodeNumber, String image, Color darkPurple) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children:[
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              image, 
              width: 120, height: 70, 
              fit: BoxFit.cover, alignment: Alignment.topCenter,
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text("Episode $episodeNumber", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkPurple)),
                const SizedBox(height: 4),
                Text("24 min", style: TextStyle(fontSize: 13, color: darkPurple.withOpacity(0.6), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // Play Icon
          IconButton(
            icon: Icon(Icons.play_circle_fill, color: darkPurple, size: 40),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// BROWSE SCREEN (Unchanged)
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
                child: TextField(decoration: InputDecoration(hintText: "Search anime, movies, episodes...", hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15), prefixIcon: Icon(Icons.search, color: Colors.grey[600]), suffixIcon: Icon(Icons.cancel, color: Colors.grey[400]), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16))),
              ),
              const SizedBox(height: 24),
              const Text("Recent Searches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              _buildRecentItem("Naruto"), _buildRecentItem("One Piece"), _buildRecentItem("Demon Slayer"), _buildRecentItem("Attack on Titan"),
              const SizedBox(height: 24),
              const Text("Trending Searches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              Row(children:[Expanded(child: Column(children:[_buildTrendingItem("1", "Solo Leveling"), _buildTrendingItem("3", "Chainsaw Man")])), Expanded(child: Column(children:[_buildTrendingItem("2", "Jujutsu Kaisen"), _buildTrendingItem("4", "Tokyo Revengers")]))]),
              const SizedBox(height: 24),
              const Text("Browse by Genre", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.2,
                children:[
                  _buildGenreCard("Action", "Action", Icons.sports_martial_arts, const Color(0xFFFFEAEA), Colors.redAccent),
                  _buildGenreCard("Comedy", "Hilarity", Icons.sentiment_very_satisfied, const Color(0xFFF0E6FF), const Color(0xFF6A5AE0)),
                  _buildGenreCard("Drama", "Series", Icons.masks, const Color(0xFFE6F2FF), Colors.blueAccent),
                  _buildGenreCard("Romance", "Love", Icons.favorite, const Color(0xFFFFE6F0), Colors.pinkAccent),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentItem(String title) { return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)), Row(children:[Icon(Icons.close, size: 18, color: Colors.grey[500]), const SizedBox(width: 12), Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400])])])); }
  Widget _buildTrendingItem(String num, String title) { return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children:[Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)), child: Center(child: Text(num, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)))), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87), overflow: TextOverflow.ellipsis))])); }
  Widget _buildGenreCard(String title, String subtitle, IconData icon, Color bgColor, Color iconColor) { return Container(decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children:[Icon(icon, size: 30, color: iconColor), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children:[Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)), Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.5)))])])); }
}