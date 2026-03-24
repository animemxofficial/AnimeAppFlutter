import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart'; // Video Player Import

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const AnimeMX());
}

// Data Model (Video URL added)
class Anime {
  final String title, image, rating, dubStatus, season, status, views, videoUrl;
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
    // Tera Direct Stream Google Drive Link
    this.videoUrl = "https://docs.google.com/uc?export=download&id=1DZBbeWTl_21PrnQLfozJ_p4Go69a1ue_",
  });
}

// Dummy Data
final List<Anime> animeData =[
  Anime(title: "Jujutsu Kaisen", image: "https://i.ibb.co/KpsCLmBg/imager.jpg", views: "5.2K", dubColor: const Color(0xFFFF4D4D)),
  Anime(title: "The Eminence in Shadow", image: "https://i.ibb.co/L0x9WvY/the-eminence-in-shadow.jpg", views: "202", dubColor: const Color(0xFF7A5CFF)),
  Anime(title: "Classroom of the Elite", image: "https://i.ibb.co/vxJtwkcX/k.jpg", season: "Season 3", status: "Completed", views: "3.8K", dubColor: const Color(0xFF4DA6FF)),
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

// ==========================================
// NAVIGATION BAR & MAIN SCREEN
// ==========================================
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
      extendBody: true,
      body: _pages[_index],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:[
              _buildNavItem(0, Icons.explore_outlined, "Explore"),
              _buildDivider(),
              _buildNavItem(1, Icons.manage_search_outlined, "Browse"),
              _buildDivider(),
              _buildNavItem(2, Icons.headphones_outlined, "Dubs"),
              _buildDivider(),
              _buildNavItem(3, Icons.person_outline, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(width: 1, height: 30, color: Colors.grey[300]);

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _index == index;
    return GestureDetector(
      onTap: () => setState(() => _index = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          Icon(icon, color: isSelected ? const Color(0xFF6A5AE0) : Colors.grey[500], size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSelected ? const Color(0xFF6A5AE0) : Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ==========================================
// HOME SCREEN
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
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
          height: 260, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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

// ==========================================
// ANIME CARD DESIGN
// ==========================================
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
        // CARD CLICK KARNE PE AB VIDEO DETAILS PAGE OPEN HOGA
        Navigator.push(context, MaterialPageRoute(builder: (context) => VideoDetailsPage(anime: widget.anime)));
      },
      onTapCancel: () => setState(() => _isTapped = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isTapped ? 0.96 : 1.0),
        width: 160, 
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1), 
          boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children:[
              Image.network(widget.anime.image, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:[Colors.black.withOpacity(0.95), Colors.black.withOpacity(0.3), Colors.transparent],
                      stops: const[0.0, 0.45, 1.0],
                      begin: Alignment.bottomCenter, 
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10, left: 10, right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Text(widget.anime.rating, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                      ),
                      child: Text(widget.anime.dubStatus, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 12, left: 12, right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children:[
                    Text(widget.anime.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text("${widget.anime.season} • ${widget.anime.status}", style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children:[
                        Icon(Icons.remove_red_eye_outlined, color: Colors.white.withOpacity(0.75), size: 14),
                        const SizedBox(width: 4),
                        Text("${widget.anime.views} Views", style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
                      ],
                    ),
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

// ==========================================
// BROWSE SCREEN
// ==========================================
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
              Row(children: [Expanded(child: Column(children:[_buildTrendingItem("1", "Solo Leveling"), _buildTrendingItem("3", "Chainsaw Man")])), Expanded(child: Column(children:[_buildTrendingItem("2", "Jujutsu Kaisen"), _buildTrendingItem("4", "Tokyo Revengers")]))]),
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

// ==========================================
// 🔥 PREMIUM VIDEO PLAYER & DETAILS PAGE 🔥
// ==========================================
class VideoDetailsPage extends StatefulWidget {
  final Anime anime;
  const VideoDetailsPage({super.key, required this.anime});

  @override
  State<VideoDetailsPage> createState() => _VideoDetailsPageState();
}

class _VideoDetailsPageState extends State<VideoDetailsPage> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  int _currentEpisode = 1;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.anime.videoUrl),
    )..initialize().then((_) {
        setState(() {});
        _controller.play(); 
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    const Color orangeAccent = Color(0xFFF47521);
    const Color darkBg = Color(0xFF0F0F0F);

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            // 1. VIDEO PLAYER SECTION
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children:[
                  _controller.value.isInitialized
                      ? VideoPlayer(_controller)
                      : const Center(child: CircularProgressIndicator(color: orangeAccent)),
                  
                  if (_showControls)
                    GestureDetector(
                      onTap: _toggleControls,
                      child: Container(
                        color: Colors.black54,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children:[
                                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
                                Row(
                                  children:[
                                    IconButton(icon: const Icon(Icons.cast, color: Colors.white), onPressed: () {}),
                                    IconButton(icon: const Icon(Icons.fullscreen, color: Colors.white), onPressed: () {}),
                                  ],
                                )
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children:[
                                IconButton(icon: const Icon(Icons.replay_10, color: Colors.white, size: 40), onPressed: () => _controller.seekTo(_controller.value.position - const Duration(seconds: 10))),
                                IconButton(
                                  icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 60),
                                  onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
                                ),
                                IconButton(icon: const Icon(Icons.forward_10, color: Colors.white, size: 40), onPressed: () => _controller.seekTo(_controller.value.position + const Duration(seconds: 10))),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                children:[
                                  Text(_formatDuration(_controller.value.position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  Expanded(
                                    child: VideoProgressIndicator(
                                      _controller, allowScrubbing: true,
                                      colors: const VideoProgressColors(playedColor: orangeAccent, bufferedColor: Colors.white24, backgroundColor: Colors.white12),
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                    ),
                                  ),
                                  Text(_formatDuration(_controller.value.duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GestureDetector(onTap: _toggleControls, child: Container(color: Colors.transparent)),
                ],
              ),
            ),

            // 2. ANIME INFO SECTION
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Text("E${_currentEpisode + 1} | ${widget.anime.title}", style: const TextStyle(color: orangeAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children:[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                          child: const Text("U/A 16+", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(child: Text("• Dub | Thriller, Mystery, Drama", style: TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:[
                        const Text("Episodes", style: TextStyle(color: orangeAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                          child: const Row(children:[Text("Season 1", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(width: 5), Icon(Icons.keyboard_arrow_down, color: orangeAccent, size: 18)]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        bool isActive = index == _currentEpisode;
                        return GestureDetector(
                          onTap: () => setState(() => _currentEpisode = index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: isActive ? orangeAccent : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children:[
                                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(widget.anime.image, width: 120, height: 70, fit: BoxFit.cover)),
                                const SizedBox(width: 16),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text("Episode ${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text("24 min", style: TextStyle(color: isActive ? Colors.white70 : Colors.white54, fontSize: 13))])),
                                Icon(isActive ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white, size: 36),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}