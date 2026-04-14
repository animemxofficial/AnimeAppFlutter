import 'dart:io'; 
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; 
import 'dart:convert'; // For encoding/decoding JSON

// ==========================================
// DATA MODELS & GLOBAL STATE
// ==========================================

String currentUserName = "Guest User"; 
String currentUserEmail = "";
String userMobileNumber = ""; 
String userActivePlan = ""; 

List<String> globalRecentSearches = [];

// --- MISSING GLOBAL NOTIFIERS ---
final ValueNotifier<List<CWItem>> continueWatchingNotifier = ValueNotifier([]);
final ValueNotifier<List<SavedEpisode>> myListNotifier = ValueNotifier([]);
// ---------------------------------

// Helper function for Avatar Colors based on Email
final List<Color> avatarColors = [
  Colors.redAccent, Colors.blueAccent, Colors.green, Colors.purpleAccent,
  Colors.teal, Colors.orange, Colors.pinkAccent, Colors.indigo,
];

Color getAvatarColor(String inputString) {
  if (inputString.isEmpty) return Colors.grey;
  final int index = inputString.codeUnitAt(0) % avatarColors.length;
  return avatarColors[index];
}

String getAvatarLetter(String inputString) {
  if (inputString.isEmpty) return "?";
  return inputString[0].toUpperCase();
}

// ==========================================
// SUPABASE DATA PERSISTENCE SERVICES
// ==========================================

// --- Continue Watching Persistence Service ---
class CWService {
  final SupabaseClient supabase;
  CWService(this.supabase);

  Future<List<CWItem>> fetchCWList(String userEmail) async {
    try {
      final response = await supabase
          .from('user_preferences')
          .select('continue_watching')
          .eq('email', userEmail)
          .single();

      if (response != null && response['continue_watching'] != null) {
        final List<dynamic> cwData = response['continue_watching'];
        return cwData.map((data) => CWItem.fromJson(data)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching continue watching list: $e");
      return [];
    }
  }

  Future<void> saveCWList(String userEmail, List<CWItem> cwList) async {
    final savedData = cwList.map((item) => item.toJson()).toList();
    try {
      await supabase.from('user_preferences').upsert(
        {'id': supabase.auth.currentUser!.id, 'email': userEmail, 'continue_watching': savedData},
        onConflict: 'id',
      );
    } catch (e) {
      print("Error saving continue watching list: $e");
    }
  }
}

// --- Recent Searches Persistence Service ---
class RecentSearchesService {
  final SupabaseClient supabase;

  RecentSearchesService(this.supabase);

  Future<List<String>> fetchRecentSearches(String userEmail) async {
    try {
      final response = await supabase
          .from('user_preferences')
          .select('recent_searches')
          .eq('email', userEmail)
          .single();

      if (response != null && response['recent_searches'] != null) {
        var data = response['recent_searches'];
        if (data is String) {
          return List<String>.from(jsonDecode(data));
        } else if (data is List) {
          return List<String>.from(data);
        }
      }
      return [];
    } catch (e) {
      print("Error fetching recent searches: $e");
      return [];
    }
  }

  Future<void> saveRecentSearches(String userEmail, List<String> searches) async {
    final newSearches = [...searches];
    if (newSearches.length > 5) newSearches.removeLast(); // Keep list short
    final searchesJson = jsonEncode(newSearches);
    try {
      await supabase.from('user_preferences').upsert(
        {'id': supabase.auth.currentUser!.id, 'email': userEmail, 'recent_searches': searchesJson},
        onConflict: 'id',
      );
    } catch (e) {
      print("Error saving recent searches: $e");
    }
  }
}

// --- My List Persistence Service ---
class MyListService {
  final SupabaseClient supabase;

  MyListService(this.supabase);

  Future<List<SavedEpisode>> fetchMyList(String userEmail) async {
    try {
      final response = await supabase
          .from('user_preferences')
          .select('saved_anime')
          .eq('email', userEmail)
          .single();

      if (response != null && response['saved_anime'] != null) {
        final List<dynamic> savedData = response['saved_anime'];
        final List<SavedEpisode> fetchedList = [];
        for (var data in savedData) {
          final animeTitle = data['animeTitle'];
          try {
            final animeMatch = animeData.firstWhere((anime) => anime.title == animeTitle);
            fetchedList.add(SavedEpisode(
              anime: animeMatch,
              seasonIndex: data['seasonIndex'] ?? 0,
              episodeIndex: data['episodeIndex'] ?? 0,
            ));
          } catch (e) {
            print("Anime not found in dummy data: $animeTitle");
          }
        }
        return fetchedList;
      }
      return [];
    } catch (e) {
      print("Error fetching saved anime: $e");
      return [];
    }
  }

  Future<void> saveMyList(String userEmail, List<SavedEpisode> savedList) async {
    final List<Map<String, dynamic>> savedData = savedList.map((item) => item.toJson()).toList();
    try {
      await supabase.from('user_preferences').upsert(
        {'id': supabase.auth.currentUser!.id, 'email': userEmail, 'saved_anime': savedData},
        onConflict: 'id',
      );
    } catch (e) {
      print("Error saving saved anime list: $e");
    }
  }
}

// ==========================================
// DATA MODELS (Cont'd)
// ==========================================

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

  Map<String, dynamic> toJson() => {
    'animeTitle': anime.title,
    'seasonIndex': seasonIndex,
    'episodeIndex': episodeIndex,
    'positionInSeconds': position.inSeconds,
    'totalDurationInSeconds': totalDuration.inSeconds,
  };
  
  static CWItem fromJson(Map<String, dynamic> json) {
    // Check if anime exists in dummy data before creating CWItem
    try {
      final animeMatch = animeData.firstWhere((anime) => anime.title == json['animeTitle']);
      return CWItem(
        anime: animeMatch,
        seasonIndex: json['seasonIndex'],
        episodeIndex: json['episodeIndex'],
        position: Duration(seconds: json['positionInSeconds']),
        totalDuration: Duration(seconds: json['totalDurationInSeconds']),
      );
    } catch (e) {
      // Return a dummy CWItem or handle gracefully if anime not found
      return CWItem(
        anime: animeData[0], // Fallback to first anime
        seasonIndex: 0,
        episodeIndex: 0,
        position: Duration(seconds: json['positionInSeconds'] ?? 0),
        totalDuration: Duration(seconds: json['totalDurationInSeconds'] ?? 0),
      );
    }
  }
}

class SavedEpisode {
  final Anime anime;
  final int seasonIndex;
  final int episodeIndex;

  SavedEpisode({
    required this.anime,
    required this.seasonIndex,
    required this.episodeIndex,
  });

  Map<String, dynamic> toJson() => {
    'animeTitle': anime.title,
    'seasonIndex': seasonIndex,
    'episodeIndex': episodeIndex,
  };
}

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
    required this.videoUrl
  });
}

class Season {
  final String name;
  final List<Episode> episodes;

  Season({
    required this.name, 
    required this.episodes
  });
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
  final bool isNew; 

  Anime({
    required this.title, 
    required this.image, 
    this.genre = "Action", 
    this.rating = "PG-13", 
    this.dubStatus = "DUB", 
    this.season = "Season 1", 
    this.status = "Ongoing", 
    this.views = "1.1M", 
    this.dubColor = const Color(0xFFFF4D4D), 
    required this.seasonsList,
    this.isNew = false, 
  });
}

// DUMMY DATA FOR DEMO
List<Season> generateDummySeasons() {
  return [
    Season(
      name: "Season 1", 
      episodes:[
        Episode(
          title: "The Beginning", 
          image: "https://i.ibb.co/rW2Zk9B/images.jpg", 
          duration: "24m 10s", 
          views: "2.1M", 
          videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        ),
        Episode(
          title: "A New Threat", 
          image: "https://i.ibb.co/C3rhjGv3/images-1.jpg", 
          duration: "23m 45s", 
          views: "1.8M", 
          videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
        ),
      ]
    ),
  ];
}

List<Season> generateClassroomOfEliteSeasons() {
  return [
    Season(
      name: "Season 1", 
      episodes:[
        Episode(
          title: "Episode 1", 
          image: "https://i.ibb.co/vxJtwkcX/k.jpg", 
          duration: "24m 10s", 
          views: "3.8K", 
          videoUrl: "https://animemx-proxy.onrender.com/stream/AgADXx8AAg-FSFY"
        ), 
        Episode(
          title: "Episode 2", 
          image: "https://i.ibb.co/vxJtwkcX/k.jpg", 
          duration: "23m 45s", 
          views: "1.8M", 
          videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
        ),
      ]
    ),
  ];
}

final List<Anime> animeData = [
  Anime(title: "Solo Leveling", genre: "Action", image: "https://i.ibb.co/C3rhjGv3/images-1.jpg", views: "38K", dubStatus: "DUB", dubColor: const Color(0xFFFF4D4D), season: "S1", seasonsList: generateDummySeasons(), isNew: true),
  Anime(title: "Classroom of the Elite", genre: "Thriller", image: "https://i.ibb.co/vxJtwkcX/k.jpg", status: "Completed", views: "3K", dubStatus: "MIX", dubColor: const Color(0xFF4DA6FF), season: "S3", seasonsList: generateClassroomOfEliteSeasons()),
  Anime(title: "One Piece", genre: "Adventure", image: "https://i.ibb.co/jvVk3XSY/g.jpg", views: "8.1K", dubStatus: "DUB", dubColor: const Color(0xFF4DA6FF), season: "S1", seasonsList: generateDummySeasons()),
  Anime(title: "Naruto", genre: "Action", image: "https://i.ibb.co/YFg2hKvf/j.jpg", views: "4.5K", dubStatus: "ORIGINAL", dubColor: const Color(0xFFFF9F43), season: "S1", seasonsList: generateDummySeasons()),
  Anime(title: "Demon Slayer", genre: "Action", image: "https://i.ibb.co/yFRNxJbG/o.jpg", views: "3.1K", dubStatus: "MIX", dubColor: const Color(0xFF00C853), season: "S2", seasonsList: generateDummySeasons()),
  Anime(title: "Death Note", genre: "Mystery", image: "https://i.ibb.co/L0x9WvY/the-eminence-in-shadow.jpg", views: "9M", dubStatus: "DUB", dubColor: const Color(0xFF7A5CFF), season: "S1", seasonsList: generateDummySeasons()),
  Anime(title: "Your Name", genre: "Romance", image: "https://i.ibb.co/rW2Zk9B/images.jpg", views: "2M", dubStatus: "MIX", dubColor: const Color(0xFFFF4D4D), season: "Movie", seasonsList: generateDummySeasons()),
  Anime(title: "Bleach: Thousand-Year Blood War", genre: "Action", image: "https://i.ibb.co/DDDJNsFX/images-3.jpg", status: "Coming Soon", views: "0", dubStatus: "ORIGINAL", dubColor: Colors.grey, season: "S3", seasonsList: []),
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
    required this.date
  });
}

// Global list for initial data (updated by payment submission)
// ActivityPage now fetches from Supabase on load, but we keep this for local updates.
List<OrderItem> userOrders = []; 

// ==========================================
// MAIN ENTRY POINT
// ==========================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Supabase Initialization ---
  await Supabase.initialize(
    url: 'https://yngzfgfpyufusrbitagl.supabase.co',          
    anonKey: 'sb_publishable_6BD0moEpOnUTfihbRUpdOQ_U2gJCH5U', 
  );

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
// UTILITY FUNCTIONS for Links and Contacts
// ==========================================
Future<void> launchInBrowser(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $uri');
  }
}

Future<void> launchWhatsApp(String number) async {
  final Uri uri = Uri.parse("whatsapp://send?phone=$number");
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    // Fallback to web link
    final webUri = Uri.parse("https://api.whatsapp.com/send?phone=$number");
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      print("WhatsApp not installed");
    }
  }
}

Future<void> launchTelegram(String username) async {
  final Uri uri = Uri.parse("tg://resolve?domain=$username");
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    // Fallback to web link
    final webUri = Uri.parse("https://t.me/$username");
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      print("Telegram not installed");
    }
  }
}

// ==========================================
// ROOT APP
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
      home: const AuthGate(), 
    );
  }
}

// ==========================================
// AUTH GATE (SUPABASE)
// ==========================================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.orange)),
          );
        }
        final session = snapshot.data?.session;
        if (session != null) {
          currentUserEmail = session.user.email ?? "User";
          // Generate userName from email prefix as requested (Task 1 fix)
          currentUserName = currentUserEmail.split('@')[0]; 
          return const MainScreen();
        }
        // User is not logged in
        return const LoginScreen();
      },
    );
  }
}

// ==========================================
// LOGIN SCREEN (REAL EMAIL/PASSWORD) - UPDATED UI/UX
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true; // State to toggle between Login and Signup

  // Supabase Login Function
  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter email and password")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Supabase Sign Up Function (Removed first name/last name)
  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter email and password")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sign Up Successful! Please Log In.")));
      setState(() => _isLoginMode = true); // Switch back to login after signup
    } on AuthException catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light color background as requested
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_fill, color: Colors.orange, size: 80),
              const SizedBox(height: 10),
              const Text(
                "AnimeMX", 
                style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold) // Black text for light background
              ),
              const SizedBox(height: 40),
              
              // Email Field (light UI)
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration(context, "Email", Icons.email),
              ),
              const SizedBox(height: 16),
              
              // Password Field (light UI)
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration(context, "Password", Icons.lock),
              ),
              const SizedBox(height: 30),
              
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.orange)
              else
                Column(
                  children: [
                    // Primary Action Button (Login or Signup based on mode)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isLoginMode ? _signIn : _signUp,
                        child: Text(_isLoginMode ? "Log In" : "Sign Up", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Toggle Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                        });
                      },
                      child: Text(
                        _isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Log In",
                        style: const TextStyle(color: Colors.orange, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  InputDecoration _inputDecoration(BuildContext context, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      prefixIcon: Icon(icon, color: Colors.orange),
      filled: true,
      fillColor: const Color(0xFFE0E0E0), // Soft light background color
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
    );
  }
}

// ==========================================
// MAIN SCREEN NAVIGATION
// ==========================================
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
    final List<Widget> pages = [
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
        items: const [
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
                  // DYNAMIC AVATAR LOGO (First Letter of User Name)
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: getAvatarColor(currentUserName),
                    child: Text(
                      getAvatarLetter(currentUserName),
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUserName.isNotEmpty ? currentUserName : "Welcome!", 
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUserEmail, 
                          style: const TextStyle(color: Colors.white70, fontSize: 12), 
                          overflow: TextOverflow.ellipsis
                        ),
                        if (userActivePlan.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2), 
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(
                              userActivePlan.toUpperCase(), 
                              style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)
                            ),
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
              onTap: () => Navigator.pop(context)
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber), 
              title: const Text("Go Premium", style: TextStyle(color: Colors.amber)), 
              onTap: () { 
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())); 
              }
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.white70), 
              title: const Text("Website", style: TextStyle(color: Colors.white)), 
              onTap: () => Navigator.pop(context)
            ),
            ListTile(
              leading: const Icon(Icons.headset_mic, color: Colors.white70), 
              title: const Text("Support", style: TextStyle(color: Colors.white)), 
              onTap: () { 
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportPage())); 
              }
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white70), 
              title: const Text("Privacy Policy", style: TextStyle(color: Colors.white)), 
              onTap: () { 
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage())); 
              }
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white70), 
              title: const Text("About Us", style: TextStyle(color: Colors.white)), 
              onTap: () { 
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutUsPage())); 
              }
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0), 
              child: Divider(color: Colors.white12, thickness: 1)
            ),
            // REAL LOGOUT ACTION
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20), 
              title: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)), 
              onTap: () async { 
                Navigator.pop(context); // Close Drawer
                await Supabase.instance.client.auth.signOut(); // REAL LOGOUT
              }
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
              onPressed: () => Scaffold.of(context).openDrawer()
            ); 
          }
        ),
        title: const Text(
          "AnimeMX", 
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)
        ),
        actions:[
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white), 
            onPressed: onSearchTap
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
                viewportFraction: 1.0
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
                        fit: BoxFit.cover
                      ), 
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.95), Colors.transparent], 
                            begin: Alignment.bottomCenter, 
                            end: Alignment.topCenter, 
                            stops: const [0.0, 0.6]
                          )
                        )
                      ), 
                      Positioned(
                        top: 15, 
                        right: 15, 
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                          decoration: BoxDecoration(
                            color: Colors.black54, 
                            borderRadius: BorderRadius.circular(12)
                          ), 
                          child: Text(
                            "${i + 1}/${sliderItems.length}", 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                          )
                        )
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
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1), 
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis
                              )
                            ), 
                            const SizedBox(height: 8), 
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                              decoration: BoxDecoration(
                                color: tagColor, 
                                borderRadius: BorderRadius.circular(4)
                              ), 
                              child: Text(
                                tag, 
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                              )
                            )
                          ]
                        )
                      )
                    ]
                  )
                );
              },
            ),
            const SizedBox(height: 20),

            ValueListenableBuilder<List<CWItem>>(
              valueListenable: continueWatchingNotifier, 
              builder: (context, cwList, child) { 
                if (cwList.isEmpty) return const SizedBox.shrink(); 
                return _buildThumbnailSection(context, "Continue Watching", Icons.history, Colors.orange, true, cwList: cwList); 
              }
            ),
            
            _buildPortraitSection(context, "Trending Now", Icons.local_fire_department_rounded, Colors.orange, animeData),
            _buildPopularSection(context, "Popular Anime", Icons.emoji_events, Colors.amber, animeData.reversed.toList()),
            _buildThumbnailSection(context, "Latest Episodes", null, null, false, animeList: animeData.where((a) => a.seasonsList.isNotEmpty).toList()),
            _buildPortraitSection(context, "Thriller", null, null, animeData.reversed.toList()),
            _buildPortraitSection(context, "Action", null, null, animeData),
          ],
        ),
      ),
    );
  }

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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)
                  ), 
                  if (icon != null) ...[
                    const SizedBox(width: 6), 
                    Icon(icon, color: iconColor, size: 20)
                  ]
                ]
              ), 
              GestureDetector(
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => SeeAllCategoryPage(title: title, animeList: list))
                ), 
                child: const Text(
                  "See All", 
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)
                )
              )
            ]
          ),
        ),
        SizedBox(
          height: 210, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal, 
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), 
            itemCount: list.length, 
            itemBuilder: (context, index) { 
              return GestureDetector(
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => DetailsPage(anime: list[index]))
                ), 
                child: Container(
                  width: 120, 
                  margin: const EdgeInsets.only(right: 12), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children:[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12), 
                          child: Image.network(list[index].image, fit: BoxFit.cover, width: double.infinity)
                        )
                      ), 
                      const SizedBox(height: 8), 
                      Text(
                        list[index].title, 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis
                      ), 
                      Text(
                        list[index].genre, 
                        style: const TextStyle(color: Colors.grey, fontSize: 11), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis
                      )
                    ]
                  )
                )
              ); 
            }
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)
                  ), 
                  const SizedBox(width: 6), 
                  Icon(icon, color: iconColor, size: 20)
                ]
              ), 
              GestureDetector(
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => SeeAllCategoryPage(title: title, animeList: list))
                ), 
                child: const Text(
                  "See All", 
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)
                )
              )
            ]
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
            }
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)
                  ), 
                  if (icon != null) ...[
                    const SizedBox(width: 6), 
                    Icon(icon, color: iconColor, size: 20)
                  ]
                ]
              ), 
              GestureDetector(
                onTap: () { 
                  List<Anime> listToPass = isCW ? cwList!.map((cw) => cw.anime).toList() : animeList!; 
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => SeeAllCategoryPage(title: title, animeList: listToPass))
                  ); 
                }, 
                child: const Text(
                  "See All", 
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)
                )
              )
            ]
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
            }
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ==========================================
// CATEGORY PAGES & CARDS
// ==========================================
class SeeAllCategoryPage extends StatelessWidget {
  final String title; 
  final List<Anime> animeList; 
  
  const SeeAllCategoryPage({
    super.key, 
    required this.title, 
    required this.animeList
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.black, 
        elevation: 0, 
        title: Text(
          title, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)
        ), 
        iconTheme: const IconThemeData(color: Colors.white)
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
        itemBuilder: (context, index) => GridCategoryCard(anime: animeList[index], pageTitle: title)
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
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => DetailsPage(anime: anime))
      ), 
      child: Container(
        width: 140, 
        margin: const EdgeInsets.only(right: 12), 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: Colors.white, width: 1.5)
        ), 
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10), 
          child: Stack(
            children:[
              Image.network(
                anime.image, 
                fit: BoxFit.cover, 
                width: double.infinity, 
                height: double.infinity
              ), 
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:[Colors.black.withOpacity(0.9), Colors.transparent], 
                      begin: Alignment.bottomCenter, 
                      end: Alignment.center
                    )
                  )
                )
              ), 
              Positioned(
                top: 8, 
                right: 8, 
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), 
                  decoration: BoxDecoration(
                    color: Colors.cyan, 
                    borderRadius: BorderRadius.circular(4)
                  ), 
                  child: const Text(
                    "POPULAR", 
                    style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)
                  )
                )
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
                      overflow: TextOverflow.ellipsis
                    ), 
                    const SizedBox(height: 4), 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children:[
                        Text(
                          "${anime.season} | Ep 3", 
                          style: const TextStyle(color: Colors.white70, fontSize: 10)
                        ), 
                        Row(
                          children:[
                            const Icon(Icons.visibility, color: Colors.white70, size: 12), 
                            const SizedBox(width: 4), 
                            Text(
                              anime.views, 
                              style: const TextStyle(color: Colors.white70, fontSize: 10)
                            )
                          ]
                        )
                      ]
                    )
                  ]
                )
              )
            ]
          )
        ),
      ),
    );
  }
}

class GridCategoryCard extends StatefulWidget {
  final Anime anime; 
  final String pageTitle; 
  
  const GridCategoryCard({super.key, required this.anime, required this.pageTitle});

  @override
  State<GridCategoryCard> createState() => _GridCategoryCardState();
}

class _GridCategoryCardState extends State<GridCategoryCard> {
  // Save/Unsave logic function (local update, save to Supabase will be implemented in future steps)
  void _toggleSaveAnime() {
    final list = List<SavedEpisode>.from(myListNotifier.value);
    final isSaved = list.any((item) => item.anime.title == widget.anime.title);

    if (isSaved) {
      list.removeWhere((item) => item.anime.title == widget.anime.title);
    } else {
      list.add(SavedEpisode(anime: widget.anime, seasonIndex: 0, episodeIndex: 0));
    }
    myListNotifier.value = list;
    // Notify the UI to rebuild (handled by ValueListenableBuilder in MyListScreen)
    // Save to Supabase (Task 10)
    _saveMyListToSupabase();
  }

  Future<void> _saveMyListToSupabase() async {
    final savedData = myListNotifier.value.map((item) => item.toJson()).toList();
    try {
      await Supabase.instance.client.from('user_preferences').upsert(
        {'id': Supabase.instance.client.auth.currentUser!.id, 'email': currentUserEmail, 'saved_anime': savedData},
        onConflict: 'id',
      );
    } catch (e) {
      print("Error saving saved anime list: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String? tagText; 
    Color? tagBgColor; 
    Color tagTextColor = Colors.black;
    
    // Logic for tags based on section (Task 8 & 9)
    if (widget.pageTitle == "Trending Now") { 
      tagText = "TRENDING"; 
      tagBgColor = Colors.orange; 
      tagTextColor = Colors.white; 
    } else if (widget.pageTitle == "Popular Anime") { 
      tagText = "POPULAR"; 
      tagBgColor = Colors.cyan; 
      tagTextColor = Colors.black; 
    } else if (widget.pageTitle == "DUB" || widget.pageTitle == "ORIGINAL") { 
      tagText = widget.anime.dubStatus == "DUB" ? "AMX DUB" : (widget.anime.dubStatus == "ORIGINAL" ? "ORIGINAL" : "MIX O/D");
      tagBgColor = widget.anime.dubColor;
      tagTextColor = Colors.white;
    }
    
    // New tag for "Latest Episodes" see all page (Task 8)
    if (widget.pageTitle == "Latest Episodes" && widget.anime.isNew) {
      tagText = "NEW";
      tagBgColor = Colors.green;
      tagTextColor = Colors.white;
    }

    // MyList save icon logic (Task 10)
    final bool isSaved = myListNotifier.value.any((item) => item.anime.title == widget.anime.title);
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => DetailsPage(anime: widget.anime))
      ), 
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: Colors.white, width: 1.5)
        ), 
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10), 
          child: Stack(
            children:[
              Image.network(
                widget.anime.image, 
                fit: BoxFit.cover, 
                width: double.infinity, 
                height: double.infinity
              ), 
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:[Colors.black.withOpacity(0.9), Colors.transparent], 
                      begin: Alignment.bottomCenter, 
                      end: Alignment.center
                    )
                  )
                )
              ), 
              if (tagText != null) 
                Positioned(
                  top: 8, 
                  right: 8, 
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), 
                    decoration: BoxDecoration(
                      color: tagBgColor, 
                      borderRadius: BorderRadius.circular(4)
                    ), 
                    child: Text(
                      tagText, 
                      style: TextStyle(color: tagTextColor, fontSize: 10, fontWeight: FontWeight.bold)
                    )
                  )
                ), 
              Positioned(
                bottom: 10, 
                left: 10, 
                right: 10, 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children:[
                    Text(
                      widget.anime.title, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14), 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis
                    ), 
                    const SizedBox(height: 4), 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children:[
                        Text(
                          "${widget.anime.season} | Ep 3", 
                          style: const TextStyle(color: Colors.white70, fontSize: 10)
                        ), 
                        Row(
                          children:[
                            const Icon(Icons.visibility, color: Colors.white70, size: 12), 
                            const SizedBox(width: 4), 
                            Text(
                              widget.anime.views, 
                              style: const TextStyle(color: Colors.white70, fontSize: 10)
                            )
                          ]
                        )
                      ]
                    )
                  ]
                )
              ),
              // My List Save Icon Position (Task 10)
              Positioned(
                top: 8, // Changed position to top left
                left: 8, // Changed position to top left
                child: GestureDetector(
                  onTap: () async {
                    _toggleSaveAnime(); // Call save logic
                  },
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
              )
            ]
          )
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
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => DetailsPage(anime: anime))
      ), 
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
                        decoration: BoxDecoration(
                          color: Colors.black54, 
                          borderRadius: BorderRadius.circular(4)
                        ), 
                        child: Row(
                          children:[
                            const Icon(Icons.visibility, color: Colors.orange, size: 12), 
                            const SizedBox(width: 4), 
                            Text(
                              anime.views, 
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                            )
                          ]
                        )
                      )
                    ), 
                    Positioned(
                      bottom: 6, 
                      right: 6, 
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                        decoration: BoxDecoration(
                          color: Colors.black87, 
                          borderRadius: BorderRadius.circular(4)
                        ), 
                        child: const Text(
                          "Ep 12", 
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                        )
                      )
                    )
                  ]
                )
              )
            ), 
            const SizedBox(height: 8), 
            Text(
              anime.title, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis
            ), 
            const SizedBox(height: 2), 
            Text(
              "Latest Episode", 
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)
            )
          ]
        )
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
      onTapDown: (_) => setState(() => _isTapped = true), 
      onTapUp: (_) { 
        setState(() => _isTapped = false); 
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (_) => VideoPlayerPage(
              anime: widget.item.anime, 
              seasonIndex: widget.item.seasonIndex, 
              episodeIndex: widget.item.episodeIndex, 
              startPosition: widget.item.position
            )
          )
        ); 
      }, 
      onTapCancel: () => setState(() => _isTapped = false), 
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
                      fit: BoxFit.cover
                    ), 
                    Container(color: Colors.black38), 
                    const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40)
                    ), 
                    Positioned(
                      bottom: 0, 
                      left: 0, 
                      right: 0, 
                      child: LinearProgressIndicator(
                        value: progress, 
                        backgroundColor: Colors.white24, 
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange), 
                        minHeight: 4
                      )
                    )
                  ]
                )
              )
            ), 
            const SizedBox(height: 8), 
            Text(
              widget.item.anime.title, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis
            ), 
            Text(
              "Episode ${widget.item.episodeIndex + 1}", 
              style: const TextStyle(color: Colors.grey, fontSize: 11)
            )
          ]
        )
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
        appBar: AppBar(
          backgroundColor: Colors.black, 
          title: Text(widget.anime.title)
        ), 
        body: const Center(
          child: Text(
            "Episodes Coming Soon!", 
            style: TextStyle(color: Colors.white)
          )
        )
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
              onPressed: () => Navigator.pop(context)
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand, 
                children:[
                  Image.network(
                    widget.anime.image, 
                    fit: BoxFit.cover, 
                    alignment: Alignment.topCenter
                  ), 
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:[darkBg, darkBg.withOpacity(0.5), Colors.transparent], 
                        stops: const [0.0, 0.4, 1.0], 
                        begin: Alignment.bottomCenter, 
                        end: Alignment.topCenter
                      )
                    )
                  )
                ]
              )
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
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)
                  ), 
                  const SizedBox(height: 10),
                  Row(
                    children:[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                        decoration: BoxDecoration(
                          color: Colors.white24, 
                          borderRadius: BorderRadius.circular(12)
                        ), 
                        child: Text(
                          widget.anime.rating, 
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                        )
                      ), 
                      const SizedBox(width: 10), 
                      const Expanded(
                        child: Text(
                          "• Dub | Action, Thriller, Drama", 
                          style: TextStyle(color: Colors.white70, fontSize: 13), 
                          overflow: TextOverflow.ellipsis
                        )
                      )
                    ]
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, 
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor, 
                        padding: const EdgeInsets.symmetric(vertical: 14), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                        elevation: 5
                      ), 
                      onPressed: () { 
                        if (episodesList.isNotEmpty) {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => VideoPlayerPage(anime: widget.anime, seasonIndex: _selectedSeasonIndex, episodeIndex: 0))
                          );
                        }
                      }, 
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28), 
                      label: const Text(
                        "Play Season 1", 
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                      )
                    )
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Kiyotaka Ayanokouji enters the prestigious Tokyo Metropolitan Advanced Nurturing High School, which is dedicated to fostering the best and brightest students. But he ends up in Class-D, a dumping ground for the school's worst. A cruel meritocracy awaits where he must use his dark intellect to survive in a school of ruthless competition and psychological warfare.", 
                    maxLines: _isExpanded ? null : 2, 
                    overflow: _isExpanded ? null : TextOverflow.ellipsis, 
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded), 
                    child: Text(
                      _isExpanded ? "Read Less" : "Read More", 
                      style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)
                    )
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Seasons", 
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40, 
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal, 
                      itemCount: widget.anime.seasonsList.length, 
                      itemBuilder: (context, index) { 
                        return Padding(
                          padding: const EdgeInsets.only(right: 10), 
                          child: _buildSeasonTab(index, widget.anime.seasonsList[index].name, primaryColor)
                        ); 
                      }
                    )
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Episodes", 
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
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
                          final cwIndex = cwList.indexWhere((item) => item.anime.title == widget.anime.title && item.seasonIndex == _selectedSeasonIndex && item.episodeIndex == index); 
                          if (cwIndex != -1) { 
                            if (cwList[cwIndex].totalDuration.inMilliseconds > 0) {
                              progress = cwList[cwIndex].position.inMilliseconds / cwList[cwIndex].totalDuration.inMilliseconds; 
                            }
                          } 
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerPage(anime: widget.anime, seasonIndex: _selectedSeasonIndex, episodeIndex: index, startPosition: cwIndex != -1 ? cwList[cwIndex].position : null)
                              )
                            ), 
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12), 
                              padding: const EdgeInsets.all(10), 
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A), 
                                borderRadius: BorderRadius.circular(12)
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
                                          Image.network(ep.image, fit: BoxFit.cover), 
                                          if (progress > 0.0) 
                                            Positioned(
                                              bottom: 0, 
                                              left: 0, 
                                              right: 0, 
                                              child: LinearProgressIndicator(
                                                value: progress, 
                                                backgroundColor: Colors.black54, 
                                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange), 
                                                minHeight: 4
                                              )
                                            )
                                        ]
                                      )
                                    )
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
                                          overflow: TextOverflow.ellipsis
                                        ), 
                                        const SizedBox(height: 6), 
                                        Row(
                                          children:[
                                            Text(
                                              ep.duration, 
                                              style: const TextStyle(color: Colors.white54, fontSize: 12)
                                            ), 
                                            const SizedBox(width: 10), 
                                            const Icon(Icons.visibility, color: Colors.white54, size: 12), 
                                            const SizedBox(width: 4), 
                                            Text(
                                              ep.views, 
                                              style: const TextStyle(color: Colors.white54, fontSize: 12)
                                            )
                                          ]
                                        )
                                      ]
                                    )
                                  ), 
                                  Container(
                                    padding: const EdgeInsets.all(8), 
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle, 
                                      color: Colors.white.withOpacity(0.1)
                                    ), 
                                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24)
                                  )
                                ]
                              )
                            )
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
      onTap: () => setState(() => _selectedSeasonIndex = index), 
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
        decoration: BoxDecoration(
          color: isActive ? primaryColor : const Color(0xFF1A1A1A), 
          borderRadius: BorderRadius.circular(8)
        ), 
        child: Center(
          child: Text(
            title, 
            style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)
          )
        )
      )
    ); 
  }
}

// ==========================================
// FAST LOAD VIDEO PLAYER PAGE - UPDATED LIKES/DISLIKES
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
    this.startPosition
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
  
  // Local state for like/dislike status (now also linked to Supabase)
  bool _isLiked = false; 
  bool _isDisliked = false;
  // Local state for counts (updated from Supabase)
  int _likesCount = 0;
  int _dislikesCount = 0;

  @override 
  void initState() { 
    super.initState(); 
    _fetchLikesDislikes(); // Fetch current counts from Supabase
    final ep = widget.anime.seasonsList[widget.seasonIndex].episodes[widget.episodeIndex]; 
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(ep.videoUrl), 
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true)
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

  // --- Supabase Likes/Dislikes Logic ---
  // Fetch initial likes/dislikes from Supabase
  Future<void> _fetchLikesDislikes() async {
    final episodeId = "${widget.anime.title}_${widget.seasonIndex}_${widget.episodeIndex}";
    try {
      final response = await Supabase.instance.client
          .from('content_likes') // Create a table named 'content_likes' in Supabase
          .select('likes, dislikes')
          .eq('episode_id', episodeId)
          .single();
      
      if (mounted && response != null) {
        setState(() {
          _likesCount = response['likes'] ?? 0;
          _dislikesCount = response['dislikes'] ?? 0;
        });
      }
      
      // Check if current user has liked/disliked
      final userResponse = await Supabase.instance.client
          .from('user_likes') // Create a table named 'user_likes' in Supabase
          .select('is_liked')
          .eq('episode_id', episodeId)
          .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
          .single();

      if (mounted && userResponse != null) {
        setState(() {
          _isLiked = userResponse['is_liked'] ?? false;
          _isDisliked = userResponse['is_disliked'] ?? false; // Fixed issue where dislike status wasn't fetched correctly.
        });
      }

    } catch (e) {
      print("Error fetching likes/dislikes: $e");
    }
  }

  // Update likes/dislikes in Supabase when button is pressed
  Future<void> _updateLikesDislikes(bool newLikeStatus, bool newDislikeStatus) async {
    final episodeId = "${widget.anime.title}_${widget.seasonIndex}_${widget.episodeIndex}";
    final userId = Supabase.instance.client.auth.currentUser!.id;

    // 1. Update user_likes table for current user (to save state)
    await Supabase.instance.client.from('user_likes').upsert({
      'user_id': userId,
      'episode_id': episodeId,
      'is_liked': newLikeStatus,
      'is_disliked': newDislikeStatus,
    }, onConflict: 'user_id, episode_id');

    // 2. Update content_likes table (increment/decrement counts)
    try {
        // Fetch current counts again (to avoid conflicts with other users liking/disliking)
        final currentCounts = await Supabase.instance.client
            .from('content_likes')
            .select('likes, dislikes')
            .eq('episode_id', episodeId)
            .single();
        
        int currentLikes = currentCounts?['likes'] ?? 0;
        int currentDislikes = currentCounts?['dislikes'] ?? 0;
        
        // Calculate new counts based on new state
        int newLikes = currentLikes;
        int newDislikes = currentDislikes;

        if (newLikeStatus && !_isLiked) { // Liked (and wasn't liked before)
            newLikes++;
            if (_isDisliked) newDislikes--; // If previously disliked, remove dislike count
        } else if (!newLikeStatus && _isLiked) { // Unliked (was liked before)
            newLikes--;
        }

        if (newDislikeStatus && !_isDisliked) { // Disliked (and wasn't disliked before)
            newDislikes++;
            if (_isLiked) newLikes--; // If previously liked, remove like count
        } else if (!newDislikeStatus && _isDisliked) { // Undisliked (was disliked before)
            newDislikes--;
        }
        
        // Ensure counts are non-negative
        newLikes = max(0, newLikes);
        newDislikes = max(0, newDislikes);

        // Update counts in database
        await Supabase.instance.client.from('content_likes').upsert({
            'episode_id': episodeId,
            'likes': newLikes,
            'dislikes': newDislikes,
        }, onConflict: 'episode_id');
        
        if (mounted) {
            setState(() {
                _likesCount = newLikes;
                _dislikesCount = newDislikes;
            });
        }

    } catch (e) {
        print("Error updating content counts: $e");
    }
  }

  void _updateContinueWatching() { 
    if (!_controller.value.isInitialized) return; 
    final pos = _controller.value.position; 
    final dur = _controller.value.duration; 
    if (pos > const Duration(seconds: 2)) { 
      final list = List<CWItem>.from(continueWatchingNotifier.value); 
      final existingIdx = list.indexWhere((item) => item.anime.title == widget.anime.title && item.seasonIndex == widget.seasonIndex && item.episodeIndex == widget.episodeIndex); 
      if (existingIdx != -1) { 
        list[existingIdx].position = pos; 
        list[existingIdx].totalDuration = dur; 
        final item = list.removeAt(existingIdx); 
        list.insert(0, item); 
      } else { 
        list.insert(0, CWItem(anime: widget.anime, seasonIndex: widget.seasonIndex, episodeIndex: widget.episodeIndex, position: pos, totalDuration: dur)); 
      } 
      continueWatchingNotifier.value = list; 
      // Save Continue Watching list to Supabase (Task 1)
      _saveContinueWatchingToSupabase(list);
    } 
  }
  
  Future<void> _saveContinueWatchingToSupabase(List<CWItem> cwList) async {
    final savedData = cwList.map((item) => item.toJson()).toList();
    try {
      await Supabase.instance.client.from('user_preferences').upsert(
        {'id': Supabase.instance.client.auth.currentUser!.id, 'email': currentUserEmail, 'continue_watching': savedData},
        onConflict: 'id',
      );
    } catch (e) {
      print("Error saving continue watching list: $e");
    }
  }

  void _toggleControls() { 
    setState(() => _showControls = !_showControls); 
  }

  void _toggleFullScreen() { 
    setState(() => _isFullScreen = !_isFullScreen); 
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

  // --- Like/Dislike Button Handlers ---
  void _toggleLike() { 
    final newLikeStatus = !_isLiked;
    final newDislikeStatus = false;
    _updateLikesDislikes(newLikeStatus, newDislikeStatus);
    setState(() { // Local UI update immediately
      _isLiked = newLikeStatus;
      _isDisliked = false;
    });
  }

  void _toggleDislike() { 
    final newLikeStatus = false;
    final newDislikeStatus = !_isDisliked;
    _updateLikesDislikes(newLikeStatus, newDislikeStatus);
    setState(() { // Local UI update immediately
      _isDisliked = newDislikeStatus;
      _isLiked = false;
    });
  }

  // --- My List Save Button Logic ---
  bool get _isSaved { 
    return myListNotifier.value.any((item) => item.anime.title == widget.anime.title && item.seasonIndex == widget.seasonIndex && item.episodeIndex == widget.episodeIndex); 
  }

  void _toggleSave() { 
    final list = List<SavedEpisode>.from(myListNotifier.value); 
    if (_isSaved) { 
      list.removeWhere((item) => item.anime.title == widget.anime.title && item.seasonIndex == widget.seasonIndex && item.episodeIndex == widget.episodeIndex); 
    } else { 
      list.add(SavedEpisode(anime: widget.anime, seasonIndex: widget.seasonIndex, episodeIndex: widget.episodeIndex)); 
    } 
    myListNotifier.value = list; 
    MyListService(Supabase.instance.client).saveMyList(currentUserEmail, list); // Save to Supabase
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
                  child: VideoPlayer(_controller)
                )
              ) 
            : const Center(
                child: CircularProgressIndicator(color: primaryColor)
              ),
        
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
                    Text("-10s", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
                  ]
                )
              )
            )
          )
        ),
        
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
                    Text("+10s", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
                  ]
                )
              )
            )
          )
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
                        }
                      ), 
                      Row(
                        children:[
                          IconButton(
                            icon: const Icon(Icons.cast, color: Colors.white), 
                            onPressed: () {
                              // Task: Connect TV functionality (Complex implementation required here)
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connecting to TV feature coming soon!")));
                            }
                          ), 
                          IconButton(
                            icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white), 
                            onPressed: _toggleFullScreen
                          )
                        ]
                      )
                    ]
                  ), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                    children:[
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white, size: 40), 
                        onPressed: _skipBackward
                      ), 
                      IconButton(
                        icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 60), 
                        onPressed: () { 
                          setState(() { 
                            _controller.value.isPlaying ? _controller.pause() : _controller.play(); 
                          }); 
                          _updateContinueWatching(); 
                        }
                      ), 
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white, size: 40), 
                        onPressed: _skipForward
                      )
                    ]
                  ), 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), 
                    child: Row(
                      children:[
                        ValueListenableBuilder(
                          valueListenable: _controller, 
                          builder: (context, VideoPlayerValue value, child) { 
                            return Text(_formatDuration(value.position), style: const TextStyle(color: Colors.white, fontSize: 12)); 
                          }
                        ), 
                        Expanded(
                          child: ValueListenableBuilder(
                            valueListenable: _controller, 
                            builder: (context, VideoPlayerValue value, child) { 
                              return SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3.0, 
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0), 
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0)
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
                                  }
                                )
                              ); 
                            }
                          )
                        ), 
                        ValueListenableBuilder(
                          valueListenable: _controller, 
                          builder: (context, VideoPlayerValue value, child) { 
                            return Text(_formatDuration(value.duration), style: const TextStyle(color: Colors.white, fontSize: 12)); 
                          }
                        )
                      ]
                    )
                  )
                ]
              )
            ),
          ) 
        else 
          GestureDetector(
            onTap: _toggleControls, 
            child: Container(color: Colors.transparent)
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
              child: _isFullScreen ? videoContent : AspectRatio(aspectRatio: 16 / 9, child: videoContent)
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
                        style: const TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold)
                      ), 
                      const SizedBox(height: 4), 
                      Text(
                        widget.anime.title, 
                        style: const TextStyle(color: Colors.white70, fontSize: 12)
                      ), 
                      const SizedBox(height: 4), 
                      Text(
                        currentEpisode.title, 
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
                      ), 
                      const SizedBox(height: 20),
                      
                      // SLEEK ACTION BAR (LIKE, DISLIKE, SAVE)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), 
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05), 
                          borderRadius: BorderRadius.circular(16)
                        ), 
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround, 
                          children:[
                            GestureDetector(
                              onTap: _toggleLike, 
                              child: AnimatedContainer( // Magic effect for like button
                                duration: const Duration(milliseconds: 150),
                                transform: Matrix4.identity()..scale(_isLiked ? 1.1 : 1.0),
                                child: Row(
                                  children:[
                                    Icon(_isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, color: _isLiked ? Colors.orange : Colors.white, size: 22), 
                                    const SizedBox(width: 8), 
                                    Text(_likesCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))
                                  ]
                                )
                              )
                            ), 
                            Container(width: 1, height: 24, color: Colors.white24), 
                            GestureDetector(
                              onTap: _toggleDislike, 
                              child: AnimatedContainer( // Magic effect for dislike button
                                duration: const Duration(milliseconds: 150),
                                transform: Matrix4.identity()..scale(_isDisliked ? 1.1 : 1.0),
                                child: Row(
                                  children:[
                                    Icon(_isDisliked ? Icons.thumb_down : Icons.thumb_down_alt_outlined, color: _isDisliked ? Colors.orange : Colors.white, size: 22), 
                                    const SizedBox(width: 8), 
                                    Text(_dislikesCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))
                                  ]
                                )
                              )
                            ), 
                            Container(width: 1, height: 24, color: Colors.white24), 
                            GestureDetector(
                              onTap: _toggleSave, 
                              child: Row(
                                children:[
                                  Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: _isSaved ? Colors.orange : Colors.white, size: 22), 
                                  const SizedBox(width: 8), 
                                  Text(_isSaved ? "Saved" : "Save", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))
                                ]
                              )
                            )
                          ]
                        )
                      ),
                      const SizedBox(height: 30),
                      
                      if (hasNextEpisode) ...[
                        const Text(
                          "Up Next", 
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                        ), 
                        const SizedBox(height: 12), 
                        GestureDetector(
                          onTap: () { 
                            Navigator.pushReplacement(
                              context, 
                              MaterialPageRoute(builder: (context) => VideoPlayerPage(anime: widget.anime, seasonIndex: widget.seasonIndex, episodeIndex: widget.episodeIndex + 1))
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
                                  offset: const Offset(0, 5)
                                )
                              ]
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
                                        Image.network(currentSeason.episodes[widget.episodeIndex + 1].image, fit: BoxFit.cover), 
                                        Container(color: Colors.black38), 
                                        const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40))
                                      ]
                                    )
                                  )
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
                                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)
                                        ), 
                                        const SizedBox(height: 4), 
                                        Text(
                                          currentSeason.episodes[widget.episodeIndex + 1].title, 
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), 
                                          maxLines: 1, 
                                          overflow: TextOverflow.ellipsis
                                        ), 
                                        const SizedBox(height: 6), 
                                        Row(
                                          children:[
                                            const Icon(Icons.access_time, color: Colors.white54, size: 14), 
                                            const SizedBox(width: 4), 
                                            Text(
                                              currentSeason.episodes[widget.episodeIndex + 1].duration, 
                                              style: const TextStyle(color: Colors.white54, fontSize: 12)
                                            )
                                          ]
                                        )
                                      ]
                                    )
                                  )
                                )
                              ]
                            )
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
// FULLY WORKING BROWSE (SEARCH) SCREEN - UPDATED PERSISTENCE
// ==========================================
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key}); 
  @override 
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final TextEditingController _searchController = TextEditingController(); 
  List<Anime> _searchResults = [];
  bool _isLoadingSearches = true;

  @override
  void initState() {
    super.initState();
    _fetchRecentSearches(); // Fetch on load
  }

  // Fetch data from Supabase on load
  Future<void> _fetchRecentSearches() async {
    try {
      final response = await Supabase.instance.client
          .from('user_preferences')
          .select('recent_searches')
          .eq('email', currentUserEmail) // Filter by current user's email
          .single();

      if (response != null && response['recent_searches'] != null) {
        setState(() {
          // Check if recent searches is a string or list
          var data = response['recent_searches'];
          if (data is String) {
            globalRecentSearches = List<String>.from(jsonDecode(data));
          } else if (data is List) {
            globalRecentSearches = List<String>.from(data);
          } else {
            globalRecentSearches = [];
          }
          _isLoadingSearches = false;
        });
      } else {
        setState(() => _isLoadingSearches = false);
      }
    } catch (e) {
      print("Error fetching recent searches: $e");
      setState(() => _isLoadingSearches = false);
    }
  }

  // Save/Update recent searches to Supabase DB
  Future<void> _updateRecentSearchesInDb(String query) async {
    final newSearches = [...globalRecentSearches];
    if (newSearches.length > 5) newSearches.removeLast(); // Keep list short
    if (!newSearches.contains(query)) newSearches.insert(0, query);
    
    // Convert List<String> to JSON string for jsonb type in Supabase
    String searchesJson = jsonEncode(newSearches);

    try {
      await Supabase.instance.client.from('user_preferences').upsert(
        {'id': Supabase.instance.client.auth.currentUser!.id, 'email': currentUserEmail, 'recent_searches': searchesJson},
        onConflict: 'id',
      );
    } catch (e) {
      print("Error saving recent searches: $e");
    }
  }

  void _performSearch(String query) { 
    if (query.isEmpty) { 
      setState(() { 
        _searchResults = []; 
      }); 
    } else { 
      setState(() { 
        _searchResults = animeData.where((anime) {
          return anime.title.toLowerCase().contains(query.toLowerCase()) || anime.genre.toLowerCase().contains(query.toLowerCase());
        }).toList(); 
      }); 
    } 
  }

  void _setSearchQuery(String query) { 
    _searchController.text = query; 
    _performSearch(query); 
    // Save to DB when selected from recents
    if (query.isNotEmpty) {
      _updateRecentSearchesInDb(query); 
    }
  }

  void _submitSearch(String query) { 
    if (query.trim().isNotEmpty && !globalRecentSearches.contains(query.trim())) { 
      setState(() {
        globalRecentSearches.insert(0, query.trim());
      }); 
      _updateRecentSearchesInDb(query.trim()); // Save to DB when new search submitted
    } 
    _performSearch(query); 
  }

  void _removeRecentSearch(int index) {
    setState(() {
      globalRecentSearches.removeAt(index);
    });
    // Update DB after removal
    _updateRecentSearchesInDb(globalRecentSearches.join(',')); 
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
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A), 
                  borderRadius: BorderRadius.circular(12)
                ), 
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 16)
                  )
                )
              ),
              const SizedBox(height: 24),
              
              if (_searchController.text.isNotEmpty) ...[
                Text(
                  "Search Results for '${_searchController.text}'", 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                ), 
                const SizedBox(height: 12), 
                if (_searchResults.isEmpty) 
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 20), 
                      child: Text("No anime found.", style: TextStyle(color: Colors.white54))
                    )
                  ) 
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
                    itemBuilder: (context, index) => GridCategoryCard(anime: _searchResults[index], pageTitle: "")
                  )
              ] else ...[
                const Text(
                  "Recent Searches", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                ), 
                const SizedBox(height: 12), 
                _isLoadingSearches
                    ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                    : (globalRecentSearches.isEmpty) 
                        ? const Text("No recent searches.", style: TextStyle(color: Colors.white54)) 
                        : ListView.builder(
                            shrinkWrap: true, 
                            physics: const NeverScrollableScrollPhysics(), 
                            itemCount: globalRecentSearches.length, 
                            itemBuilder: (context, index) { 
                              return _buildRecentItem(globalRecentSearches[index], index); 
                            }
                          )
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
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), 
          borderRadius: BorderRadius.circular(10)
        ), 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children:[
            Expanded( // Added Expanded here to handle overflow
              child: Text(
                title, 
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ), 
            Row(
              children:[
                GestureDetector(
                  onTap: () => _removeRecentSearch(index), 
                  child: Icon(Icons.close, size: 18, color: Colors.grey[500])
                ), 
                const SizedBox(width: 12), 
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[600])
              ]
            )
          ]
        )
      )
    ); 
  }
}

// ==========================================
// DUBS SCREEN - UPDATED TAGS
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
              Tab(text: "ORIGINAL")
            ]
          )
        ), 
        body: TabBarView(
          children:[
            // Dubbed Section (show DUB and MIX tags)
            GridView.builder(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100), 
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 14, mainAxisSpacing: 16), 
              itemCount: animeData.length, 
              itemBuilder: (context, index) {
                final anime = animeData[index];
                if (anime.dubStatus == "DUB" || anime.dubStatus == "MIX") {
                  return GridCategoryCard(anime: anime, pageTitle: "DUB"); // Passing "DUB" as pageTitle for tag logic
                }
                return const SizedBox.shrink();
              }
            ), 
            // Original Section (show ORIGINAL and MIX tags)
            GridView.builder(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100), 
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 14, mainAxisSpacing: 16), 
              itemCount: animeData.length, 
              itemBuilder: (context, index) {
                final anime = animeData[index];
                if (anime.dubStatus == "ORIGINAL" || anime.dubStatus == "MIX") {
                  return GridCategoryCard(anime: anime, pageTitle: "ORIGINAL"); // Passing "ORIGINAL" as pageTitle for tag logic
                }
                return const SizedBox.shrink();
              }
            )
          ]
        )
      )
    ); 
  }
}

// ==========================================
// MY LIST SCREEN - PERSISTENCE ADDED
// ==========================================
class MyListScreen extends StatefulWidget {
  const MyListScreen({super.key});

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  bool _isLoadingSavedAnime = true;

  @override
  void initState() {
    super.initState();
    _fetchSavedAnime();
  }

  // Fetch saved anime list from Supabase on load
  Future<void> _fetchSavedAnime() async {
    try {
      final response = await Supabase.instance.client
          .from('user_preferences')
          .select('saved_anime')
          .eq('email', currentUserEmail) // Filter by current user's email
          .single();

      if (response != null && response['saved_anime'] != null) {
        final List<dynamic> savedData = response['saved_anime'];
        final List<SavedEpisode> fetchedList = [];
        for (var data in savedData) {
          final animeTitle = data['animeTitle'];
          try {
            final animeMatch = animeData.firstWhere((anime) => anime.title == animeTitle);
            fetchedList.add(SavedEpisode(
              anime: animeMatch,
              seasonIndex: data['seasonIndex'] ?? 0,
              episodeIndex: data['episodeIndex'] ?? 0,
            ));
          } catch (e) {
            print("Anime not found in dummy data: $animeTitle");
          }
        }
        setState(() {
          myListNotifier.value = fetchedList;
          _isLoadingSavedAnime = false;
        });
      } else {
        setState(() => _isLoadingSavedAnime = false);
      }
    } catch (e) {
      print("Error fetching saved anime: $e");
      setState(() => _isLoadingSavedAnime = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("My List", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoadingSavedAnime
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : ValueListenableBuilder<List<SavedEpisode>>(
              valueListenable: myListNotifier,
              builder: (context, savedList, child) {
                if (savedList.isEmpty) {
                  return const Center(
                    child: Text(
                      "Your watch list is empty.", 
                      style: TextStyle(color: Colors.white54, fontSize: 16)
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    childAspectRatio: 0.65, 
                    crossAxisSpacing: 14, 
                    mainAxisSpacing: 16
                  ),
                  itemCount: savedList.length,
                  itemBuilder: (context, index) {
                    return GridCategoryCard(
                      anime: savedList[index].anime, 
                      pageTitle: ""
                    );
                  },
                );
              },
            ),
    );
  }
}

// ==========================================
// PROFILE SCREEN - REDESIGNED UI (BASED ON SCREENSHOT)
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

  // Temporary/Placeholder values for the new stats section as requested by UI design
  String episodesWatched = "145";
  String watchTime = "28h 45m";
  String favoritesCount = "32";

  // State for the new SwitchListTile
  bool _streamCellularEnabled = true;

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
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Colors.black,
                        value: selectedCountryCode,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                        items: const [
                          DropdownMenuItem(value: "+91", child: Text("🇮🇳 +91", style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: "+1", child: Text("🇺🇸 +1", style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: "+44", child: Text("🇬🇧 +44", style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: "+81", child: Text("🇯🇵 +81", style: TextStyle(color: Colors.white)))
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedCountryCode = val);
                          }
                        }
                      )
                    )
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
                      )
                    )
                  )
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  onPressed: () {
                    if (_mobileController.text.isNotEmpty) {
                      setState(() => addedMobileNumber = "$selectedCountryCode ${_mobileController.text}");
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mobile number saved!")));
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- Header Section ---
              _buildProfileHeader(),
              const SizedBox(height: 20),

              // --- Statistics Section ---
              _buildStatsSection(),
              const SizedBox(height: 30),

              // --- Account Menu Section ---
              _buildAccountMenu(),
              const SizedBox(height: 20),

              // --- App Settings Section ---
              _buildAppSettings(),
              
              const SizedBox(height: 20),
              // --- Privacy and Other Settings ---
              _buildPrivacySection(),

              // --- Footer Info ---
              const SizedBox(height: 20),
              const Text("Version 1.0.0 (1)", style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {},
                child: const Text("Terms of Service", style: TextStyle(color: Colors.orange)),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text("Privacy Policy", style: TextStyle(color: Colors.orange)),
              ),
              const SizedBox(height: 80), // Space for bottom navigation bar
            ],
          ),
        ),
      ),
    );
  }

  // --- Profile Header Widget (Matching Screenshot) ---
  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with Glowing Border (as per screenshot)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Screenshot's glow effect
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    // Placeholder image URL, replace with dynamic logic if available
                    "https://i.ibb.co/C3rhjGv3/images-1.jpg", // Example image URL
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => CircleAvatar(
                      radius: 40,
                      backgroundColor: getAvatarColor(currentUserName),
                      child: Text(getAvatarLetter(currentUserName), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // User Info Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          currentUserName.isNotEmpty ? currentUserName : "User Name",
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Colors.blue, size: 18), // Verified checkmark
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Premium Member Tag
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          userActivePlan.isNotEmpty ? "Premium Member" : "Free Member", // Dynamic text
                          style: TextStyle(color: userActivePlan.isNotEmpty ? Colors.amber : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Joined Jan 2024 • ID: ANMX1001", // Placeholder text matching screenshot
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Notification and Settings Icons (top right)
              Row(
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: () { /* Navigate to Notifications */ },
                      ),
                      Container( // Red dot for new notification
                        margin: const EdgeInsets.all(8),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () { /* Navigate to Settings */ },
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),

          // Edit Profile Button (separate line below user info)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    "Edit Profile",
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Statistics Section Widget (Matching Screenshot) ---
  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.play_circle_fill, Colors.purpleAccent, episodesWatched, "Episodes Watched"),
          _buildStatItem(Icons.watch_later, Colors.green, watchTime, "Watch Time"),
          _buildStatItem(Icons.favorite, Colors.pinkAccent, favoritesCount, "Favorites"),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color iconColor, String count, String label) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 30),
        const SizedBox(height: 6),
        Text(count, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  // --- Account Menu Section Widget ---
  Widget _buildAccountMenu() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.star,
          label: "Subscription",
          iconColor: Colors.amber,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(userActivePlan.isNotEmpty ? userActivePlan : "Free", style: const TextStyle(color: Colors.white70)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
            ],
          ),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())),
        ),
        _buildMenuItem(
          icon: Icons.notifications_none,
          label: "Notifications",
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: const Text("1", style: TextStyle(color: Colors.white, fontSize: 12))),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
            ],
          ),
          onTap: () {},
        ),
        const Divider(color: Colors.white12, thickness: 1),
        _buildMenuItem(
          icon: Icons.email,
          label: "Email",
          trailing: Text(currentUserEmail, style: const TextStyle(color: Colors.white70)),
        ),
        _buildMenuItem(
          icon: Icons.lock,
          label: "Password",
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.phone,
          label: "Add Phone Number",
          trailing: addedMobileNumber != null ? const Icon(Icons.check_circle, color: Colors.green, size: 16) : const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
          onTap: _showAddInfoDialog,
        ),
      ],
    );
  }

  // --- App Settings Section Widget ---
  Widget _buildAppSettings() {
    return Column(
      children: [
        _buildSwitchItem(
          label: "Stream Using Cellular",
          value: _streamCellularEnabled,
          onChanged: (value) => setState(() => _streamCellularEnabled = value),
        ),
        _buildMenuItem(
          icon: null,
          label: "Notification Settings",
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
          onTap: () {},
        ),
        _buildMenuItem(
          icon: null,
          label: "Connected Apps",
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
          onTap: () {},
        ),
      ],
    );
  }
  
  // --- Privacy and Other Settings Section Widget ---
  Widget _buildPrivacySection() {
    return Column(
      children: [
        const Divider(color: Colors.white12, thickness: 1),
        _buildMenuItem(
          icon: null,
          label: "Don't Sell/Share my personal information",
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
          onTap: () {},
        ),
        _buildMenuItem(
          icon: null,
          label: "Delete My Account",
          textColor: Colors.redAccent,
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
          onTap: () {},
        ),
      ],
    );
  }

  // --- Generic Menu Item Builder (for standard list items) ---
  Widget _buildMenuItem({required IconData? icon, required String label, Color? iconColor, Color textColor = Colors.white, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: icon != null ? Icon(icon, color: iconColor ?? Colors.white) : null,
      title: Text(label, style: TextStyle(color: textColor)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  // --- Generic Switch Item Builder (for settings toggle) ---
  Widget _buildSwitchItem({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.orange,
      trackOutlineColor: MaterialStateProperty.resolveWith((states) => Colors.transparent), // Remove border
    );
  }
}

// ==========================================
// PLACEHOLDER PAGES FOR MENU OPTIONS - UPDATED
// ==========================================
class PrivacyPolicyPage extends StatelessWidget { 
  const PrivacyPolicyPage({super.key});

  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        title: const Text("Privacy Policy", style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.black, 
        iconTheme: const IconThemeData(color: Colors.white)
      ), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16), 
        child: const Text(
          "Privacy Policy\n\nWelcome to AnimeMX. At AnimeMX, we value your privacy. This Privacy Policy outlines how we collect, use, and protect your data.\n\nWe do not sell your personal data to third parties. All user preferences, including recent searches and saved episodes, are stored locally on your device unless connected via cloud synchronization. For more details, please contact our support team.", 
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)
        )
      )
    ); 
  } 
}

class AboutUsPage extends StatelessWidget { 
  const AboutUsPage({super.key});

  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        title: const Text("About Us", style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.black, 
        iconTheme: const IconThemeData(color: Colors.white)
      ), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: const [
            Text("About AnimeMX", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), 
            SizedBox(height: 12), 
            Text(
              "Welcome to AnimeMX, your ultimate destination for streaming the best and latest anime! Our mission is to provide a seamless and high-quality viewing experience for anime fans around the world. We offer a vast library of titles, from classics to new releases, both dubbed and subbed, ensuring everyone finds something they love.", 
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)
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
        title: const Text("Support", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Contact Us", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildSupportItem(
              icon: Icons.email,
              title: "Email Support",
              subtitle: "support@animemx.com",
              onTap: () { launchInBrowser("mailto:support@animemx.com"); },
            ),
            _buildSupportItem(
              icon: Icons.phone,
              title: "WhatsApp Support",
              subtitle: "+91 1234567890",
              onTap: () { launchWhatsApp("+911234567890"); },
            ),
            _buildSupportItem(
              icon: Icons.telegram,
              title: "Telegram Channel",
              subtitle: "@animemx_official",
              onTap: () { launchTelegram("animemx_official"); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 28),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Premium Membership", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Upgrade to AnimeMX Premium",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber),
            ),
            const SizedBox(height: 16),
            const Text(
              "Enjoy ad-free streaming, unlimited downloads, and access to exclusive content.",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            // Example of a premium plan card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Monthly Plan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text("₹199 / month", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 12),
                  _buildFeatureItem("Ad-free viewing"),
                  _buildFeatureItem("HD streaming quality"),
                  _buildFeatureItem("Download episodes for offline viewing"),
                  _buildFeatureItem("Early access to new releases"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Logic for purchase/subscription initiation
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Purchase flow initiated.")));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Subscribe Now", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}