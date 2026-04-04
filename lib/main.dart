// main.dart file for User Panel App

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

// Import Firebase packages (Assuming these are in pubspec.yaml)
// import 'package:firebase_core/firebase_core.dart'; // Uncomment this after manual connection
// import 'package:firebase_auth/firebase_auth.dart'; // Uncomment this after manual connection
// import 'package:cloud_firestore/cloud_firestore.dart'; // Uncomment this after manual connection

// --- GLOBAL STATE ---

// User details (will be loaded after login)
String currentUserName = "Guest User";
String currentUserEmail = "guest@example.com";
String userMobileNumber = ""; // Will be updated via Add Info screen
String userActivePlan = ""; // Will be updated after Admin approval

// For demo purposes (will be removed when connecting to Firebase)
List<String> globalRecentSearches = [];

// Continue Watching Data Model
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

// Saved Episodes Data Model
class SavedEpisode {
  final Anime anime;
  final int seasonIndex;
  final int episodeIndex;

  SavedEpisode({
    required this.anime,
    required this.seasonIndex,
    required this.episodeIndex,
  });
}
final ValueNotifier<List<SavedEpisode>> myListNotifier = ValueNotifier([]);

// Anime Data Models
class Episode {
  final String title;
  final String image;
  final String duration;
  final String views;
  final String videoUrl;
  Episode({required this.title, required this.image, required this.duration, required this.views, required this.videoUrl});
}
class Season {
  final String name;
  final List<Episode> episodes;
  Season({required this.name, required this.episodes});
}
class Anime {
  final String title;
  final String image;
  final String genre;
  final String rating;
  final String dubStatus;
  final String season;
  final String status;
  final String views;
  final Color dubColor;
  final List<Season> seasonsList;
  Anime({required this.title, required this.image, this.genre = "Action", this.rating = "PG-13", this.dubStatus = "DUB", this.season = "Season 1", this.status = "Ongoing", this.views = "1.1M", this.dubColor = const Color(0xFFFF4D4D), required this.seasonsList});
}

// DUMMY DATA FOR DEMO
List<Season> generateDummySeasons() {
  return[
    Season(name: "Season 1", episodes:[
      Episode(title: "The Beginning", image: "https://i.ibb.co/rW2Zk9B/images.jpg", duration: "24m 10s", views: "2.1M", videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"),
      Episode(title: "A New Threat", image: "https://i.ibb.co/C3rhjGv3/images-1.jpg", duration: "23m 45s", views: "1.8M", videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"),
    ]),
    Season(name: "Season 2", episodes:[
      Episode(title: "Return of Hero", image: "https://i.ibb.co/DDDJNsFX/images-3.jpg", duration: "25m 00s", views: "3.2M", videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4"),
    ]),
  ];
}
List<Season> generateClassroomOfEliteSeasons() {
  return[
    Season(name: "Season 1", episodes:[
      Episode(title: "Episode 1", image: "https://i.ibb.co/vxJtwkcX/k.jpg", duration: "24m 10s", views: "3.8K", videoUrl: "https://animemx-proxy.onrender.com/stream/AgADXx8AAg-FSFY"), 
      Episode(title: "Episode 2", image: "https://i.ibb.co/vxJtwkcX/k.jpg", duration: "23m 45s", views: "1.8M", videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"),
    ]),
    Season(name: "Season 2", episodes:[
      Episode(title: "Episode 1", image: "https://i.ibb.co/vxJtwkcX/k.jpg", duration: "24m 00s", views: "2.5M", videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4"),
    ]),
  ];
}
final List<Anime> animeData =[
  Anime(title: "Solo Leveling", genre: "Action", image: "https://i.ibb.co/C3rhjGv3/images-1.jpg", views: "38K", dubColor: const Color(0xFFFF4D4D), season: "S1", seasonsList: generateDummySeasons()),
  Anime(title: "Classroom of the Elite", genre: "Thriller", image: "https://i.ibb.co/vxJtwkcX/k.jpg", status: "Completed", views: "3K", dubColor: const Color(0xFF4DA6FF), season: "S3", seasonsList: generateClassroomOfEliteSeasons()),
  Anime(title: "One Piece", genre: "Adventure", image: "https://i.ibb.co/jvVk3XSY/g.jpg", views: "8.1K", dubColor: const Color(0xFF4DA6FF), season: "S1", seasonsList: generateDummySeasons()),
  Anime(title: "Naruto", genre: "Action", image: "https://i.ibb.co/YFg2hKvf/j.jpg", views: "4.5K", dubColor: const Color(0xFFFF9F43), season: "S1", seasonsList: generateDummySeasons()),
  Anime(title: "Demon Slayer", genre: "Action", image: "https://i.ibb.co/yFRNxJbG/o.jpg", views: "3.1K", dubStatus: "MIX", dubColor: const Color(0xFF00C853), season: "S2", seasonsList: generateDummySeasons()),
  Anime(title: "Death Note", genre: "Mystery", image: "https://i.ibb.co/L0x9WvY/the-eminence-in-shadow.jpg", views: "9M", dubColor: const Color(0xFF7A5CFF), season: "S1", seasonsList: generateDummySeasons()),
  Anime(title: "Your Name", genre: "Romance", image: "https://i.ibb.co/rW2Zk9B/images.jpg", views: "2M", dubColor: const Color(0xFFFF4D4D), season: "Movie", seasonsList: generateDummySeasons()),
  Anime(title: "Bleach: Thousand-Year Blood War - The Conflict", genre: "Action", image: "https://i.ibb.co/DDDJNsFX/images-3.jpg", status: "Coming Soon", views: "0", dubColor: Colors.grey, season: "S3", seasonsList: []),
];

class OrderItem {
  final String planName;
  final String amount;
  final String status;
  final String date;
  OrderItem({required this.planName, required this.amount, required this.status, required this.date});
}
List<OrderItem> userOrders =[];

// --- Main App Entry Point ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // --- Firebase Initialization ---
  // await Firebase.initializeApp(); // Uncomment this line after Firebase connection steps

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

  void _goToSearch() {
    setState(() {
      _index = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages =[
      HomeScreen(onSearchTap: _goToSearch),
      const BrowseScreen(),
      const DubsScreen(),
      const MyListScreen(),
      const ProfileScreen()
    ];

    return Scaffold(
      extendBody: true,
      body: pages[_index],
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
  final VoidCallback onSearchTap;
  
  const HomeScreen({super.key, required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sliderItems = [
      {'anime': animeData[0], 'tag': 'TRENDING', 'color': Colors.orange},
      {'anime': animeData[2], 'tag': 'POPULAR', 'color': Colors.cyan},
      {'anime': animeData[6], 'tag': 'RECOMMENDED', 'color': Colors.blueAccent},
      {'anime': animeData[7], 'tag': 'COMING SOON', 'color': Colors.grey}, 
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: Drawer(
        backgroundColor: const Color(0xFF121212),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(bottom: BorderSide(color: Colors.white12, width: 1))
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage("https://i.ibb.co/vxJtwkcX/k.jpg"),
                        fit: BoxFit.cover
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Flexxy xD", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text("flexxy0xd@gmail.com", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        if (userActivePlan.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: Text(userActivePlan.toUpperCase(), style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ]
                      ],
                    ),
                  )
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white70),
              title: const Text("Home", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              title: const Text("Go Premium", style: TextStyle(color: Colors.amber)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.white70),
              title: const Text("Website", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.headset_mic, color: Colors.white70),
              title: const Text("Support", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white70),
              title: const Text("Privacy Policy", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white70),
              title: const Text("About Us", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutUsPage()));
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(color: Colors.white12, thickness: 1),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
              title: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logged out successfully!")));
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          }
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
        actions:[
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: onSearchTap,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            CarouselSlider.builder(
              itemCount: sliderItems.length,
              options: CarouselOptions(
                height: 220,
                autoPlay: true,
                enlargeCenterPage: false,
                viewportFraction: 1.0,
              ),
              itemBuilder: (ctx, i, real) {
                final anime = sliderItems[i]['anime'] as Anime;
                final tag = sliderItems[i]['tag'] as String;
                final tagColor = sliderItems[i]['color'] as Color;

                return GestureDetector(
                  onTap: () {
                    bool hasEpisodes = false;
                    for (var season in anime.seasonsList) {
                      if (season.episodes.isNotEmpty) {
                        hasEpisodes = true;
                        break;
                      }
                    }

                    if (tag == "COMING SOON" && !hasEpisodes) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Episodes coming soon!")));
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: anime)));
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children:[
                      Image.network(
                        anime.image,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.95), Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            stops: const [0.0, 0.6]
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
                            "${i + 1}/${sliderItems.length}",
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
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.85,
                              child: Text(
                                anime.title.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20, 
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: tagColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // CONTINUE WATCHING
            ValueListenableBuilder<List<CWItem>>(
              valueListenable: continueWatchingNotifier,
              builder: (context, cwList, child) {
                if (cwList.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildThumbnailSection(context, "Continue Watching", Icons.history, Colors.orange, true, cwList: cwList);
              },
            ),

            // TOP PICKS FOR YOU
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      const Text(
                        "Top Picks for You",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "New episodes available now!",
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
                        MaterialPageRoute(builder: (_) => DetailsPage(anime: animeData[0])),
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

            _buildPortraitSection(context, "Trending Now", Icons.local_fire_department_rounded, Colors.orange, animeData),
            _buildPopularSection(context, "Popular Anime", Icons.emoji_events, Colors.amber, animeData.reversed.toList()),
            _buildThumbnailSection(context, "Latest Episodes", null, null, false, animeList: animeData.where((a) => a.seasonsList.isNotEmpty).toList()),
            _buildPortraitSection(context, "Thriller", null, null, animeData.reversed.toList()),
            _buildPortraitSection(context, "Action", null, null, animeData),
            _buildPortraitSection(context, "Romance", null, null, animeData.reversed.toList()),
            _buildPortraitSection(context, "Horror & Mystery", null, null, animeData),
            _buildPortraitSection(context, "Comedy", null, null, animeData.reversed.toList()),
          ],
        ),
      ),
    );
  }

  // PORTRAIT CARD SECTION
  Widget _buildPortraitSection(BuildContext context, String title, IconData? icon, Color? iconColor, List<Anime> list) {
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
                  if (icon != null) ...[
                    const SizedBox(width: 6),
                    Icon(icon, color: iconColor, size: 20),
                  ],
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SeeAllCategoryPage(title: title, animeList: list)));
                },
                child: const Text(
                  "See All",
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return PortraitTextBelowCard(anime: list[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // POPULAR OVERLAY SECTION
  Widget _buildPopularSection(BuildContext context, String title, IconData icon, Color iconColor, List<Anime> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children:[
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Icon(icon, color: iconColor, size: 20),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SeeAllCategoryPage(title: title, animeList: list)));
                },
                child: const Text(
                  "See All",
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return OverlayPopularCard(anime: list[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // THUMBNAIL SECTION (For CW & Latest)
  Widget _buildThumbnailSection(BuildContext context, String title, IconData? icon, Color? iconColor, bool isCW, {List<CWItem>? cwList, List<Anime>? animeList}) {
    int itemCount = isCW ? cwList!.length : animeList!.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children:[
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 6),
                    Icon(icon, color: iconColor, size: 20),
                  ],
                ],
              ),
              GestureDetector(
                onTap: () {
                  List<Anime> listToPass = isCW ? cwList!.map((cw) => cw.anime).toList() : animeList!;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SeeAllCategoryPage(title: title, animeList: listToPass)));
                },
                child: const Text(
                  "See All",
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (isCW) {
                return CWAnimeCard(item: cwList![index]);
              } else {
                return ThumbnailLatestCard(anime: animeList![index]);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ==========================================
// "SEE ALL" CATEGORY PAGE
// ==========================================
class SeeAllCategoryPage extends StatelessWidget {
  final String title;
  final List<Anime> animeList;

  const SeeAllCategoryPage({super.key, required this.title, required this.animeList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 40),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, 
          childAspectRatio: 0.70, 
          crossAxisSpacing: 14, 
          mainAxisSpacing: 16
        ),
        itemCount: animeList.length,
        itemBuilder: (context, index) => GridCategoryCard(anime: animeList[index], pageTitle: title),
      ),
    );
  }
}

// ==========================================
// HOME CARD WIDGETS
// ==========================================

class PortraitTextBelowCard extends StatelessWidget {
  final Anime anime;
  const PortraitTextBelowCard({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: anime)));
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(anime.image, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              anime.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              anime.genre,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class OverlayPopularCard extends StatelessWidget {
  final Anime anime;
  const OverlayPopularCard({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: anime)));
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children:[
              Image.network(anime.image, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:[Colors.black.withOpacity(0.9), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(color: Colors.cyan, borderRadius: BorderRadius.circular(4)),
                  child: const Text("POPULAR", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Text(
                      anime.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:[
                        Text("${anime.season} | Ep 3", style: const TextStyle(color: Colors.white70, fontSize: 10)),
                        Row(
                          children:[
                            const Icon(Icons.visibility, color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(anime.views, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class GridCategoryCard extends StatelessWidget {
  final Anime anime;
  final String pageTitle;
  const GridCategoryCard({super.key, required this.anime, required this.pageTitle});

  @override
  Widget build(BuildContext context) {
    String? tagText;
    Color? tagBgColor;
    Color tagTextColor = Colors.black;

    if (pageTitle == "Trending Now") {
      tagText = "TRENDING";
      tagBgColor = Colors.orange;
      tagTextColor = Colors.white;
    } else if (pageTitle == "Popular Anime") {
      tagText = "POPULAR";
      tagBgColor = Colors.cyan;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: anime)));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children:[
              Image.network(anime.image, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:[Colors.black.withOpacity(0.9), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                    ),
                  ),
                ),
              ),
              if (tagText != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(color: tagBgColor, borderRadius: BorderRadius.circular(4)),
                    child: Text(tagText, style: TextStyle(color: tagTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Text(
                      anime.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:[
                        Text("${anime.season} | Ep 3", style: const TextStyle(color: Colors.white70, fontSize: 10)),
                        Row(
                          children:[
                            const Icon(Icons.visibility, color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(anime.views, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ThumbnailLatestCard extends StatelessWidget {
  final Anime anime;
  const ThumbnailLatestCard({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: anime)));
      },
      child: Container(
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
                  fit: StackFit.expand,
                  children:[
                    Image.network(anime.image, fit: BoxFit.cover),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          children:[
                            const Icon(Icons.visibility, color: Colors.orange, size: 12),
                            const SizedBox(width: 4),
                            Text(anime.views, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                        child: const Text("Ep 12", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              anime.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text("Latest Episode", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

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
    
    if (widget.anime.seasonsList.isEmpty) {
      return Scaffold(
        backgroundColor: darkBg,
        appBar: AppBar(backgroundColor: Colors.black, title: Text(widget.anime.title)),
        body: const Center(child: Text("Episodes Coming Soon!", style: TextStyle(color: Colors.white))),
      );
    }

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
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
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
// MY LIST SCREEN
// ==========================================
class MyListScreen extends StatelessWidget {
  const MyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("My List", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<SavedEpisode>>(
        valueListenable: myListNotifier,
        builder: (context, savedList, child) {
          if (savedList.isEmpty) {
            return const Center(
              child: Text(
                "Your list is empty.\nSave episodes to watch later!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16).copyWith(bottom: 100),
            itemCount: savedList.length,
            itemBuilder: (context, index) {
              final item = savedList[index];
              final ep = item.anime.seasonsList[item.seasonIndex].episodes[item.episodeIndex];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerPage(
                        anime: item.anime,
                        seasonIndex: item.seasonIndex,
                        episodeIndex: item.episodeIndex,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children:[
                      SizedBox(
                        width: 140,
                        height: 90,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                          child: Stack(
                            fit: StackFit.expand,
                            children:[
                              Image.network(ep.image, fit: BoxFit.cover),
                              Container(color: Colors.black38),
                              const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 36)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:[
                              Text(
                                item.anime.title,
                                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ep.title,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${item.anime.seasonsList[item.seasonIndex].name} | Episode ${item.episodeIndex + 1}",
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.bookmark, color: Colors.orange),
                        onPressed: () {
                          final list = List<SavedEpisode>.from(myListNotifier.value);
                          list.removeAt(index);
                          myListNotifier.value = list;
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// FAST LOAD VIDEO PLAYER PAGE
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

  int likes = 12400;
  int dislikes = 230;
  bool isLiked = false;
  bool isDisliked = false;

  @override
  void initState() {
    super.initState();
    final ep = widget.anime.seasonsList[widget.seasonIndex].episodes[widget.episodeIndex];
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(ep.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
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
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _forwardOpacity = 0.0);
    });
  }

  void _skipBackward() {
    _controller.seekTo(_controller.value.position - const Duration(seconds: 10));
    setState(() => _rewindOpacity = 1.0);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _rewindOpacity = 0.0);
    });
  }

  void _toggleLike() {
    setState(() {
      if (isLiked) {
        isLiked = false;
        likes--;
      } else {
        isLiked = true;
        likes++;
        if (isDisliked) {
          isDisliked = false;
          dislikes--;
        }
      }
    });
  }

  void _toggleDislike() {
    setState(() {
      if (isDisliked) {
        isDisliked = false;
        dislikes--;
      } else {
        isDisliked = true;
        dislikes++;
        if (isLiked) {
          isLiked = false;
          likes--;
        }
      }
    });
  }

  bool get _isSaved {
    return myListNotifier.value.any((item) => 
      item.anime.title == widget.anime.title && 
      item.seasonIndex == widget.seasonIndex && 
      item.episodeIndex == widget.episodeIndex
    );
  }

  void _toggleSave() {
    final list = List<SavedEpisode>.from(myListNotifier.value);
    if (_isSaved) {
      list.removeWhere((item) => 
        item.anime.title == widget.anime.title && 
        item.seasonIndex == widget.seasonIndex && 
        item.episodeIndex == widget.episodeIndex
      );
    } else {
      list.add(SavedEpisode(
        anime: widget.anime,
        seasonIndex: widget.seasonIndex,
        episodeIndex: widget.episodeIndex,
      ));
    }
    myListNotifier.value = list;
    setState(() {});
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

    Widget videoContent = Stack(
      children:[
        _controller.value.isInitialized
            ? Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            : const Center(child: CircularProgressIndicator(color: primaryColor)),
        
        // REWIND ANIMATION
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 40),
            child: AnimatedOpacity(
              opacity: _rewindOpacity,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children:[
                    Icon(Icons.fast_rewind, color: Colors.white, size: 36),
                    Text("-10s", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ),

        // FORWARD ANIMATION
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 40),
            child: AnimatedOpacity(
              opacity: _forwardOpacity,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children:[
                    Icon(Icons.fast_forward, color: Colors.white, size: 36),
                    Text("+10s", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ),

        // CONTROLS OVERLAY
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
                                  trackHeight: 3.0, 
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                                ),
                                child: Slider(
                                  activeColor: primaryColor,
                                  inactiveColor: Colors.white24,
                                  min: 0.0,
                                  max: value.duration.inSeconds.toDouble() == 0 ? 100 : value.duration.inSeconds.toDouble(),
                                  value: value.position.inSeconds.toDouble().clamp(0.0, value.duration.inSeconds.toDouble() == 0 ? 100 : value.duration.inSeconds.toDouble()),
                                  onChangeStart: (val) {
                                    _controller.pause(); 
                                  },
                                  onChanged: (val) {
                                    _controller.seekTo(Duration(seconds: val.toInt()));
                                  },
                                  onChangeEnd: (val) {
                                    _controller.play(); 
                                    _updateContinueWatching();
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
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            SizedBox(
              width: double.infinity,
              height: _isFullScreen ? MediaQuery.of(context).size.height : null,
              child: _isFullScreen 
                  ? videoContent
                  : AspectRatio(aspectRatio: 16 / 9, child: videoContent),
            ),
            
            if (!_isFullScreen)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text(
                        "${currentSeason.name} | Episode ${widget.episodeIndex + 1}",
                        style: const TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.anime.title,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentEpisode.title,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      
                      // SLEEK ACTION BAR (LIKE, DISLIKE, SAVE)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children:[
                            GestureDetector(
                              onTap: _toggleLike,
                              child: Row(
                                children:[
                                  Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, color: isLiked ? Colors.orange : Colors.white, size: 22),
                                  const SizedBox(width: 8),
                                  Text(likes.toString(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 24, color: Colors.white24), 
                            GestureDetector(
                              onTap: _toggleDislike,
                              child: Row(
                                children:[
                                  Icon(isDisliked ? Icons.thumb_down : Icons.thumb_down_alt_outlined, color: isDisliked ? Colors.orange : Colors.white, size: 22),
                                  const SizedBox(width: 8),
                                  Text(dislikes.toString(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 24, color: Colors.white24), 
                            GestureDetector(
                              onTap: _toggleSave,
                              child: Row(
                                children:[
                                  Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: _isSaved ? Colors.orange : Colors.white, size: 22),
                                  const SizedBox(width: 8),
                                  Text(_isSaved ? "Saved" : "Save", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children:[
                                SizedBox(
                                  width: 140,
                                  height: 90,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children:[
                                        Image.network(
                                          currentSeason.episodes[widget.episodeIndex + 1].image,
                                          fit: BoxFit.cover,
                                        ),
                                        Container(color: Colors.black38),
                                        const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children:[
                                        Text(
                                          "Episode ${widget.episodeIndex + 2}",
                                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currentSeason.episodes[widget.episodeIndex + 1].title,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children:[
                                            const Icon(Icons.access_time, color: Colors.white54, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              currentSeason.episodes[widget.episodeIndex + 1].duration,
                                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                                            ),
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
// FULLY WORKING BROWSE (SEARCH) SCREEN
// ==========================================
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Anime> _searchResults = [];

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
    } else {
      setState(() {
        _searchResults = animeData.where((anime) {
          return anime.title.toLowerCase().contains(query.toLowerCase()) || 
                 anime.genre.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  void _setSearchQuery(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  void _submitSearch(String query) {
    if (query.trim().isNotEmpty && !globalRecentSearches.contains(query.trim())) {
      setState(() {
        globalRecentSearches.insert(0, query.trim());
      });
    }
    _performSearch(query);
  }

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
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: _searchController,
                  onChanged: _performSearch,
                  onSubmitted: _submitSearch,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search anime, movies, episodes...",
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                    suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(
                          icon: Icon(Icons.cancel, color: Colors.grey[600]), 
                          onPressed: () {
                            _searchController.clear();
                            _performSearch("");
                          }
                        ) 
                      : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              if (_searchController.text.isNotEmpty) ...[
                Text("Search Results for '${_searchController.text}'", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                if (_searchResults.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.only(top: 20), child: Text("No anime found.", style: TextStyle(color: Colors.white54))))
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      childAspectRatio: 0.65, 
                      crossAxisSpacing: 14, 
                      mainAxisSpacing: 16
                    ),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) => GridCategoryCard(anime: _searchResults[index], pageTitle: ""),
                  )
              ] else ...[
                const Text("Recent Searches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                if (globalRecentSearches.isEmpty)
                  const Text("No recent searches.", style: TextStyle(color: Colors.white54))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: globalRecentSearches.length,
                    itemBuilder: (context, index) {
                      return _buildRecentItem(globalRecentSearches[index], index);
                    },
                  ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentItem(String title, int index) {
    return GestureDetector(
      onTap: () => _setSearchQuery(title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            Row(
              children:[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      globalRecentSearches.removeAt(index);
                    });
                  },
                  child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[600]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// DUBS SCREEN
// ==========================================
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
              Tab(text: "DUBBED"),
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
              itemBuilder: (context, index) => GridCategoryCard(anime: animeData[index], pageTitle: ""),
            ),
            GridView.builder(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 14, mainAxisSpacing: 16),
              itemCount: animeData.length,
              itemBuilder: (context, index) => GridCategoryCard(anime: animeData[index], pageTitle: ""),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PROFILE, PREMIUM, ACTIVITY & SUPPORT PAGES
// ==========================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? addedMobileNumber;
  String selectedCountryCode = "+91";
  final TextEditingController _mobileController = TextEditingController();

  void _showAddInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Add Mobile Number", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Colors.black,
                        value: selectedCountryCode,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                        items: const [
                          DropdownMenuItem(value: "+91", child: Text("🇮🇳 +91", style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: "+1", child: Text("🇺🇸 +1", style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: "+44", child: Text("🇬🇧 +44", style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: "+81", child: Text("🇯🇵 +81", style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedCountryCode = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Mobile Number",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.black,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (_mobileController.text.isNotEmpty) {
                      setState(() {
                        addedMobileNumber = "$selectedCountryCode ${_mobileController.text}";
                      });
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mobile number saved!")));
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                          image: const DecorationImage(
                            image: NetworkImage("https://i.ibb.co/vxJtwkcX/k.jpg"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showAddInfoDialog,
                        child: Row(
                          children: const [
                            Icon(Icons.add_circle_outline, color: Colors.orange, size: 14),
                            SizedBox(width: 4),
                            Text("Add Info", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:[
                            const Text("Flexxy xD", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                boxShadow:[BoxShadow(color: Colors.greenAccent, blurRadius: 8)],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text("flexxy0xd@gmail.com", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        
                        if (addedMobileNumber != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children:[
                              Text(addedMobileNumber!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle, color: Colors.green, size: 14),
                            ],
                          ),
                        ],
                        
                        if (userActivePlan.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orangeAccent.withOpacity(0.6)),
                            ),
                            child: Text(userActivePlan.toUpperCase(), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                          ),
                        ]
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
                    gradient: const LinearGradient(
                      colors: [Colors.orangeAccent, Colors.deepOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          _buildPricePill("₹50"),
                          const SizedBox(width: 8),
                          _buildPricePill("₹100"),
                          const SizedBox(width: 8),
                          _buildPricePill("₹150"),
                          const SizedBox(width: 8),
                          _buildPricePill("₹200"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              _buildMenuItem(context, Icons.inventory_2_outlined, "Activity & Orders", const ActivityPage()),
              _buildMenuItem(context, Icons.credit_card, "Payment Proof", const PaymentProofPage()),
              _buildMenuItem(context, Icons.headphones, "Support", const SupportPage()),
              _buildMenuItem(context, Icons.verified_user_outlined, "Privacy Policy", const PrivacyPolicyPage()),
              _buildMenuItem(context, Icons.info_outline, "About Us", const AboutUsPage()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricePill(String price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, Widget page) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF161618),
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
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PLACEHOLDER PAGES FOR NEW MENU OPTIONS
// ==========================================
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Privacy Policy", style: TextStyle(color: Colors.white)), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Text(
          "Privacy Policy\n\nWelcome to AnimeMX. At AnimeMX, we value your privacy. This Privacy Policy outlines how we collect, use, and protect your data.\n\nWe do not sell your personal data to third parties. All user preferences, including recent searches and saved episodes, are stored locally on your device unless connected via cloud synchronization. For more details, please contact our support team.", 
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)
        )
      ),
    );
  }
}

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("About Us", style: TextStyle(color: Colors.white)), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("About AnimeMX", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text(
              "Welcome to AnimeMX, your ultimate destination for streaming the best and latest anime! Our mission is to provide an ad-free, high-quality, and seamless viewing experience for anime lovers around the world.\n\nEnjoy HD & 4K quality, dubbed & subbed versions, and lightning-fast streaming anywhere, anytime.", 
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)
            ),
            SizedBox(height: 30),
            Text("Contact Us", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text("Email: animemx.official@gmail.com", style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        )
      ),
    );
  }
}

// ==========================================
// UPDATED PREMIUM PAGE WITH 4 PLANS
// ==========================================
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Choose Your Plan", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("Unlock exclusive content & an ad-free experience.", style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // HORIZONTAL SCROLLING WIDE CARDS
            SizedBox(
              height: 480,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildNewPlanCard(
                    context: context,
                    title: "Lite Plan",
                    price: "₹50",
                    quality: "720p",
                    ads: "NO",
                    slot: "1",
                    limit: "50 minutes",
                    limitSub: "(0.8 hrs)",
                    hasEarlyAccess: false,
                    hasAllPremium: null,
                    color: Colors.orange,
                    icon: Icons.local_fire_department,
                  ),
                  const SizedBox(width: 20),
                  _buildNewPlanCard(
                    context: context,
                    title: "Plus Plan",
                    price: "₹100",
                    quality: "1080p",
                    ads: "NO",
                    slot: "2",
                    limit: "240 minutes",
                    limitSub: "(4 hrs)",
                    hasEarlyAccess: false,
                    hasAllPremium: null,
                    color: Colors.amber,
                    icon: Icons.star,
                    badgeText: "MOST POPULAR",
                  ),
                  const SizedBox(width: 20),
                  _buildNewPlanCard(
                    context: context,
                    title: "Pro Plan",
                    price: "₹150",
                    quality: "1080p",
                    ads: "NO",
                    slot: "3",
                    limit: "480 minutes",
                    limitSub: "(8 hrs)",
                    hasEarlyAccess: true,
                    hasAllPremium: true,
                    color: Colors.lightBlueAccent,
                    icon: Icons.auto_awesome, 
                  ),
                  const SizedBox(width: 20),
                  _buildNewPlanCard(
                    context: context,
                    title: "Ultra Plan",
                    price: "₹200",
                    quality: "1080p",
                    ads: "NO", 
                    slot: "4",
                    limit: "Unlimited",
                    limitSub: null,
                    hasEarlyAccess: true,
                    hasAllPremium: true,
                    earlyAccessText: "YES", 
                    allPremiumText: "YES",
                    color: Colors.purpleAccent,
                    icon: Icons.flash_on, 
                    isGradientBtn: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPlanCard({
    required BuildContext context,
    required String title,
    required String price,
    required String quality,
    required String ads,
    required String slot,
    required String limit,
    String? limitSub,
    required bool hasEarlyAccess,
    bool? hasAllPremium,
    required Color color,
    required IconData icon,
    String? badgeText,
    String? earlyAccessText,
    String? allPremiumText,
    bool isGradientBtn = false,
  }) {
    String cleanPrice = price.replaceAll("₹", "");

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.85, 
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 1,
              )
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(icon, color: color, size: 24), const SizedBox(width: 8), Text(title, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),],),Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(price, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)), const Text("/mo", style: TextStyle(color: Colors.white54, fontSize: 14)),],),],),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 20),
              _buildGridRow("Quality", quality),
              _buildGridRow("Ads", ads),
              _buildGridRow("Device Slot", slot),
              Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Expanded(child: Text("Daily Watching limit", style: TextStyle(color: Colors.white70, fontSize: 16))), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(limit, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), if (limitSub != null) Text(limitSub, style: const TextStyle(color: Colors.white54, fontSize: 12)),],)],)),
              const Spacer(),
              if (!hasEarlyAccess) Row(children: [const Icon(Icons.check_circle_outline, color: Colors.white38, size: 18), const SizedBox(width: 8), const Text("No Early Access", style: TextStyle(color: Colors.white38, fontSize: 14)),],) else ...[Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18), const SizedBox(width: 8), const Text("Early Access", style: TextStyle(color: Colors.white70, fontSize: 14)),],), if (earlyAccessText != null) Text(earlyAccessText, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),],), if (hasAllPremium != null) ...[const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18), const SizedBox(width: 8), const Text("All Premium Anime", style: TextStyle(color: Colors.white70, fontSize: 14)),],), if (allPremiumText != null) Text(allPremiumText, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),],)]],
              const SizedBox(height: 24),
              GestureDetector(onTap: () { userActivePlan = title; _launchUPI(context, cleanPrice, title.replaceAll(" ", "")); }, child: Container(height: 50, alignment: Alignment.center, decoration: BoxDecoration(color: isGradientBtn ? null : color, gradient: isGradientBtn ? const LinearGradient(colors: [Colors.purpleAccent, Colors.pinkAccent]) : null, borderRadius: BorderRadius.circular(12)), child: Text("Select Plan", style: TextStyle(color: (title == "Lite Plan" || title == "Plus Plan") ? Colors.black : Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),)
            ],
          ),
        ),
        if (badgeText != null) Positioned(top: -15, right: 20, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.star, color: Colors.black, size: 14), const SizedBox(width: 6), Text(badgeText, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),],)),),
      ],
    );
  }

  Widget _buildGridRow(String feature, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(feature, style: const TextStyle(color: Colors.white70, fontSize: 16)), Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),],),);
  }
}