import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // 🔥 YAHAN IMPORT MISSING THA, AB ADD KAR DIYA HAI

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, 
  ));
  runApp(const AnimeMX());
}

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
    this.videoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
  });
}

final List<Anime> animeData =[
  Anime(title: "Jujutsu Kaisen", image: "https://i.ibb.co/KpsCLmBg/imager.jpg", views: "5.2K", dubColor: const Color(0xFFFF4D4D)),
  Anime(title: "The Eminence in Shadow", image: "https://i.ibb.co/L0x9WvY/the-eminence-in-shadow.jpg", views: "202", dubColor: const Color(0xFF7A5CFF)),
  Anime(title: "Classroom of the Elite", image: "https://i.ibb.co/vxJtwkcX/k.jpg", season: "Season 3", status: "Completed", views: "3.8K", dubColor: const Color(0xFF4DA6FF)),
  Anime(title: "Tokyo Revengers", image: "https://i.ibb.co/YFg2hKvf/j.jpg", views: "4.1K", dubColor: const Color(0xFFFF9F43)),
  Anime(title: "Wang Ling", image: "https://i.ibb.co/yFRNxJbG/o.jpg", views: "3.1K", dubStatus: "MIX", dubColor: const Color(0xFF00C853)),
];

// Activity Page Tracking
class OrderItem { final String planName, amount, status, date; OrderItem({required this.planName, required this.amount, required this.status, required this.date}); }
List<OrderItem> userOrders =[];

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
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
  final List<Widget> _pages =[
    const HomeScreen(), 
    const BrowseScreen(), 
    const DubsScreen(), 
    const ProfileScreen()
  ];

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
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(35),
            boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 5))],
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

  Widget _buildDivider() => Container(width: 1, height: 30, color: Colors.white24);

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
// 🔥 HOME SCREEN (UPDATED FIXED HEADER & ORDER) 🔥
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children:[
            // 1. FIXED HEADER (DOES NOT SCROLL)
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // SCROLLABLE CONTENT BELOW HEADER
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    const SizedBox(height: 16),

                    // 2. AUTO SLIDE BAR
                    CarouselSlider.builder(
                      itemCount: animeData.length,
                      options: CarouselOptions(height: 180, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.9),
                      itemBuilder: (ctx, i, real) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16), 
                          child: Stack(
                            fit: StackFit.expand,
                            children:[
                              Image.network(animeData[i].image, fit: BoxFit.cover, width: double.infinity),
                              Positioned(
                                bottom: 10, left: 15, 
                                child: Text(i == 0 ? "Latest" : i == 1 ? "Coming Soon" : i == 2 ? "Popular" : "Recommended", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, backgroundColor: Colors.black54, fontSize: 16))
                              )
                            ],
                          )
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. CONTINUE WATCHING (YouTube Thumbnail Shape - Small)
                    _buildThumbnailSection("⏳ Continue Watching", animeData),

                    // 4. TRENDING NOW (Normal Poster)
                    _buildCategorySection("🔥 Trending Now", animeData),

                    // 5. POPULAR (With White Outline)
                    _buildCategorySection("🏆 Popular", animeData.reversed.toList(), hasWhiteOutline: true),

                    // 6. LATEST EPISODES (YouTube Thumbnail Shape - Small)
                    _buildThumbnailSection("🆕 Latest Episodes", animeData),

                    // 7. FANTASY (Normal Poster)
                    _buildCategorySection("✨ Fantasy", animeData),

                    // 8. THRILLER (Normal Poster)
                    _buildCategorySection("🔪 Thriller", animeData.reversed.toList()),

                    // 9. ROMANCE (Normal Poster)
                    _buildCategorySection("💖 Romance", animeData),

                    // 10. MYSTERY (Normal Poster)
                    _buildCategorySection("🕵️ Mystery", animeData.reversed.toList()),

                    // 11. ACTION (Normal Poster)
                    _buildCategorySection("⚔️ Action", animeData),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, List<Anime> list, {bool hasWhiteOutline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
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
              return AnimePosterCard(anime: list[index], hasWhiteOutline: hasWhiteOutline);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Helper for YouTube Thumbnail shaped cards
  Widget _buildThumbnailSection(String title, List<Anime> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
        SizedBox(
          height: 150, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return ThumbnailAnimeCard(anime: list[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// 16:9 YOUTUBE THUMBNAIL SHAPED CARD 
class ThumbnailAnimeCard extends StatefulWidget {
  final Anime anime;
  const ThumbnailAnimeCard({super.key, required this.anime});
  @override
  State<ThumbnailAnimeCard> createState() => _ThumbnailAnimeCardState();
}
class _ThumbnailAnimeCardState extends State<ThumbnailAnimeCard> {
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
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isTapped ? 0.96 : 1.0),
        width: 170, 
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children:[
                    Image.network(widget.anime.image, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                    Positioned(
                      bottom: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                        child: const Text("24:00", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 36)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.anime.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text("Episode 12", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ANIME POSTER CARD 
class AnimePosterCard extends StatefulWidget {
  final Anime anime;
  final bool hasWhiteOutline;
  const AnimePosterCard({super.key, required this.anime, this.hasWhiteOutline = false});
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
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isTapped ? 0.96 : 1.0),
        width: 160, 
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.hasWhiteOutline ? Colors.white : Colors.white.withOpacity(0.1), width: widget.hasWhiteOutline ? 2 : 1), 
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children:[
              Image.network(widget.anime.image, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:[Colors.black.withOpacity(0.95), Colors.black.withOpacity(0.3), Colors.transparent],
                      stops: const[0.0, 0.45, 1.0],
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10, left: 10, right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Text(widget.anime.rating, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5)), child: Text(widget.anime.dubStatus, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Positioned(
                bottom: 12, left: 12, right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                  children:[
                    Text(widget.anime.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text("${widget.anime.season} • ${widget.anime.status}", style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children:[Icon(Icons.remove_red_eye_outlined, color: Colors.white.withOpacity(0.75), size: 14), const SizedBox(width: 4), Text("${widget.anime.views} Views", style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11))]),
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
// DETAILS PAGE 
// ==========================================
class DetailsPage extends StatefulWidget {
  final Anime anime;
  const DetailsPage({super.key, required this.anime});
  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  bool _isExpanded = false;
  int _selectedSeason = 1;

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A5AE0);
    const Color darkBg = Color(0xFF0F0F0F);

    return Scaffold(
      backgroundColor: darkBg,
      body: CustomScrollView(
        slivers:[
          SliverAppBar(
            expandedHeight: 250, pinned: true, backgroundColor: Colors.black,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children:[
                  Image.network(widget.anime.image, fit: BoxFit.cover, alignment: Alignment.topCenter),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(colors:[const Color(0xFF0F0F0F), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter))),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Text(widget.anime.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 10),
                  Row(
                    children:[
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)), child: Text(widget.anime.rating, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 10),
                      const Expanded(child: Text("• Dub | Action, Thriller, Drama", style: TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryPurple, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerPage(anime: widget.anime, episodeIndex: 0))), 
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      label: const Text("Watch Episode 1", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text("Kiyotaka Ayanokouji enters the prestigious Tokyo Metropolitan Advanced Nurturing High School, which is dedicated to fostering the best and brightest students...", maxLines: _isExpanded ? null : 2, overflow: _isExpanded ? null : TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 6),
                  GestureDetector(onTap: () => setState(() => _isExpanded = !_isExpanded), child: Text(_isExpanded ? "Read Less" : "Read More", style: const TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize: 13))),
                  const SizedBox(height: 30),
                  const Text("Seasons", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children:[
                    _buildSeasonTab(1, primaryPurple), const SizedBox(width: 10),
                    _buildSeasonTab(2, primaryPurple), const SizedBox(width: 10),
                    _buildSeasonTab(3, primaryPurple),
                  ]),
                  const SizedBox(height: 24),
                  const Text("Episodes", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 4,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerPage(anime: widget.anime, episodeIndex: index))),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children:[
                              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(widget.anime.image, width: 120, height: 70, fit: BoxFit.cover)),
                              const SizedBox(width: 16),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text("Episode ${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text("24 min", style: TextStyle(color: Colors.white70, fontSize: 13))])),
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)), child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24)),
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
    );
  }

  Widget _buildSeasonTab(int seasonNumber, Color primaryColor) {
    bool isActive = _selectedSeason == seasonNumber;
    return GestureDetector(
      onTap: () => setState(() => _selectedSeason = seasonNumber),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isActive ? primaryColor : const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
        child: Text("Season $seasonNumber", style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

// ==========================================
// VIDEO PLAYER PAGE
// ==========================================
class VideoPlayerPage extends StatefulWidget {
  final Anime anime;
  final int episodeIndex;
  const VideoPlayerPage({super.key, required this.anime, required this.episodeIndex});
  @override State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  @override void initState() { super.initState(); _controller = VideoPlayerController.networkUrl(Uri.parse(widget.anime.videoUrl))..initialize().then((_) { setState(() {}); _controller.play(); }); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  void _toggleControls() { setState(() { _showControls = !_showControls; }); }
  String _formatDuration(Duration duration) { String twoDigits(int n) => n.toString().padLeft(2, '0'); return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}"; }

  @override Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A5AE0);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children:[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children:[
                  _controller.value.isInitialized ? VideoPlayer(_controller) : const Center(child: CircularProgressIndicator(color: primaryPurple)),
                  if (_showControls)
                    GestureDetector(
                      onTap: _toggleControls,
                      child: Container(
                        color: Colors.black54,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:[
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)), Row(children:[IconButton(icon: const Icon(Icons.cast, color: Colors.white), onPressed: () {}), IconButton(icon: const Icon(Icons.fullscreen, color: Colors.white), onPressed: () {})])]),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children:[IconButton(icon: const Icon(Icons.replay_10, color: Colors.white, size: 40), onPressed: () => _controller.seekTo(_controller.value.position - const Duration(seconds: 10))), IconButton(icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 60), onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play())), IconButton(icon: const Icon(Icons.forward_10, color: Colors.white, size: 40), onPressed: () => _controller.seekTo(_controller.value.position + const Duration(seconds: 10)))]),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Row(children:[Text(_formatDuration(_controller.value.position), style: const TextStyle(color: Colors.white, fontSize: 12)), Expanded(child: VideoProgressIndicator(_controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: primaryPurple, bufferedColor: Colors.white24, backgroundColor: Colors.white12), padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0))), Text(_formatDuration(_controller.value.duration), style: const TextStyle(color: Colors.white, fontSize: 12))])),
                          ],
                        ),
                      ),
                    )
                  else GestureDetector(onTap: _toggleControls, child: Container(color: Colors.transparent)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text("Episode ${widget.episodeIndex + 1}", style: const TextStyle(color: primaryPurple, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(widget.anime.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))]),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PROFILE, PREMIUM, ACTIVITY, SUPPORT PAGES
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 100),
          child: Column(
            children:[
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Column(children:[Container(width: 75, height: 75, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow:[BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 15)], image: const DecorationImage(image: NetworkImage("https://i.ibb.co/vxJtwkcX/k.jpg"), fit: BoxFit.cover))), const SizedBox(height: 8), const Row(children:[Icon(Icons.edit, color: Colors.purpleAccent, size: 14), SizedBox(width: 4), Text("Edit Profile", style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 12))])]), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text("Flexxy xD", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, boxShadow:[BoxShadow(color: Colors.greenAccent, blurRadius: 8)]))]), const SizedBox(height: 4), const Text("flexxy0xd@gmail.com", style: TextStyle(color: Colors.white70, fontSize: 14)), const SizedBox(height: 8), Row(children:[const Text("UID: VcXZJDac...", style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(width: 8), const Icon(Icons.copy_outlined, color: Colors.grey, size: 14)]), const SizedBox(height: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF8B4513), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orangeAccent.withOpacity(0.6))), child: const Text("BRONZE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)))])),]),
              const SizedBox(height: 24),
              GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())), child: Container(margin: const EdgeInsets.symmetric(horizontal: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors:[Color(0xFF8B5CF6), Color(0xFF6A5AE0)], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[const Row(children:[Icon(Icons.workspace_premium, color: Colors.white, size: 26), SizedBox(width: 8), Text("Go Premium", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]), const SizedBox(height: 6), const Text("Unlock all episodes & Remove ads", style: TextStyle(color: Colors.white70, fontSize: 13)), const SizedBox(height: 12), Row(children:[_buildPricePill("₹90"), const SizedBox(width: 8), _buildPricePill("₹160"), const SizedBox(width: 8), _buildPricePill("₹299")])]))),
              const SizedBox(height: 24),
              _buildMenuItem(context, Icons.receipt_long, "Activity & Orders", const ActivityPage()),
              _buildMenuItem(context, Icons.payment, "Payment Proof", const PaymentProofPage()),
              _buildMenuItem(context, Icons.headset_mic, "Support", const SupportPage()),
              _buildMenuItem(context, Icons.info_outline, "About Us", const Scaffold(backgroundColor: Color(0xFF0F0F0F), body: Center(child: Text("About Us", style: TextStyle(color: Colors.white))))),
              _buildMenuItem(context, Icons.privacy_tip_outlined, "Privacy Policy", const Scaffold(backgroundColor: Color(0xFF0F0F0F), body: Center(child: Text("Privacy Policy", style: TextStyle(color: Colors.white))))),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildPricePill(String price) { return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))); }
  Widget _buildMenuItem(BuildContext context, IconData icon, String title, Widget page) { return Padding(padding: const EdgeInsets.only(bottom: 12), child: Material(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16), child: InkWell(borderRadius: BorderRadius.circular(16), splashColor: Colors.grey.withOpacity(0.3), highlightColor: Colors.grey.withOpacity(0.3), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Row(children:[Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white70, size: 20)), const SizedBox(width: 16), Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))), const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16)]))))); }
}

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});
  void _launchUPI(BuildContext context, String amount, String plan) async { final Uri uri = Uri.parse("upi://pay?pa=wicvlox.i@oksbi&pn=AnimeMX&am=$amount&cu=INR&tn=Buy%20$plan"); if (await canLaunchUrl(uri)) { await launchUrl(uri, mode: LaunchMode.externalApplication); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No UPI App found on this device!"))); } }
  @override Widget build(BuildContext context) { return Scaffold(backgroundColor: const Color(0xFF0F0F0F), appBar: AppBar(title: const Text("Go Premium", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)), body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children:[const Text("Choose Your Plan", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 5), const Text("Unlock exclusive content & an ad-free experience.", style: TextStyle(color: Colors.white70, fontSize: 14)), const SizedBox(height: 30), _buildPlanCard(context, "🥈 Silver Plan", "HD (720p) • Medium Ads", "₹90", false), const SizedBox(height: 15), _buildPlanCard(context, "🥇 Gold Plan", "Full HD (1080p) • Low Ads", "₹160", true), const SizedBox(height: 15), _buildPlanCard(context, "💎 Diamond Plan", "Ultra HD (4K) • Ad-Free", "₹299", false)]))); }
  Widget _buildPlanCard(BuildContext context, String title, String subtitle, String price, bool isGold) { String cleanPrice = price.replaceAll("₹", ""); return Stack(children:[Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), border: Border.all(color: isGold ? Colors.amber : Colors.white24, width: isGold ? 2 : 1), borderRadius: BorderRadius.circular(16)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children:[Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children:[Text(price, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const Text("/mo", style: TextStyle(color: Colors.white54, fontSize: 12))]), const SizedBox(height: 10), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isGold ? Colors.amber : const Color(0xFF6A5AE0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () => _launchUPI(context, cleanPrice, title.split(" ")[1]), child: Text("Select", style: TextStyle(color: isGold ? Colors.black : Colors.white, fontWeight: FontWeight.bold)))])])), if (isGold) Positioned(top: 0, left: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: const BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8))), child: const Text("RECOMMENDED", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold))))]); }
}

class PaymentProofPage extends StatefulWidget { const PaymentProofPage({super.key}); @override State<PaymentProofPage> createState() => _PaymentProofPageState(); }
class _PaymentProofPageState extends State<PaymentProofPage> { File? _imageFile; String _selectedAmount = "90"; String _selectedPlan = "Silver Plan"; Future<void> _pickImage() async { final picker = ImagePicker(); final pickedFile = await picker.pickImage(source: ImageSource.gallery); if (pickedFile != null) setState(() { _imageFile = File(pickedFile.path); }); } @override Widget build(BuildContext context) { return Scaffold(backgroundColor: const Color(0xFF0F0F0F), appBar: AppBar(title: const Text("Verify Payment", style: TextStyle(color: Colors.white)), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)), body: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Row(children:[Icon(Icons.info_outline, color: Colors.blue), SizedBox(width: 10), Expanded(child: Text("Verify your payment to activate plan instantly.", style: TextStyle(color: Colors.blue)))])), const SizedBox(height: 24), const Text("Select Amount Paid", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(height: 8), DropdownButtonFormField<String>(dropdownColor: const Color(0xFF1A1A1A), decoration: InputDecoration(filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), style: const TextStyle(color: Colors.white, fontSize: 16), value: _selectedAmount, items: const[DropdownMenuItem(value: "90", child: Text("₹90 (Silver)")), DropdownMenuItem(value: "160", child: Text("₹160 (Gold)")), DropdownMenuItem(value: "299", child: Text("₹299 (Diamond)"))], onChanged: (val) { setState(() { _selectedAmount = val!; if(val == "90") _selectedPlan = "Silver Plan"; if(val == "160") _selectedPlan = "Gold Plan"; if(val == "299") _selectedPlan = "Diamond Plan"; }); }), const SizedBox(height: 24), const Text("Upload Screenshot", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(height: 8), GestureDetector(onTap: _pickImage, child: Container(height: 200, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF6A5AE0).withOpacity(0.5), style: BorderStyle.solid, width: 2)), child: _imageFile != null ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(_imageFile!, fit: BoxFit.cover)) : Column(mainAxisAlignment: MainAxisAlignment.center, children: const[Icon(Icons.cloud_upload_outlined, color: Color(0xFF6A5AE0), size: 50), SizedBox(height: 10), Text("Tap to upload Screenshot", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("Supports JPG, PNG", style: TextStyle(color: Colors.white54, fontSize: 12))]))), const SizedBox(height: 24), const Text("Transaction ID / UTR", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(height: 8), TextFormField(style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "e.g. 3089XXXXXXX", hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF1A1A1A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))), const SizedBox(height: 30), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A5AE0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () { setState(() { userOrders.insert(0, OrderItem(planName: _selectedPlan, amount: "₹$_selectedAmount", status: "Pending", date: "Today")); }); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Proof Submitted!"))); Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context)); }, child: const Text("Submit & Verify", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))))]))); } }

class SupportPage extends StatelessWidget { const SupportPage({super.key}); @override Widget build(BuildContext context) { return Scaffold(backgroundColor: const Color(0xFF0F0F0F), appBar: AppBar(title: const Text("Help Center", style: TextStyle(color: Colors.white)), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)), body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors:[Color(0xFF8B5CF6), Color(0xFF6A5AE0)])), child: Row(children:[Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.headset_mic, color: Colors.white, size: 30)), const SizedBox(width: 15), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text("How can we help?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text("We're here to help you with any issues.", style: TextStyle(color: Colors.white70, fontSize: 12))]))])), const SizedBox(height: 30), const Text("Contact Options", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 16), _buildSupportTile(Icons.telegram, "Telegram", "Instant Chat Support", Colors.blueAccent), _buildSupportTile(Icons.chat, "WhatsApp", "Chat Support", Colors.green), _buildSupportTile(Icons.email, "Email", "24-hour Response", Colors.orangeAccent)]))); } Widget _buildSupportTile(IconData icon, String title, String sub, Color color) { return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)), child: Row(children:[Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12))])), const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16)])); } }

class ActivityPage extends StatelessWidget { const ActivityPage({super.key}); @override Widget build(BuildContext context) { return Scaffold(backgroundColor: const Color(0xFF0F0F0F), appBar: AppBar(title: const Text("Activity & Orders", style: TextStyle(color: Colors.white)), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)), body: userOrders.isEmpty ? const Center(child: Text("No recent orders.", style: TextStyle(color: Colors.white54))) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: userOrders.length, itemBuilder: (ctx, i) { final order = userOrders[i]; return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: order.status == "Pending" ? Colors.orange : Colors.green, width: 4))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(order.planName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text("${order.amount} • ${order.date}", style: const TextStyle(color: Colors.white54, fontSize: 12))]), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: order.status == "Pending" ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text(order.status, style: TextStyle(color: order.status == "Pending" ? Colors.orange : Colors.green, fontSize: 12, fontWeight: FontWeight.bold)))])); })); } }

// ==========================================
// BROWSE SCREEN & DUBS SCREEN (UNCHANGED)
// ==========================================
class BrowseScreen extends StatelessWidget { const BrowseScreen({super.key}); @override Widget build(BuildContext context) { return Scaffold(backgroundColor: const Color(0xFF0F0F0F), body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(16.0).copyWith(bottom: 100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Container(decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)), child: TextField(style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Search anime...", hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15), prefixIcon: Icon(Icons.search, color: Colors.grey[500]), suffixIcon: Icon(Icons.cancel, color: Colors.grey[600]), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16)))), const SizedBox(height: 24), const Text("Recent Searches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 12), _buildRecentItem("Naruto"), _buildRecentItem("One Piece"), const SizedBox(height: 24), const Text("Trending Searches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 12), Row(children:[Expanded(child: Column(children:[_buildTrendingItem("1", "Solo Leveling"), _buildTrendingItem("3", "Chainsaw Man")])), Expanded(child: Column(children:[_buildTrendingItem("2", "Jujutsu Kaisen"), _buildTrendingItem("4", "Tokyo Revengers")]))]), const SizedBox(height: 24), const Text("Browse by Genre", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 12), GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.2, children:[_buildGenreCard("Action", "Action", Icons.sports_martial_arts, const Color(0xFF3A1C1C), Colors.redAccent), _buildGenreCard("Comedy", "Hilarity", Icons.sentiment_very_satisfied, const Color(0xFF2D1B4E), const Color(0xFF9D84FF)), _buildGenreCard("Drama", "Series", Icons.masks, const Color(0xFF162B44), Colors.blueAccent), _buildGenreCard("Romance", "Love", Icons.favorite, const Color(0xFF421A28), Colors.pinkAccent)])])))); } Widget _buildRecentItem(String title) { return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)), Row(children:[Icon(Icons.close, size: 18, color: Colors.grey[500]), const SizedBox(width: 12), Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[600])])])); } Widget _buildTrendingItem(String num, String title) { return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children:[Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)), child: Center(child: Text(num, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)))), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white), overflow: TextOverflow.ellipsis))])); } Widget _buildGenreCard(String title, String subtitle, IconData icon, Color bgColor, Color iconColor) { return Container(decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children:[Icon(icon, size: 30, color: iconColor), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children:[Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)))])])); } }
class DubsScreen extends StatelessWidget { const DubsScreen({super.key}); @override Widget build(BuildContext context) { return DefaultTabController(length: 2, child: Scaffold(backgroundColor: const Color(0xFF0F0F0F), appBar: AppBar(backgroundColor: const Color(0xFF0F0F0F), elevation: 0, toolbarHeight: 10, bottom: const TabBar(indicatorColor: Color(0xFF6A5AE0), indicatorWeight: 3, labelColor: Color(0xFF6A5AE0), unselectedLabelColor: Colors.white70, tabs:[Tab(text: "ADR DUBBED"), Tab(text: "ORIGINAL")])), body: TabBarView(children:[GridView.builder(padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 14, mainAxisSpacing: 16), itemCount: animeData.length, itemBuilder: (context, index) => AnimePosterCard(anime: animeData[index], hasWhiteOutline: false)), GridView.builder(padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 14, mainAxisSpacing: 16), itemCount: animeData.length, itemBuilder: (context, index) => AnimePosterCard(anime: animeData[index], hasWhiteOutline: false))]))); } }