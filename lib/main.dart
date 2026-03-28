import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const AnimeMX());
}

// ==========================================
// DATA MODELS & GLOBAL STATE
// ==========================================

class Episode {
  final String title;
  final String image;
  final String duration;
  final String views;
  final String videoUrl;

  Episode({
    required this.title,
    required this.image,
    required this.duration,
    required this.views,
    required this.videoUrl,
  });
}

class Season {
  final String name;
  final List<Episode> episodes;

  Season({
    required this.name,
    required this.episodes,
  });
}

class Anime {
  final String title;
  final String image;
  final String genre;
  final String rating;
  final String dubStatus;
  final String season;       // 🔥 ERROR FIXED: Added season back
  final String status;
  final String views;
  final String videoUrl;     // 🔥 ERROR FIXED: Added videoUrl back
  final bool isNew;
  final Color dubColor;
  final List<Season> seasonsList;

  Anime({
    required this.title,
    required this.image,
    this.genre = "Action",
    this.rating = "PG-13",
    this.dubStatus = "DUB",
    this.season = "Season 1", 
    this.status = "Ongoing",
    this.views = "1.1M",
    this.videoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    this.isNew = false,
    this.dubColor = const Color(0xFFFF4D4D),
    required this.seasonsList,
  });
}

// SMART CONTINUE WATCHING STATE
class CWItem {
  final Anime anime;
  int seasonIndex;
  int episodeIndex;
  Duration position;
  Duration totalDuration;

  CWItem({
    required this.anime,
    required this.seasonIndex,
    required this.episodeIndex,
    required this.position,
    required this.totalDuration,
  });
}

final ValueNotifier<List<CWItem>> continueWatchingNotifier = ValueNotifier([]);

// DUMMY DATA GENERATOR
List<Season> generateDummySeasons() {
  return[
    Season(
      name: "Season 1",
      episodes:[
        Episode(
          title: "The Beginning of the End",
          image: "https://i.ibb.co/rW2Zk9B/images.jpg",
          duration: "24m 10s",
          views: "2.1M",
          videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        ),
        Episode(
          title: "A New Threat Appears",
          image: "https://i.ibb.co/C3rhjGv3/images-1.jpg",
          duration: "23m 45s",
          views: "1.8M",
          videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ),
      ],
    ),
    Season(
      name: "Season 2",
      episodes:[
        Episode(
          title: "Return of the Hero",
          image: "https://i.ibb.co/DDDJNsFX/images-3.jpg",
          duration: "25m 00s",
          views: "3.2M",
          videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
        ),
      ],
    ),
  ];
}

final List<Anime> animeData =[
  Anime(
    title: "Solo Leveling",
    genre: "Action",
    image: "https://i.ibb.co/C3rhjGv3/images-1.jpg",
    views: "38K",
    dubColor: const Color(0xFFFF4D4D),
    seasonsList: generateDummySeasons(),
  ),
  Anime(
    title: "Classroom of the Elite",
    genre: "Thriller",
    image: "https://i.ibb.co/vxJtwkcX/k.jpg",
    status: "Completed",
    views: "3K",
    season: "Season 3",
    dubColor: const Color(0xFF4DA6FF),
    seasonsList: generateDummySeasons(),
  ),
  Anime(
    title: "One Piece",
    genre: "Adventure",
    image: "https://i.ibb.co/jvVk3XSY/g.jpg",
    views: "8.1K",
    dubColor: const Color(0xFF4DA6FF),
    seasonsList: generateDummySeasons(),
  ),
  Anime(
    title: "Naruto",
    genre: "Action",
    image: "https://i.ibb.co/YFg2hKvf/j.jpg",
    views: "4.5K",
    dubColor: const Color(0xFFFF9F43),
    seasonsList: generateDummySeasons(),
  ),
  Anime(
    title: "Demon Slayer",
    genre: "Action",
    image: "https://i.ibb.co/yFRNxJbG/o.jpg",
    views: "3.1K",
    dubStatus: "MIX",
    dubColor: const Color(0xFF00C853),
    seasonsList: generateDummySeasons(),
  ),
];

class OrderItem {
  final String planName;
  final String amount;
  final String status;
  final String date;

  OrderItem({
    required this.planName,
    required this.amount,
    required this.status,
    required this.date,
  });
}

List<OrderItem> userOrders =[];

// ==========================================
// MAIN APP & NAVIGATION
// ==========================================
class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.orange,
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
    const Center(child: Text("My List Page")),
    const ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF121212),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
        currentIndex: _index,
        onTap: (i) {
          setState(() {
            _index = i;
          });
        },
        items: const[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.headphones), label: "Dub"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "My List"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text(
          "AnimeMX",
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            CarouselSlider.builder(
              itemCount: 4,
              options: CarouselOptions(
                height: 220,
                autoPlay: true,
                enlargeCenterPage: false,
                viewportFraction: 1.0,
              ),
              itemBuilder: (ctx, i, real) {
                return Stack(
                  fit: StackFit.expand,
                  children:[
                    Image.network(
                      "https://i.ibb.co/C3rhjGv3/images-1.jpg",
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:[Colors.black.withOpacity(0.9), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 15,
                      right: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${i + 1}/4",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 15,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          const Text(
                            "SOLO LEVELING",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "TRENDING",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // 🔥 SMART CONTINUE WATCHING SECTION 🔥
            ValueListenableBuilder<List<CWItem>>(
              valueListenable: continueWatchingNotifier,
              builder: (context, cwList, child) {
                if (cwList.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildCWSection("⏳ Continue Watching", cwList);
              },
            ),

            // TOP PICKS FOR YOU
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text(
                        "Top Picks for You",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "New episodes available now!",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailsPage(anime: animeData[0]),
                        ),
                      );
                    },
                    child: const Text(
                      "Watch Now",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 25),

            _buildCategorySection("🔥 Trending Now", animeData),
            _buildCategorySection("🏆 Popular", animeData.reversed.toList(), hasWhiteOutline: true),
            _buildThumbnailSection("🆕 Latest Episodes", animeData),
            _buildCategorySection("✨ Fantasy", animeData),
            _buildCategorySection("🔪 Thriller", animeData.reversed.toList()),
            _buildCategorySection("💖 Romance", animeData),
            _buildCategorySection("🕵️ Mystery", animeData.reversed.toList()),
            _buildCategorySection("⚔️ Action", animeData),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.auto_awesome, color: Colors.orange),
                  label: const Text(
                    "Explore All Anime",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const Text(
                "See All",
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
              ),
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
              return AnimePosterCard(
                anime: list[index],
                hasWhiteOutline: hasWhiteOutline,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildThumbnailSection(String title, List<Anime> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const Text(
                "See All",
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
              ),
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

  Widget _buildCWSection(String title, List<CWItem> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Row(
                children:[
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.history, color: Colors.orange, size: 20),
                ],
              ),
              const Text(
                "See All",
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
              ),
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
              return CWAnimeCard(item: list[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ==========================================
// CARD COMPONENTS
// ==========================================
class CWAnimeCard extends StatefulWidget {
  final CWItem item;

  const CWAnimeCard({super.key, required this.item});

  @override
  State<CWAnimeCard> createState() => _CWAnimeCardState();
}

class _CWAnimeCardState extends State<CWAnimeCard> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    double progress = 0.0;
    if (widget.item.totalDuration.inMilliseconds > 0) {
      progress = widget.item.position.inMilliseconds / widget.item.totalDuration.inMilliseconds;
    }

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isTapped = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isTapped = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerPage(
              anime: widget.item.anime,
              seasonIndex: widget.item.seasonIndex,
              episodeIndex: widget.item.episodeIndex,
              startPosition: widget.item.position,
            ),
          ),
        );
      },
      onTapCancel: () {
        setState(() {
          _isTapped = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isTapped ? 0.96 : 1.0),
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      widget.item.anime.seasonsList[widget.item.seasonIndex].episodes[widget.item.episodeIndex].image,
                      fit: BoxFit.cover,
                    ),
                    Container(color: Colors.black38),
                    const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.item.anime.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "Episode ${widget.item.episodeIndex + 1}",
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class ThumbnailAnimeCard extends StatefulWidget {
  final Anime anime;
  final bool isLatest;

  const ThumbnailAnimeCard({
    super.key,
    required this.anime,
    this.isLatest = false,
  });

  @override
  State<ThumbnailAnimeCard> createState() => _ThumbnailAnimeCardState();
}

class _ThumbnailAnimeCardState extends State<ThumbnailAnimeCard> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isTapped = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isTapped = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailsPage(anime: widget.anime)),
        );
      },
      onTapCancel: () {
        setState(() {
          _isTapped = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isTapped ? 0.96 : 1.0),
        width: 180,
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
                    Image.network(
                      widget.anime.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    if (widget.isLatest) ...[
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children:[
                              const Icon(Icons.visibility, color: Colors.orange, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                widget.anime.views,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Ep 12",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.anime.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              "Latest Episode",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimePosterCard extends StatefulWidget {
  final Anime anime;
  final bool hasWhiteOutline;

  const AnimePosterCard({
    super.key,
    required this.anime,
    this.hasWhiteOutline = false,
  });

  @override
  State<AnimePosterCard> createState() => _AnimePosterCardState();
}

class _AnimePosterCardState extends State<AnimePosterCard> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isTapped = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isTapped = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailsPage(anime: widget.anime)),
        );
      },
      onTapCancel: () {
        setState(() {
          _isTapped = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isTapped ? 0.96 : 1.0),
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.hasWhiteOutline ? Colors.white : Colors.white.withOpacity(0.1),
            width: widget.hasWhiteOutline ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children:[
              Image.network(
                widget.anime.image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:[Colors.black.withOpacity(0.95), Colors.black.withOpacity(0.3), Colors.transparent],
                      stops: const [0.0, 0.45, 1.0],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.anime.rating,
                        style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                      ),
                      child: Text(
                        widget.anime.dubStatus,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children:[
                    Text(
                      widget.anime.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${widget.anime.season} • ${widget.anime.status}",
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children:[
                        Icon(Icons.remove_red_eye_outlined, color: Colors.white.withOpacity(0.75), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "${widget.anime.views} Views",
                          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
                        ),
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
// DETAILS PAGE
// ==========================================
class DetailsPage extends StatefulWidget {
  final Anime anime;

  const DetailsPage({super.key, required this.anime});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  int _selectedSeasonIndex = 0;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Colors.orange;
    const Color darkBg = Color(0xFF0F0F0F);
    
    final currentSeason = widget.anime.seasonsList[_selectedSeasonIndex];
    final episodesList = currentSeason.episodes;

    return Scaffold(
      backgroundColor: darkBg,
      body: CustomScrollView(
        slivers:[
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children:[
                  Image.network(
                    widget.anime.image,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:[darkBg, darkBg.withOpacity(0.5), Colors.transparent],
                        stops: const [0.0, 0.4, 1.0],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
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
                  Text(
                    widget.anime.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children:[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.anime.rating,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "• Dub | Action, Thriller, Drama",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      onPressed: () {
                        if (episodesList.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerPage(
                                anime: widget.anime,
                                seasonIndex: _selectedSeasonIndex,
                                episodeIndex: 0,
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      label: const Text(
                        "Play Season 1",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    "Kiyotaka Ayanokouji enters the prestigious Tokyo Metropolitan Advanced Nurturing High School, which is dedicated to fostering the best and brightest students. But he ends up in Class-D, a dumping ground for the school's worst. A cruel meritocracy awaits where he must use his dark intellect to survive in a school of ruthless competition and psychological warfare.",
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Text(
                      _isExpanded ? "Read Less" : "Read More",
                      style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  const Text("Seasons", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.anime.seasonsList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _buildSeasonTab(index, widget.anime.seasonsList[index].name, primaryColor),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text("Episodes", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  ValueListenableBuilder<List<CWItem>>(
                    valueListenable: continueWatchingNotifier,
                    builder: (context, cwList, child) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: episodesList.length,
                        itemBuilder: (context, index) {
                          final ep = episodesList[index];
                          
                          double progress = 0.0;
                          final cwIndex = cwList.indexWhere((item) => 
                            item.anime.title == widget.anime.title && 
                            item.seasonIndex == _selectedSeasonIndex && 
                            item.episodeIndex == index
                          );
                          
                          if (cwIndex != -1) {
                            final item = cwList[cwIndex];
                            if (item.totalDuration.inMilliseconds > 0) {
                              progress = item.position.inMilliseconds / item.totalDuration.inMilliseconds;
                            }
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoPlayerPage(
                                    anime: widget.anime,
                                    seasonIndex: _selectedSeasonIndex,
                                    episodeIndex: index,
                                    startPosition: cwIndex != -1 ? cwList[cwIndex].position : null,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children:[
                                  SizedBox(
                                    width: 120,
                                    height: 70,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children:[
                                          Image.network(
                                            ep.image,
                                            fit: BoxFit.cover,
                                          ),
                                          if (progress > 0.0)
                                            Positioned(
                                              bottom: 0, left: 0, right: 0,
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                backgroundColor: Colors.black54,
                                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                                                minHeight: 4,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children:[
                                        Text(
                                          "${index + 1}. ${ep.title}",
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children:[
                                            Text(ep.duration, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                            const SizedBox(width: 10),
                                            const Icon(Icons.visibility, color: Colors.white54, size: 12),
                                            const SizedBox(width: 4),
                                            Text(ep.views, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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

  Widget _buildSeasonTab(int index, String title, Color primaryColor) {
    bool isActive = _selectedSeasonIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSeasonIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// VIDEO PLAYER PAGE
// ==========================================
class VideoPlayerPage extends StatefulWidget {
  final Anime anime;
  final int seasonIndex;
  final int episodeIndex;
  final Duration? startPosition;

  const VideoPlayerPage({
    super.key,
    required this.anime,
    required this.seasonIndex,
    required this.episodeIndex,
    this.startPosition,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _isFullScreen = false;
  double _forwardOpacity = 0.0;
  double _rewindOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    final ep = widget.anime.seasonsList[widget.seasonIndex].episodes[widget.episodeIndex];
    _controller = VideoPlayerController.networkUrl(Uri.parse(ep.videoUrl))
      ..initialize().then((_) {
        if (widget.startPosition != null) {
          _controller.seekTo(widget.startPosition!);
        }
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _updateContinueWatching();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  void _updateContinueWatching() {
    if (!_controller.value.isInitialized) return;
    final pos = _controller.value.position;
    final dur = _controller.value.duration;

    if (pos > const Duration(seconds: 2)) {
      final list = List<CWItem>.from(continueWatchingNotifier.value);
      final existingIdx = list.indexWhere((item) => 
        item.anime.title == widget.anime.title && 
        item.seasonIndex == widget.seasonIndex &&
        item.episodeIndex == widget.episodeIndex
      );

      if (existingIdx != -1) {
        list[existingIdx].position = pos;
        list[existingIdx].totalDuration = dur;
        final item = list.removeAt(existingIdx);
        list.insert(0, item);
      } else {
        list.insert(0, CWItem(
          anime: widget.anime,
          seasonIndex: widget.seasonIndex,
          episodeIndex: widget.episodeIndex,
          position: pos,
          totalDuration: dur,
        ));
      }
      continueWatchingNotifier.value = list;
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _skipForward() {
    _controller.seekTo(_controller.value.position + const Duration(seconds: 10));
    setState(() => _forwardOpacity = 1.0);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _forwardOpacity = 0.0);
    });
  }

  void _skipBackward() {
    _controller.seekTo(_controller.value.position - const Duration(seconds: 10));
    setState(() => _rewindOpacity = 1.0);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _rewindOpacity = 0.0);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Colors.orange;
    final currentSeason = widget.anime.seasonsList[widget.seasonIndex];
    final currentEpisode = currentSeason.episodes[widget.episodeIndex];
    bool hasNextEpisode = widget.episodeIndex < currentSeason.episodes.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            AspectRatio(
              aspectRatio: _isFullScreen ? MediaQuery.of(context).size.aspectRatio : 16 / 9,
              child: Stack(
                children:[
                  _controller.value.isInitialized
                      ? Center(child: VideoPlayer(_controller))
                      : const Center(child: CircularProgressIndicator(color: primaryColor)),
                  
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: AnimatedOpacity(
                        opacity: _rewindOpacity,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children:[
                              Icon(Icons.replay_10, color: Colors.white, size: 30),
                              Text("-10s", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: AnimatedOpacity(
                        opacity: _forwardOpacity,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children:[
                              Icon(Icons.forward_10, color: Colors.white, size: 30),
                              Text("+10s", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

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
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                                  onPressed: () {
                                    if (_isFullScreen) _toggleFullScreen();
                                    Navigator.pop(context);
                                  },
                                ),
                                Row(
                                  children:[
                                    IconButton(icon: const Icon(Icons.cast, color: Colors.white), onPressed: () {}),
                                    IconButton(
                                      icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white),
                                      onPressed: _toggleFullScreen,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children:[
                                IconButton(
                                  icon: const Icon(Icons.replay_10, color: Colors.white, size: 40),
                                  onPressed: _skipBackward,
                                ),
                                IconButton(
                                  icon: Icon(
                                    _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _controller.value.isPlaying ? _controller.pause() : _controller.play();
                                    });
                                    _updateContinueWatching();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.forward_10, color: Colors.white, size: 40),
                                  onPressed: _skipForward,
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                children:[
                                  ValueListenableBuilder(
                                    valueListenable: _controller,
                                    builder: (context, VideoPlayerValue value, child) {
                                      return Text(
                                        _formatDuration(value.position),
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      );
                                    },
                                  ),
                                  Expanded(
                                    child: ValueListenableBuilder(
                                      valueListenable: _controller,
                                      builder: (context, VideoPlayerValue value, child) {
                                        return SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 4.0,
                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                                          ),
                                          child: Slider(
                                            activeColor: primaryColor,
                                            inactiveColor: Colors.white24,
                                            min: 0.0,
                                            max: value.duration.inSeconds.toDouble() == 0 ? 100 : value.duration.inSeconds.toDouble(),
                                            value: value.position.inSeconds.toDouble(),
                                            onChanged: (val) {
                                              _controller.seekTo(Duration(seconds: val.toInt()));
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  ValueListenableBuilder(
                                    valueListenable: _controller,
                                    builder: (context, VideoPlayerValue value, child) {
                                      return Text(
                                        _formatDuration(value.duration),
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _toggleControls,
                      child: Container(color: Colors.transparent),
                    ),
                ],
              ),
            ),
            
            if (!_isFullScreen)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text(
                        "Episode ${widget.episodeIndex + 1} | ${currentEpisode.title}",
                        style: const TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.anime.title,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),
                      
                      if (hasNextEpisode) ...[
                        const Text(
                          "Up Next",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerPage(
                                  anime: widget.anime,
                                  seasonIndex: widget.seasonIndex,
                                  episodeIndex: widget.episodeIndex + 1,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children:[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    currentSeason.episodes[widget.episodeIndex + 1].image,
                                    width: 120,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children:[
                                      Text(
                                        "Episode ${widget.episodeIndex + 2}",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        currentSeason.episodes[widget.episodeIndex + 1].duration,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
                              ],
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// OTHER SCREENS (BROWSE, DUBS, PROFILE, ETC)
// ==========================================
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
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search anime, movies, episodes...",
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                    suffixIcon: Icon(Icons.cancel, color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Recent Searches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              _buildRecentItem("Naruto"),
              _buildRecentItem("One Piece"),
              const SizedBox(height: 24),
              const Text("Trending Searches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children:[
                        _buildTrendingItem("1", "Solo Leveling"),
                        _buildTrendingItem("3", "Chainsaw Man"),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children:[
                        _buildTrendingItem("2", "Jujutsu Kaisen"),
                        _buildTrendingItem("4", "Tokyo Revengers"),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text("Browse by Genre", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children:[
                  _buildGenreCard("Action", "Action", Icons.sports_martial_arts, const Color(0xFF3A1C1C), Colors.redAccent),
                  _buildGenreCard("Comedy", "Hilarity", Icons.sentiment_very_satisfied, const Color(0xFF2D1B4E), Colors.purpleAccent),
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

  Widget _buildRecentItem(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:[
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          Row(
            children:[
              Icon(Icons.close, size: 18, color: Colors.grey[500]),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[600]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingItem(String num, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children:[
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
            child: Center(child: Text(num, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreCard(String title, String subtitle, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children:[
          Icon(icon, size: 30, color: iconColor),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
            ],
          ),
        ],
      ),
    );
  }
}

class DubsScreen extends StatelessWidget {
  const DubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F0F),
          elevation: 0,
          toolbarHeight: 10,
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            indicatorWeight: 3,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.white70,
            tabs:[
              Tab(text: "ADR DUBBED"),
              Tab(text: "ORIGINAL"),
            ],
          ),
        ),
        body: TabBarView(
          children:[
            GridView.builder(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 14, mainAxisSpacing: 16),
              itemCount: animeData.length,
              itemBuilder: (context, index) => GridAnimeCard(anime: animeData[index]),
            ),
            GridView.builder(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 14, mainAxisSpacing: 16),
              itemCount: animeData.length,
              itemBuilder: (context, index) => GridAnimeCard(anime: animeData[index]),
            ),
          ],
        ),
      ),
    );
  }
}

class GridAnimeCard extends StatefulWidget {
  final Anime anime;
  const GridAnimeCard({super.key, required this.anime});

  @override
  State<GridAnimeCard> createState() => _GridAnimeCardState();
}

class _GridAnimeCardState extends State<GridAnimeCard> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isTapped = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isTapped = false;
        });
        Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsPage(anime: widget.anime)));
      },
      onTapCancel: () {
        setState(() {
          _isTapped = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isTapped ? 0.96 : 1.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Text(widget.anime.rating, style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5)),
                      child: Text(widget.anime.dubStatus, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 12,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children:[
                    Text(widget.anime.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text("${widget.anime.season} • ${widget.anime.status}", style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children:[
                        Icon(Icons.remove_red_eye_outlined, color: Colors.white.withOpacity(0.75), size: 12),
                        const SizedBox(width: 4),
                        Text("${widget.anime.views} Views", style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children:[
                      Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 15)],
                          image: const DecorationImage(image: NetworkImage("https://i.ibb.co/vxJtwkcX/k.jpg"), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children:[
                          Icon(Icons.edit, color: Colors.orange, size: 14),
                          SizedBox(width: 4),
                          Text("Edit Profile", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:[
                            const Text("Flexxy xD", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, boxShadow:[BoxShadow(color: Colors.greenAccent, blurRadius: 8)])),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text("flexxy0xd@gmail.com", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          children:[
                            const Text("UID: VcXZJDac...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(width: 8),
                            const Icon(Icons.copy_outlined, color: Colors.grey, size: 14),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF8B4513), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orangeAccent.withOpacity(0.6))),
                          child: const Text("BRONZE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(colors:[Colors.orangeAccent, Colors.deepOrange], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      const Row(
                        children:[
                          Icon(Icons.workspace_premium, color: Colors.white, size: 26),
                          SizedBox(width: 8),
                          Text("Go Premium", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text("Unlock all episodes & Remove ads", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children:[
                          _buildPricePill("₹90"),
                          const SizedBox(width: 8),
                          _buildPricePill("₹160"),
                          const SizedBox(width: 8),
                          _buildPricePill("₹299"),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildMenuItem(context, Icons.receipt_long, "Activity & Orders", const ActivityPage()),
              _buildMenuItem(context, Icons.payment, "Payment Proof", const PaymentProofPage()),
              _buildMenuItem(context, Icons.headset_mic, "Support", const SupportPage()),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.grey.withOpacity(0.3),
          highlightColor: Colors.grey.withOpacity(0.3),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children:[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: Colors.white70, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  void _launchUPI(BuildContext context, String amount, String plan) async {
    final Uri uri = Uri.parse("upi://pay?pa=wicvlox.i@oksbi&pn=AnimeMX&am=$amount&cu=INR&tn=Buy%20$plan");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No UPI App found on this device!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Go Premium", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children:[
            const Text("Choose Your Plan", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text("Unlock exclusive content & an ad-free experience.", style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 30),
            _buildPlanCard(context, "🥈 Silver Plan", "HD (720p) • Medium Ads", "₹90", false),
            const SizedBox(height: 15),
            _buildPlanCard(context, "🥇 Gold Plan", "Full HD (1080p) • Low Ads", "₹160", true),
            const SizedBox(height: 15),
            _buildPlanCard(context, "💎 Diamond Plan", "Ultra HD (4K) • Ad-Free", "₹299", false),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, String title, String subtitle, String price, bool isGold) {
    String cleanPrice = price.replaceAll("₹", "");
    return Stack(
      children:[
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: isGold ? Colors.amber : Colors.white24, width: isGold ? 2 : 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children:[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children:[
                      Text(price, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const Text("/mo", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isGold ? Colors.amber : Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _launchUPI(context, cleanPrice, title.split(" ")[1]),
                    child: Text("Select", style: TextStyle(color: isGold ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              )
            ],
          ),
        ),
        if (isGold)
          Positioned(
            top: 0, left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8))),
              child: const Text("RECOMMENDED", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          )
      ],
    );
  }
}

class PaymentProofPage extends StatefulWidget {
  const PaymentProofPage({super.key});
  @override
  State<PaymentProofPage> createState() => _PaymentProofPageState();
}

class _PaymentProofPageState extends State<PaymentProofPage> {
  File? _imageFile;
  String _selectedAmount = "90";
  String _selectedPlan = "Silver Plan";

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Verify Payment", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children:[
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(child: Text("Verify your payment to activate plan instantly.", style: TextStyle(color: Colors.blue))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text("Select Amount Paid", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              value: _selectedAmount,
              dropdownColor: const Color(0xFF1A1A1A),
              items: const[
                DropdownMenuItem(value: "90", child: Text("₹90 (Silver)")),
                DropdownMenuItem(value: "160", child: Text("₹160 (Gold)")),
                DropdownMenuItem(value: "299", child: Text("₹299 (Diamond)")),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedAmount = val!;
                  if (val == "90") _selectedPlan = "Silver Plan";
                  if (val == "160") _selectedPlan = "Gold Plan";
                  if (val == "299") _selectedPlan = "Diamond Plan";
                });
              },
            ),
            const SizedBox(height: 24),
            const Text("Upload Screenshot", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.5), style: BorderStyle.solid, width: 2),
                ),
                child: _imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(_imageFile!, fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:[
                          Icon(Icons.cloud_upload_outlined, color: Colors.orange, size: 50),
                          SizedBox(height: 10),
                          Text("Tap to upload Screenshot", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text("Supports JPG, PNG", style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Transaction ID / UTR", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "e.g. 3089XXXXXXX",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() {
                    userOrders.insert(0, OrderItem(planName: _selectedPlan, amount: "₹$_selectedAmount", status: "Pending", date: "Today"));
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Proof Submitted Successfully!")));
                  Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context));
                },
                child: const Text("Submit & Verify", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Help Center", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrange]),
              ),
              child: Row(
                children:[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.headset_mic, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        Text("How can we help?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("We're here to help you with any issues.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Contact Options", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSupportTile(Icons.telegram, "Telegram", "Instant Chat Support", Colors.blueAccent),
            _buildSupportTile(Icons.chat, "WhatsApp", "Chat Support", Colors.green),
            _buildSupportTile(Icons.email, "Email", "24-hour Response", Colors.orangeAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTile(IconData icon, String title, String sub, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: Row(
        children:[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
        ],
      ),
    );
  }
}

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Activity & Orders", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: userOrders.isEmpty
          ? const Center(child: Text("No recent orders.", style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userOrders.length,
              itemBuilder: (ctx, i) {
                final order = userOrders[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(color: order.status == "Pending" ? Colors.orange : Colors.green, width: 4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Text(order.planName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("${order.amount} • ${order.date}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: order.status == "Pending" ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          order.status,
                          style: TextStyle(
                            color: order.status == "Pending" ? Colors.orange : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}