import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart'; // UPI aur Support Links ke liye

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const AnimeMX());
}

// Global Order List to track Activity
List<Map<String, dynamic>> globalOrders =[];

// Data Model
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
    const Center(child: Text("Dubs", style: TextStyle(color: Colors.white))), 
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

// HOME SCREEN (UNCHANGED)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children:[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:[
                        const Text("AnimeMX", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF6A5AE0), letterSpacing: -0.5)),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children:[
                          Icon(Icons.search, color: Colors.grey[400]),
                          const SizedBox(width: 10),
                          Text("Search anime, movies, series...", style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500)),
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
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
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
              return AnimePosterCard(anime: list[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ANIME POSTER CARD (UNCHANGED)
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
          color: const Color(0xFF1A1A1A), 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1), 
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children:[
              Image.network(widget.anime.image, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors:[Colors.black.withOpacity(0.95), Colors.black.withOpacity(0.3), Colors.transparent], stops: const[0.0, 0.45, 1.0], begin: Alignment.bottomCenter, end: Alignment.topCenter)))),
              Positioned(top: 10, left: 10, right: 10, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Text(widget.anime.rating, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold))), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5)), child: Text(widget.anime.dubStatus, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))])),
              Positioned(bottom: 12, left: 12, right: 12, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children:[Text(widget.anime.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 6), Text("${widget.anime.season} • ${widget.anime.status}", style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 6), Row(children:[Icon(Icons.remove_red_eye_outlined, color: Colors.white.withOpacity(0.75), size: 14), const SizedBox(width: 4), Text("${widget.anime.views} Views", style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11))])])),
            ],
          ),
        ),
      ),
    );
  }
}

// BROWSE SCREEN (UNCHANGED)
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Container(decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)), child: TextField(style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Search anime, movies, episodes...", hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15), prefixIcon: Icon(Icons.search, color: Colors.grey[500]), suffixIcon: Icon(Icons.cancel, color: Colors.grey[600]), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16)))),
              const SizedBox(height: 24),
              const Text("Recent Searches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              _buildRecentItem("Naruto"), _buildRecentItem("One Piece"), _buildRecentItem("Demon Slayer"),
              const SizedBox(height: 24),
              const Text("Trending Searches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Row(children:[Expanded(child: Column(children:[_buildTrendingItem("1", "Solo Leveling"), _buildTrendingItem("3", "Chainsaw Man")])), Expanded(child: Column(children:[_buildTrendingItem("2", "Jujutsu Kaisen"), _buildTrendingItem("4", "Tokyo Revengers")]))]),
              const SizedBox(height: 24),
              const Text("Browse by Genre", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.2,
                children:[
                  _buildGenreCard("Action", "Action", Icons.sports_martial_arts, const Color(0xFF3A1C1C), Colors.redAccent),
                  _buildGenreCard("Comedy", "Hilarity", Icons.sentiment_very_satisfied, const Color(0xFF2D1B4E), const Color(0xFF9D84FF)),
                  _buildGenreCard("Drama", "Series", Icons.masks, const Color(0xFF162B44), Colors.blueAccent),
                  _buildGenreCard("Romance", "Love", Icons.favorite, const Color(0xFF421A28), Colors.pinkAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildRecentItem(String title) { return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)), Row(children:[Icon(Icons.close, size: 18, color: Colors.grey[500]), const SizedBox(width: 12), Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[600])])])); }
  Widget _buildTrendingItem(String num, String title) { return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children:[Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)), child: Center(child: Text(num, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)))), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white), overflow: TextOverflow.ellipsis))])); }
  Widget _buildGenreCard(String title, String subtitle, IconData icon, Color bgColor, Color iconColor) { return Container(decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children:[Icon(icon, size: 30, color: iconColor), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children:[Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)))])])); }
}

// VIDEO PLAYER PAGE (UNCHANGED)
class VideoDetailsPage extends StatefulWidget {
  final Anime anime;
  const VideoDetailsPage({super.key, required this.anime});
  @override
  State<VideoDetailsPage> createState() => _VideoDetailsPageState();
}

class _VideoDetailsPageState extends State<VideoDetailsPage> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  int _currentEpisode = 0;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.anime.videoUrl))..initialize().then((_) { setState(() {}); _controller.play(); });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _toggleControls() { setState(() { _showControls = !_showControls; }); }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A5AE0);
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children:[
                  _controller.value.isInitialized ? VideoPlayer(_controller) : const Center(child: CircularProgressIndicator(color: primaryPurple)),
                  if (_showControls) GestureDetector(
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
                              Row(children:[IconButton(icon: const Icon(Icons.cast, color: Colors.white), onPressed: () {}), IconButton(icon: const Icon(Icons.fullscreen, color: Colors.white), onPressed: () {})])
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children:[
                              IconButton(icon: const Icon(Icons.replay_10, color: Colors.white, size: 40), onPressed: () => _controller.seekTo(_controller.value.position - const Duration(seconds: 10))),
                              IconButton(icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 60), onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play())),
                              IconButton(icon: const Icon(Icons.forward_10, color: Colors.white, size: 40), onPressed: () => _controller.seekTo(_controller.value.position + const Duration(seconds: 10))),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children:[
                                Text(_formatDuration(_controller.value.position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                Expanded(child: VideoProgressIndicator(_controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: primaryPurple, bufferedColor: Colors.white24, backgroundColor: Colors.white12), padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0))),
                                Text(_formatDuration(_controller.value.duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ) else GestureDetector(onTap: _toggleControls, child: Container(color: Colors.transparent)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Text("E${_currentEpisode + 1} | ${widget.anime.title}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(children:[Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)), child: const Text("U/A 16+", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))), const SizedBox(width: 10), const Expanded(child: Text("• Dub | Action, Drama", style: TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis))]),
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text("Episodes", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)), child: const Row(children:[Text("Season 1", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(width: 5), Icon(Icons.keyboard_arrow_down, color: primaryPurple, size: 18)]))]),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 4,
                      itemBuilder: (context, index) {
                        bool isActive = index == _currentEpisode;
                        return GestureDetector(
                          onTap: () => setState(() => _currentEpisode = index),
                          child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isActive ? primaryPurple : const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)), child: Row(children:[ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(widget.anime.image, width: 120, height: 70, fit: BoxFit.cover)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text("Episode ${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text("24 min", style: TextStyle(color: Colors.white70, fontSize: 13))])), Icon(isActive ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white, size: 36)])),
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

// ==========================================
// 🔥 PROFILE SCREEN & NEW SUB-PAGES 🔥
// ==========================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 100),
          child: Column(
            children:[
              // Go Premium Card
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(colors:[Color(0xFF8B5CF6), Color(0xFF6A5AE0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children:[Icon(Icons.workspace_premium, color: Colors.white, size: 28), SizedBox(width: 8), Text("Go Premium", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 8),
                      const Text("Unlock all episodes & Remove ads", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 16),
                      Row(children:[_buildPricePill("₹90"), const SizedBox(width: 10), _buildPricePill("₹160"), const SizedBox(width: 10), _buildPricePill("₹299")]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Menu Items
              _buildMenuItem(context, Icons.receipt_long, "Activity & Orders", const ActivityPage()),
              _buildMenuItem(context, Icons.payment, "Payment Proof", const PaymentProofPage()),
              _buildMenuItem(context, Icons.headset_mic, "Support", const SupportPage()),
              _buildMenuItem(context, Icons.info_outline, "About Us", const AboutUsPage()),
              _buildMenuItem(context, Icons.privacy_tip_outlined, "Privacy Policy", const PrivacyPolicyPage()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricePill(String price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children:[
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white70, size: 20)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }
}

// 1. PREMIUM PAGE (With UPI Logic)
class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  void _payAndProceed(BuildContext context, int amount, String planName) async {
    final Uri upiUri = Uri.parse("upi://pay?pa=animemx@upi&pn=AnimeMX&am=$amount&cu=INR");
    try {
      await launchUrl(upiUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Ignored if no UPI app installed
    }
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentProofPage(initialAmount: amount.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(title: const Text("Go Premium"), backgroundColor: const Color(0xFF0F0F0F), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children:[
            const Text("Choose Your Plan", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text("Unlock exclusive content & an ad-free experience.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _buildPlanCard(context, "Silver Plan", "HD (720p) • Medium Ads • Limited Access", 90, false),
            _buildPlanCard(context, "Gold Plan", "Full HD (1080p) • Low Ads • Full Access", 160, true),
            _buildPlanCard(context, "Diamond Plan", "Ultra HD (4K) • Ad-Free • 3 Devices", 299, false),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, String title, String subtitle, int price, bool isRecommended) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: isRecommended ? Border.all(color: Colors.amber, width: 2) : null,
      ),
      child: Stack(
        children:[
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.only(topLeft: Radius.circular(14), bottomRight: Radius.circular(10))),
              child: const Text("RECOMMENDED", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  children:[
                    Text("₹$price/mo", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: isRecommended ? Colors.amber : const Color(0xFF6A5AE0)),
                      onPressed: () => _payAndProceed(context, price, title),
                      child: Text("Select", style: TextStyle(color: isRecommended ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 2. PAYMENT PROOF PAGE (With Image Upload Simulation & Dropdown)
class PaymentProofPage extends StatefulWidget {
  final String? initialAmount;
  const PaymentProofPage({super.key, this.initialAmount});

  @override
  State<PaymentProofPage> createState() => _PaymentProofPageState();
}

class _PaymentProofPageState extends State<PaymentProofPage> {
  String _selectedAmount = "90";
  bool _isImageUploaded = false;
  final TextEditingController _txnController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null && ["90", "160", "299"].contains(widget.initialAmount)) {
      _selectedAmount = widget.initialAmount!;
    }
  }

  void _submitProof() {
    if (!_isImageUploaded || _txnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload screenshot and enter TXN ID!")));
      return;
    }
    String planName = _selectedAmount == "90" ? "Silver Plan" : _selectedAmount == "160" ? "Gold Plan" : "Diamond Plan";
    
    // Save order globally
    globalOrders.insert(0, {'plan': planName, 'amount': _selectedAmount, 'status': 'Pending', 'date': 'Just Now'});
    
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ActivityPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(title: const Text("Verify Payment"), backgroundColor: const Color(0xFF0F0F0F), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(12)),
              child: const Row(children:[Icon(Icons.info, color: Color(0xFF1A73E8)), SizedBox(width: 10), Expanded(child: Text("Verify your payment to activate plan instantly.", style: TextStyle(color: Color(0xFF1A73E8))))]),
            ),
            const SizedBox(height: 24),
            const Text("Select Amount Paid", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAmount,
                  dropdownColor: const Color(0xFF1A1A1A),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: const[
                    DropdownMenuItem(value: "90", child: Text("₹90 (Silver)")),
                    DropdownMenuItem(value: "160", child: Text("₹160 (Gold)")),
                    DropdownMenuItem(value: "299", child: Text("₹299 (Diamond)")),
                  ],
                  onChanged: (val) => setState(() => _selectedAmount = val!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Upload Screenshot", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening File Manager...")));
                Future.delayed(const Duration(seconds: 1), () => setState(() => _isImageUploaded = true));
              },
              child: Container(
                height: 180, width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF6A5AE0), width: 1.5, style: BorderStyle.solid)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    Icon(_isImageUploaded ? Icons.check_circle : Icons.cloud_upload, color: _isImageUploaded ? Colors.green : const Color(0xFF6A5AE0), size: 60),
                    const SizedBox(height: 12),
                    Text(_isImageUploaded ? "Screenshot Selected.jpg" : "Tap to Upload Screenshot", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (!_isImageUploaded) const Text("Supports JPG, PNG", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Transaction ID / UTR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _txnController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "e.g. 3089XXXXXXXX", hintStyle: const TextStyle(color: Colors.grey),
                filled: true, fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A5AE0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _submitProof,
                child: const Text("Submit & Verify", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// 3. ACTIVITY PAGE
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(title: const Text("Activity & Orders"), backgroundColor: const Color(0xFF0F0F0F), elevation: 0),
      body: globalOrders.isEmpty
          ? const Center(child: Text("No recent orders", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: globalOrders.length,
              itemBuilder: (ctx, i) {
                final order = globalOrders[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.5))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Text("${order['plan']} Purchase", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("₹${order['amount']} • ${order['date']}", style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(order['status'], style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// 4. SUPPORT PAGE (EXACT SCREENSHOT LAYOUT)
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  void _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(title: const Text("Help Center"), backgroundColor: const Color(0xFF0F0F0F), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            // Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(color: const Color(0xFF7A5CFF), borderRadius: BorderRadius.circular(20)),
              child: const Column(
                children:[
                  Icon(Icons.headset_mic, color: Colors.white, size: 50),
                  SizedBox(height: 16),
                  Text("How can we help?", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("We're here to help you with any issues\nor questions.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("CONTACT OPTIONS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            
            _buildContactTile(Icons.telegram, "Telegram", "Instant Chat Support", Colors.blue, () => _launchUrl("https://t.me/anime_mx_support")),
            _buildContactTile(Icons.chat, "WhatsApp", "Chat Support", Colors.green, () => _launchUrl("https://wa.me/910000000000")),
            _buildContactTile(Icons.email, "Email", "24-hour Response Time", Colors.orange, () => _launchUrl("mailto:support@animemx.com")),
            
            const SizedBox(height: 30),
            const Text("FREQUENTLY ASKED QUESTIONS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text("How to download an episode?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                collapsedBackgroundColor: const Color(0xFF1A1A1A),
                backgroundColor: const Color(0xFF1A1A1A),
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                children: const[
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Go to the episode details, click the 'Download' button in the action bar. This feature is available for Premium users only.", style: TextStyle(color: Colors.grey, height: 1.5)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(IconData icon, String title, String subtitle, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children:[
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 24)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13))])),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

// 5. OTHER PAGES
class AboutUsPage extends StatelessWidget { const AboutUsPage({super.key}); @override Widget build(BuildContext context) { return Scaffold(backgroundColor: const Color(0xFF0F0F0F), appBar: AppBar(title: const Text("About Us"), backgroundColor: const Color(0xFF0F0F0F)), body: const Center(child: Text("About AnimeMX", style: TextStyle(color: Colors.white, fontSize: 20)))); } }
class PrivacyPolicyPage extends StatelessWidget { const PrivacyPolicyPage({super.key}); @override Widget build(BuildContext context) { return Scaffold(backgroundColor: const Color(0xFF0F0F0F), appBar: AppBar(title: const Text("Privacy Policy"), backgroundColor: const Color(0xFF0F0F0F)), body: const Center(child: Text("Privacy Policy", style: TextStyle(color: Colors.white, fontSize: 20)))); } }