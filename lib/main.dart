import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFF121212), // Dark Theme Navigation Bar
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const AnimeMX());
}

// Data Model
class Anime {
  final String title, image, rating, dubStatus, season, status, views, videoUrl, description;
  final Color dubColor;

  Anime({
    required this.title,
    required this.image,
    this.rating = "PG-13",
    this.dubStatus = "DUB",
    this.season = "Season 1",
    this.status = "Ongoing",
    this.views = "1.1M",
    this.dubColor = const Color(0xFF6A5AE0),
    required this.description,
    // TERA GOOGLE DRIVE LINK (Converted for Direct Stream)
    // Note: Agar Google Drive block kare, to iski jagah "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4" use karna
    this.videoUrl = "https://docs.google.com/uc?export=download&id=1DZBbeWTl_21PrnQLfozJ_p4Go69a1ue_",
  });
}

// Dummy Data
final List<Anime> animeData =[
  Anime(title: "Jujutsu Kaisen", image: "https://i.ibb.co/KpsCLmBg/imager.jpg", views: "5.2K", dubColor: const Color(0xFFFF4D4D), description: "A boy swallows a cursed talisman - the finger of a demon - and becomes cursed himself. He enters a shaman's school to be able to locate the demon's other body parts and thus exorcise himself."),
  Anime(title: "Eminence in Shadow", image: "https://i.ibb.co/L0x9WvY/the-eminence-in-shadow.jpg", views: "202", dubColor: const Color(0xFF7A5CFF), description: "Cid Kagenou reincarnates in a magical world where he forms a secret organization to fight a cult that he completely made up, but it turns out to be real."),
  Anime(title: "Classroom of Elite", image: "https://i.ibb.co/vxJtwkcX/k.jpg", season: "Season 3", status: "Completed", views: "3.8K", dubColor: const Color(0xFF4DA6FF), description: "Kiyotaka Ayanokouji enters the prestigious Tokyo Metropolitan Advanced Nurturing High School, which is dedicated to fostering the best students."),
  Anime(title: "Tokyo Revengers", image: "https://i.ibb.co/YFg2hKvf/j.jpg", views: "4.1K", dubColor: const Color(0xFFFF9F43), description: "Takemichi Hanagaki travels back in time to his middle school days to save his ex-girlfriend from being murdered by a ruthless gang."),
  Anime(title: "Wang Ling", image: "https://i.ibb.co/yFRNxJbG/o.jpg", views: "3.1K", dubStatus: "MIX", dubColor: const Color(0xFF00C853), description: "As a cultivation genius who has achieved a new realm every two years since he was a year old, Wang Ling is a near-invincible existence with prowess far beyond his control."),
];

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F), // Premium Dark Background
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
      extendBody: true,
      body: _pages[_index],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // Dark Nav Bar
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
// HOME SCREEN (DARK THEME)
// ==========================================
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[
                    const Text("AnimeMX", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF6A5AE0), letterSpacing: -0.5)),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Colors.white)),
                  ],
                ),
              ),

              CarouselSlider.builder(
                itemCount: 3,
                options: CarouselOptions(height: 180, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.9),
                itemBuilder: (ctx, i, real) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20), // Modern Rounded
                    boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network("https://i.ibb.co/rW2Zk9B/images.jpg", fit: BoxFit.cover, width: double.infinity)),
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
          height: 250, 
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
// MODERN ANIME CARD DESIGN
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
        // 1. CARD CLICK KARNE PAR DETAILS PAGE OPEN HOGA
        Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsPage(anime: widget.anime)));
      },
      onTapCancel: () => setState(() => _isTapped = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isTapped ? 0.96 : 1.0),
        width: 155, 
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), 
          borderRadius: BorderRadius.circular(20), // Modern Rounded Corners
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1), 
          boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            children:[
              Image.network(widget.anime.image, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:[Colors.black.withOpacity(0.95), Colors.black.withOpacity(0.2), Colors.transparent],
                      stops: const[0.0, 0.5, 1.0],
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Text(widget.anime.rating, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: widget.anime.dubColor, borderRadius: BorderRadius.circular(12)),
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
// 2. ANIME DETAILS PAGE (No Video Player Here)
// ==========================================
class DetailsPage extends StatelessWidget {
  final Anime anime;
  const DetailsPage({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Dark Theme
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children:[
                Image.network(anime.image, width: double.infinity, height: 300, fit: BoxFit.cover, alignment: Alignment.topCenter),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [const Color(0xFF0F0F0F), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center),
                    ),
                  ),
                ),
                SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
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
                  Text(anime.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children:[
                      _buildTag(Icons.closed_caption, anime.dubStatus, const Color(0xFF6A5AE0)),
                      _buildTag(Icons.verified_user_rounded, anime.rating, Colors.grey[800]!),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(anime.description, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), height: 1.5)),
                  const SizedBox(height: 30),
                  const Text("Episodes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 14),
                  
                  // EPISODE LIST
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          // 3. EPISODE CLICK KARNE PAR VIDEO PLAYER PAGE OPEN HOGA
                          Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerPage(anime: anime, episodeNum: index + 1)));
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children:[
                              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(anime.image, width: 120, height: 70, fit: BoxFit.cover)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:[
                                    Text("Episode ${index + 1}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Text("24 min", style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                                  ],
                                ),
                              ),
                              const Icon(Icons.play_circle_fill, color: Color(0xFF6A5AE0), size: 40),
                            ],
                          ),
                        ),
                      );
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

  Widget _buildTag(IconData icon, String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:[
          Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ==========================================
// 3. VIDEO PLAYER PAGE (Actual Video Player)
// ==========================================
class VideoPlayerPage extends StatefulWidget {
  final Anime anime;
  final int episodeNum;
  const VideoPlayerPage({super.key, required this.anime, required this.episodeNum});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.anime.videoUrl));
    
    _controller.initialize().then((_) {
      setState(() {});
      _controller.play(); 
    }).catchError((error) {
      // Agar Google Drive link fail ho gaya, to error handle karega
      print("Video Load Error: $error");
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children:[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children:[
                  _controller.value.isInitialized
                      ? VideoPlayer(_controller)
                      : const Center(child: CircularProgressIndicator(color: Color(0xFF6A5AE0))),
                  
                  GestureDetector(
                    onTap: () => setState(() => _showControls = !_showControls),
                    child: Container(color: Colors.transparent),
                  ),

                  if (_showControls)
                    Container(
                      color: Colors.black54,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:[
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
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
                          VideoProgressIndicator(_controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Color(0xFF6A5AE0)), padding: const EdgeInsets.all(16)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Episode ${widget.episodeNum} | ${widget.anime.title}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// BROWSE SCREEN (Unchanged Dark Theme)
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Container(
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
                child: TextField(style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Search anime...", hintStyle: TextStyle(color: Colors.grey[500]), prefixIcon: Icon(Icons.search, color: Colors.grey[500]), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16))),
              ),
              const SizedBox(height: 24),
              const Text("Browse by Genre", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10, runSpacing: 10,
                children:["Action", "Comedy", "Drama", "Romance"].map((g) => Chip(label: Text(g, style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1E1E1E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}