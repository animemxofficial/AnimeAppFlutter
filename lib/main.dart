import 'dart:io'; 
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; 
import 'dart:convert'; 

// ==========================================
// DATA MODELS & GLOBAL STATE
// ==========================================

String currentUserName = "Guest User"; 
String currentUserEmail = "";
String userMobileNumber = ""; 
String userActivePlan = ""; 
bool hasAcceptedCookies = false; // Global Tracker for Cookie Banner

List<String> globalRecentSearches = [];

// --- GLOBAL NOTIFIERS ---
final ValueNotifier<List<CWItem>> continueWatchingNotifier = ValueNotifier([]);
final ValueNotifier<List<SavedEpisode>> myListNotifier = ValueNotifier([]);
final ValueNotifier<Map<String, int>> globalAnimeViewsNotifier = ValueNotifier({});

// --- THEME NOTIFIERS ---
// Changed default color to AnimeMX Logo's Neon Purple theme
const Color animeMxPurple = Color(0xFF9D00FF); 
final ValueNotifier<Color> primaryColorNotifier = ValueNotifier(animeMxPurple); 

// --- THEME HELPER FUNCTIONS (FORCED DARK MODE) ---
Color getBg(BuildContext context) => Colors.black;
Color getCard(BuildContext context) => const Color(0xFF1A1A1A);
Color getText(BuildContext context) => Colors.white;
Color getSubText(BuildContext context) => Colors.white54;

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

String formatViewsCount(int views) {
  if (views >= 1000000) return (views / 1000000).toStringAsFixed(1) + "M";
  if (views >= 1000) return (views / 1000).toStringAsFixed(1) + "K";
  return views.toString();
}

Future<void> fetchGlobalAnimeViews() async {
  try {
    final response = await Supabase.instance.client
        .from('episode_views')
        .select('episode_id, view_count');

    Map<String, int> viewsMap = {};
    if (response != null) {
      for (var row in response) {
        String epId = row['episode_id'];
        int vCount = row['view_count'] ?? 0;

        List<String> parts = epId.split('_');
        if (parts.length >= 3) {
          String title = parts.sublist(0, parts.length - 2).join('_');
          viewsMap[title] = (viewsMap[title] ?? 0) + vCount; 
        }
      }
    }
    globalAnimeViewsNotifier.value = viewsMap;
  } catch (e) {
    print("Error fetching global views: $e");
  }
}

// ==========================================
// SUPABASE DATA PERSISTENCE SERVICES
// ==========================================

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
    if (newSearches.length > 5) newSearches.removeLast(); 
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
    final savedData = savedList.map((item) => item.toJson()).toList();
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
      return CWItem(
        anime: animeData[0], 
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
    this.views = "0", 
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
    this.views = "0", 
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
          views: "0", 
          videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        ),
        Episode(
          title: "A New Threat", 
          image: "https://i.ibb.co/C3rhjGv3/images-1.jpg", 
          duration: "23m 45s", 
          views: "0", 
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
          views: "0", 
          videoUrl: "https://animemx-proxy.onrender.com/stream/AgADXx8AAg-FSFY"
        ), 
        Episode(
          title: "Episode 2", 
          image: "https://i.ibb.co/vxJtwkcX/k.jpg", 
          duration: "23m 45s", 
          views: "0", 
          videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
        ),
      ]
    ),
  ];
}

final List<Anime> animeData = [
  Anime(title: "Solo Leveling", genre: "Action", image: "https://i.ibb.co/C3rhjGv3/images-1.jpg", views: "0", dubStatus: "DUB", dubColor: const Color(0xFFFF4D4D), season: "S1", seasonsList: generateDummySeasons(), isNew: true),
  Anime(title: "Classroom of the Elite", genre: "Thriller", image: "https://i.ibb.co/vxJtwkcX/k.jpg", status: "Completed", views: "0", dubStatus: "MIX", dubColor: const Color(0xFF4DA6FF), season: "S3", seasonsList: generateClassroomOfEliteSeasons()),
  Anime(title: "One Piece", genre: "Adventure", image: "https://i.ibb.co/jvVk3XSY/g.jpg", views: "0", dubStatus: "DUB", dubColor: const Color(0xFF4DA6FF), season: "S1", seasonsList: generateDummySeasons()),
  Anime(title: "Naruto", genre: "Action", image: "https://i.ibb.co/YFg2hKvf/j.jpg", views: "0", dubStatus: "ORIGINAL", dubColor: const Color(0xFFFF9F43), season: "S1", seasonsList: generateDummySeasons()),
  Anime(title: "Demon Slayer", genre: "Action", image: "https://i.ibb.co/yFRNxJbG/o.jpg", views: "0", dubStatus: "MIX", dubColor: const Color(0xFF00C853), season: "S2", seasonsList: generateDummySeasons()),
  Anime(title: "Death Note", genre: "Mystery", image: "https://i.ibb.co/L0x9WvY/the-eminence-in-shadow.jpg", views: "0", dubStatus: "DUB", dubColor: const Color(0xFF7A5CFF), season: "S1", seasonsList: generateDummySeasons()),
  Anime(title: "Your Name", genre: "Romance", image: "https://i.ibb.co/rW2Zk9B/images.jpg", views: "0", dubStatus: "MIX", dubColor: const Color(0xFFFF4D4D), season: "Movie", seasonsList: generateDummySeasons()),
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

List<OrderItem> userOrders = []; 

// ==========================================
// MAIN ENTRY POINT
// ==========================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yngzfgfpyufusrbitagl.supabase.co',          
    anonKey: 'sb_publishable_6BD0moEpOnUTfihbRUpdOQ_U2gJCH5U', 
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
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
  final cleanNumber = number.replaceAll(RegExp(r'\D'), '');
  final Uri uri = Uri.parse("https://wa.me/$cleanNumber");
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    print("Could not launch WhatsApp");
  }
}

Future<void> launchTelegram(String contact) async {
  final cleanContact = contact.replaceAll(RegExp(r'\s+'), '');
  final Uri uri = Uri.parse("https://t.me/$cleanContact");
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    print("Could not launch Telegram");
  }
}

// ==========================================
// ROOT APP (WITH THEME SUPPORT - DARK ONLY + NO RIPPLE EFFECT)
// ==========================================
class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: primaryColorNotifier,
      builder: (context, currentColor, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: currentColor,
            scaffoldBackgroundColor: Colors.black,
            useMaterial3: true,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white),
          ),
          theme: ThemeData(
            brightness: Brightness.dark, 
            primaryColor: currentColor,
            scaffoldBackgroundColor: Colors.black,
            useMaterial3: true,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
          ),
          home: const AuthGate(), 
        );
      }
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
          return Scaffold(
            backgroundColor: getBg(context),
            body: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
          );
        }
        final session = snapshot.data?.session;
        if (session != null) {
          currentUserEmail = session.user.email ?? "User";
          currentUserName = currentUserEmail.split('@')[0]; 
          return const MainScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// ==========================================
// LOGIN SCREEN (CLEAN & SPACIOUS UI)
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
  bool _isLoginMode = true; 
  bool _obscurePassword = true;

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
      setState(() => _isLoginMode = true); 
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

  InputDecoration _inputDecoration(BuildContext context, String hint, IconData icon, {Widget? suffixIcon}) {
    Color primColor = Theme.of(context).primaryColor;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54, fontSize: 16), // Increased hint text size
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(icon, color: primColor, size: 24), // Increased icon size slightly
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF121212), 
      // Increased vertical padding to make text fields taller and spacious
      contentPadding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: Colors.black, 
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Custom Logo Placeholder
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primColor, width: 2),
                      ),
                      child: const Icon(Icons.change_history, color: Colors.white, size: 36), // Slightly bigger
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      "ANIMEMX", 
                      style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2) 
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "STREAM YOUR ANIME WORLD", 
                  style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.bold)
                ),
                
                const SizedBox(height: 50), // Increased spacing before box
                
                // Login Box Container - Clean and Spacious
                Container(
                  padding: const EdgeInsets.all(32), // Increased padding inside the box
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C0C0C), // Very dark grey, almost black
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: primColor.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: primColor.withOpacity(0.08), 
                        blurRadius: 30, 
                        spreadRadius: 2
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isLoginMode ? "Welcome Back!" : "Create Account", 
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isLoginMode ? "Login to continue your anime adventure" : "Sign up to start your adventure", 
                                  style: const TextStyle(color: Colors.white54, fontSize: 14)
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.ac_unit, color: primColor, size: 24), // Placeholder icon
                          )
                        ],
                      ),
                      const SizedBox(height: 40), // Increased spacing
                      
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: _inputDecoration(context, "Email Address", Icons.person_outline),
                      ),
                      const SizedBox(height: 24), // Increased spacing between fields
                      
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: _inputDecoration(
                          context, 
                          "Password", 
                          Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 22),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          )
                        ),
                      ),
                      
                      if (_isLoginMode) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text("Forgot Password?", style: TextStyle(color: primColor, fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      const SizedBox(height: 36), // Increased spacing before button
                      
                      if (_isLoading)
                        Center(child: CircularProgressIndicator(color: primColor))
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 60, // Taller button
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 10,
                              shadowColor: primColor.withOpacity(0.5),
                            ),
                            onPressed: _isLoginMode ? _signIn : _signUp,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLoginMode ? "LOGIN" : "SIGN UP", 
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.arrow_forward, color: Colors.white, size: 24),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40), // Spacing before footer
                
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isLoginMode = !_isLoginMode;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12),
                          color: Colors.white.withOpacity(0.05),
                        ),
                        child: Icon(Icons.pets, color: primColor, size: 24), 
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoginMode ? "Don't have an account?" : "Already have an account?",
                            style: const TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                _isLoginMode ? "Sign Up" : "Log In",
                                style: TextStyle(color: primColor, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.arrow_forward, color: primColor, size: 16),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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

  @override
  void initState() {
    super.initState();
    fetchGlobalAnimeViews(); 
    _fetchUserPreferences(); 
    
    // Show Cookies Banner on login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasAcceptedCookies) {
        _showCookieBanner(context);
      }
    });
  }

  // Fetch Continue Watching and Saved List from Supabase on App Start
  Future<void> _fetchUserPreferences() async {
    try {
      final response = await Supabase.instance.client
          .from('user_preferences')
          .select('continue_watching, saved_anime')
          .eq('email', currentUserEmail)
          .maybeSingle();

      if (response != null) {
        if (response['continue_watching'] != null) {
          final List<dynamic> cwData = response['continue_watching'];
          continueWatchingNotifier.value = cwData.map((data) => CWItem.fromJson(data)).toList();
        }
        if (response['saved_anime'] != null) {
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
              // Anime missing from dummy data
            }
          }
          myListNotifier.value = fetchedList;
        }
      }
    } catch (e) {
      print("Error fetching user preferences on startup: $e");
    }
  }

  void _showCookieBanner(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: getCard(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cookie, color: primColor, size: 28),
                const SizedBox(width: 10),
                const Text("Cookie Policy", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              "We use cookies to improve your experience, personalize content, and analyze traffic. You can choose to accept or manage your preferences anytime.", 
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14)
                    ),
                    onPressed: () {
                      hasAcceptedCookies = true;
                      Navigator.pop(context);
                    },
                    child: Text("Decline", style: TextStyle(color: primColor, fontWeight: FontWeight.bold)),
                  )
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14)
                    ),
                    onPressed: () {
                      hasAcceptedCookies = true;
                      Navigator.pop(context);
                    },
                    child: const Text("Accept All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ),
              ],
            )
          ],
        )
      )
    );
  }

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
        backgroundColor: getCard(context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
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
    Color primColor = Theme.of(context).primaryColor;
    final List<Map<String, dynamic>> sliderItems = [
      {'anime': animeData[0], 'tag': 'TRENDING', 'color': primColor},
      {'anime': animeData[2], 'tag': 'POPULAR', 'color': Colors.cyan},
      {'anime': animeData[6], 'tag': 'RECOMMENDED', 'color': Colors.blueAccent},
      {'anime': animeData[7], 'tag': 'COMING SOON', 'color': Colors.grey}, 
    ];

    return Scaffold(
      backgroundColor: getBg(context),
      drawer: Drawer(
        backgroundColor: getCard(context),
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
                          style: TextStyle(color: getText(context), fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUserEmail, 
                          style: TextStyle(color: getSubText(context), fontSize: 12), 
                          overflow: TextOverflow.ellipsis
                        ),
                        if (userActivePlan.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primColor.withOpacity(0.2), 
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(
                              userActivePlan.toUpperCase(), 
                              style: TextStyle(color: primColor, fontSize: 10, fontWeight: FontWeight.bold)
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
              leading: Icon(Icons.home, color: getSubText(context)), 
              title: Text("Home", style: TextStyle(color: getText(context))), 
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
              leading: Icon(Icons.language, color: getSubText(context)), 
              title: Text("Website", style: TextStyle(color: getText(context))), 
              onTap: () => Navigator.pop(context)
            ),
            ListTile(
              leading: Icon(Icons.headset_mic, color: getSubText(context)), 
              title: Text("Support", style: TextStyle(color: getText(context))), 
              onTap: () { 
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportPage())); 
              }
            ),
            ListTile(
              leading: Icon(Icons.privacy_tip_outlined, color: getSubText(context)), 
              title: Text("Privacy Policy", style: TextStyle(color: getText(context))), 
              onTap: () { 
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage())); 
              }
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: getSubText(context)), 
              title: Text("About Us", style: TextStyle(color: getText(context))), 
              onTap: () { 
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutUsPage())); 
              }
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0), 
              child: Divider(color: Colors.white12, thickness: 1)
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20), 
              title: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)), 
              onTap: () async { 
                Navigator.pop(context); 
                await Supabase.instance.client.auth.signOut(); 
              }
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: getBg(context), 
        elevation: 0,
        leading: Builder(
          builder: (context) { 
            return IconButton(
              icon: Icon(Icons.menu, color: getText(context)), 
              onPressed: () => Scaffold.of(context).openDrawer()
            ); 
          }
        ),
        title: Text(
          "AnimeMX", 
          style: TextStyle(color: primColor, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)
        ),
        actions:[
          IconButton(
            icon: Icon(Icons.search, color: getText(context)), 
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
                return _buildThumbnailSection(context, "Continue Watching", Icons.history, primColor, true, cwList: cwList); 
              }
            ),
            
            _buildPortraitSection(context, "Trending Now", Icons.local_fire_department_rounded, primColor, animeData),
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
    Color primColor = Theme.of(context).primaryColor;
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: getText(context))
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
                child: Text(
                  "See All", 
                  style: TextStyle(color: primColor, fontWeight: FontWeight.bold, fontSize: 13)
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
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10), 
                            child: Image.network(list[index].image, fit: BoxFit.cover, width: double.infinity)
                          ),
                        )
                      ), 
                      const SizedBox(height: 8), 
                      Text(
                        list[index].title, 
                        style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 13), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis
                      ), 
                      Text(
                        list[index].genre, 
                        style: TextStyle(color: getSubText(context), fontSize: 11), 
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
    Color primColor = Theme.of(context).primaryColor;
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: getText(context))
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
                child: Text(
                  "See All", 
                  style: TextStyle(color: primColor, fontWeight: FontWeight.bold, fontSize: 13)
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
    Color primColor = Theme.of(context).primaryColor;
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: getText(context))
                  ), 
                  if (icon != null) ...[
                    const SizedBox(width: 6), 
                    Icon(icon, color: iconColor, size: 20)
                  ]
                ]
              ), 
              GestureDetector(
                onTap: () { 
                  if (isCW) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CWSeeAllPage(cwList: cwList!)));
                  } else {
                    bool isLatest = title == "Latest Episodes";
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => SeeAllCategoryPage(title: title, animeList: animeList!, isLatestOnly: isLatest))
                    ); 
                  }
                }, 
                child: Text(
                  "See All", 
                  style: TextStyle(color: primColor, fontWeight: FontWeight.bold, fontSize: 13)
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
                bool isLatest = title == "Latest Episodes";
                return ThumbnailLatestCard(anime: animeList![index], isLatestOnly: isLatest); 
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
// CONTINUE WATCHING "SEE ALL" PAGE (VERTICAL CARDS)
// ==========================================
class CWSeeAllPage extends StatelessWidget {
  final List<CWItem> cwList;
  const CWSeeAllPage({super.key, required this.cwList});

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(
        title: Text("Continue Watching", style: TextStyle(color: getText(context), fontWeight: FontWeight.bold)),
        backgroundColor: getBg(context),
        iconTheme: IconThemeData(color: getText(context)),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: cwList.length,
        itemBuilder: (context, index) {
          final item = cwList[index];
          double progress = 0.0;
          if (item.totalDuration.inMilliseconds > 0) {
            progress = item.position.inMilliseconds / item.totalDuration.inMilliseconds;
          }
          final ep = item.anime.seasonsList[item.seasonIndex].episodes[item.episodeIndex];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (_) => VideoPlayerPage(
                    anime: item.anime, 
                    seasonIndex: item.seasonIndex, 
                    episodeIndex: item.episodeIndex, 
                    startPosition: item.position
                  )
                )
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 110,
              decoration: BoxDecoration(
                color: getCard(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
                ]
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    height: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(ep.image, fit: BoxFit.cover),
                          Container(color: Colors.black38),
                          const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40)),
                          if (progress > 0.0)
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.black54,
                                valueColor: AlwaysStoppedAnimation<Color>(primColor),
                                minHeight: 4,
                              )
                            )
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.anime.title,
                            style: TextStyle(color: getText(context), fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Episode ${item.episodeIndex + 1}: ${ep.title}",
                            style: TextStyle(color: getSubText(context), fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, color: primColor, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                "${(progress * 100).toInt()}% Watched",
                                style: TextStyle(color: primColor, fontSize: 12, fontWeight: FontWeight.bold),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// CATEGORY PAGES & CARDS
// ==========================================
class SeeAllCategoryPage extends StatelessWidget {
  final String title; 
  final List<Anime> animeList; 
  final bool isLatestOnly;
  
  const SeeAllCategoryPage({
    super.key, 
    required this.title, 
    required this.animeList,
    this.isLatestOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(
        backgroundColor: getBg(context), 
        elevation: 0, 
        title: Text(
          title, 
          style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 20)
        ), 
        iconTheme: IconThemeData(color: getText(context))
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
        itemBuilder: (context, index) => GridCategoryCard(anime: animeList[index], pageTitle: title, isLatestOnly: isLatestOnly)
      ),
    );
  }
}

// POPULAR CARD 
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
                            ValueListenableBuilder<Map<String, int>>(
                              valueListenable: globalAnimeViewsNotifier,
                              builder: (context, viewsMap, child) {
                                int totalViews = viewsMap[anime.title] ?? 0;
                                return Text(
                                  formatViewsCount(totalViews),
                                  style: const TextStyle(color: Colors.white70, fontSize: 10)
                                );
                              },
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

// MAIN ANIME CARD 
class GridCategoryCard extends StatefulWidget {
  final Anime anime; 
  final String pageTitle; 
  final bool isLatestOnly;
  
  const GridCategoryCard({super.key, required this.anime, required this.pageTitle, this.isLatestOnly = false});

  @override
  State<GridCategoryCard> createState() => _GridCategoryCardState();
}

class _GridCategoryCardState extends State<GridCategoryCard> {
  void _toggleSaveAnime() {
    final list = List<SavedEpisode>.from(myListNotifier.value);
    final isSaved = list.any((item) => item.anime.title == widget.anime.title);

    if (isSaved) {
      list.removeWhere((item) => item.anime.title == widget.anime.title);
    } else {
      list.add(SavedEpisode(anime: widget.anime, seasonIndex: 0, episodeIndex: 0));
    }
    myListNotifier.value = list;
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
    Color primColor = Theme.of(context).primaryColor;
    String? tagText; 
    Color? tagBgColor; 
    Color tagTextColor = Colors.black;
    
    if (widget.pageTitle == "Trending Now") { 
      tagText = "TRENDING"; 
      tagBgColor = primColor; 
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
    
    if (widget.pageTitle == "Latest Episodes" && widget.anime.isNew) {
      tagText = "NEW";
      tagBgColor = Colors.green;
      tagTextColor = Colors.white;
    }

    final bool isSaved = myListNotifier.value.any((item) => item.anime.title == widget.anime.title);
    
    return GestureDetector(
      onTap: () {
        if (widget.isLatestOnly) {
          if (widget.anime.seasonsList.isNotEmpty && widget.anime.seasonsList.last.episodes.isNotEmpty) {
            int sIndex = widget.anime.seasonsList.length - 1;
            int eIndex = widget.anime.seasonsList.last.episodes.length - 1;
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: widget.anime, seasonIndex: sIndex, episodeIndex: eIndex))
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Episodes coming soon!")));
          }
        } else {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => DetailsPage(anime: widget.anime, isLatestOnly: widget.isLatestOnly))
          );
        }
      }, 
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
                            ValueListenableBuilder<Map<String, int>>(
                              valueListenable: globalAnimeViewsNotifier,
                              builder: (context, viewsMap, child) {
                                int totalViews = viewsMap[widget.anime.title] ?? 0;
                                return Text(
                                  formatViewsCount(totalViews),
                                  style: const TextStyle(color: Colors.white70, fontSize: 10)
                                );
                              },
                            )
                          ]
                        )
                      ]
                    )
                  ]
                )
              ),
              Positioned(
                top: 8, 
                left: 8, 
                child: GestureDetector(
                  onTap: () async {
                    _toggleSaveAnime(); 
                  },
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: primColor,
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

// LATEST CARD 
class ThumbnailLatestCard extends StatelessWidget {
  final Anime anime; 
  final bool isLatestOnly;
  const ThumbnailLatestCard({super.key, required this.anime, this.isLatestOnly = false});
  
  @override
  Widget build(BuildContext context) {
    int latestEpNum = anime.seasonsList.isNotEmpty && anime.seasonsList.last.episodes.isNotEmpty 
        ? anime.seasonsList.last.episodes.length 
        : 1;

    return GestureDetector(
      onTap: () {
        if (anime.seasonsList.isNotEmpty && anime.seasonsList.last.episodes.isNotEmpty) {
          int sIndex = anime.seasonsList.length - 1;
          int eIndex = anime.seasonsList.last.episodes.length - 1;
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: anime, seasonIndex: sIndex, episodeIndex: eIndex))
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Episodes coming soon!")));
        }
      }, 
      child: Container(
        width: 180, 
        margin: const EdgeInsets.only(right: 14), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children:[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: Colors.white, width: 1.5) 
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9, 
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), 
                  child: Stack(
                    fit: StackFit.expand, 
                    children:[
                      Image.network(anime.image, fit: BoxFit.cover), 
                      Positioned(
                        bottom: 6, 
                        right: 6, 
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                          decoration: BoxDecoration(
                            color: Colors.black87, 
                            borderRadius: BorderRadius.circular(4)
                          ), 
                          child: Text(
                            "Ep $latestEpNum", 
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                          )
                        )
                      )
                    ]
                  )
                )
              ),
            ), 
            const SizedBox(height: 8), 
            Text(
              anime.title, 
              style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 13), 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis
            ), 
            const SizedBox(height: 2), 
            Text(
              "Latest Episode", 
              style: TextStyle(color: getSubText(context), fontSize: 11)
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
    Color primColor = Theme.of(context).primaryColor;
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: Colors.white, width: 1.5) 
              ),
              child: AspectRatio(
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
                          valueColor: AlwaysStoppedAnimation<Color>(primColor), 
                          minHeight: 4
                        )
                      )
                    ]
                  )
                )
              ),
            ), 
            const SizedBox(height: 8), 
            Text(
              widget.item.anime.title, 
              style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 13), 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis
            ), 
            Text(
              "Episode ${widget.item.episodeIndex + 1}", 
              style: TextStyle(color: getSubText(context), fontSize: 11)
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
  final bool isLatestOnly; 
  const DetailsPage({super.key, required this.anime, this.isLatestOnly = false});
  @override 
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  int _selectedSeasonIndex = 0; 
  bool _isExpanded = false;
  Map<int, String> _episodeViews = {}; 

  @override
  void initState() {
    super.initState();
    if (widget.isLatestOnly && widget.anime.seasonsList.isNotEmpty) {
      _selectedSeasonIndex = widget.anime.seasonsList.length - 1;
    }
    _fetchEpisodeViews();
  }

  Future<void> _fetchEpisodeViews() async {
    try {
      final response = await Supabase.instance.client
          .from('episode_views')
          .select('episode_id, view_count')
          .like('episode_id', '${widget.anime.title}_${_selectedSeasonIndex}_%');
          
      if (mounted && response != null) {
        Map<int, String> viewsMap = {};
        for (var row in response) {
          String epId = row['episode_id'];
          int vCount = row['view_count'] ?? 0;
          
          List<String> parts = epId.split('_');
          if (parts.isNotEmpty) {
            int? eIdx = int.tryParse(parts.last);
            if (eIdx != null) {
              viewsMap[eIdx] = formatViewsCount(vCount);
            }
          }
        }
        setState(() {
          _episodeViews = viewsMap;
        });
      }
    } catch (e) {
      print("Error fetching views: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor; 
    
    if (widget.anime.seasonsList.isEmpty) { 
      return Scaffold(
        backgroundColor: getBg(context),
        appBar: AppBar(
          backgroundColor: getBg(context), 
          title: Text(widget.anime.title, style: TextStyle(color: getText(context)))
        ), 
        body: Center(
          child: Text(
            "Episodes Coming Soon!", 
            style: TextStyle(color: getText(context))
          )
        )
      ); 
    }

    Season currentSeason = widget.anime.seasonsList[_selectedSeasonIndex]; 
    List<Episode> episodesList = currentSeason.episodes;
    
    if (widget.isLatestOnly && episodesList.isNotEmpty) {
      episodesList = [episodesList.last];
    }

    return Scaffold(
      backgroundColor: getBg(context),
      body: CustomScrollView(
        slivers:[
          SliverAppBar(
            expandedHeight: 250, 
            pinned: true, 
            backgroundColor: getBg(context), 
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: getText(context)), 
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
                        colors:[getBg(context), getBg(context).withOpacity(0.5), Colors.transparent], 
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
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: getText(context))
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
                          style: TextStyle(color: getText(context), fontSize: 11, fontWeight: FontWeight.bold)
                        )
                      ), 
                      const SizedBox(width: 10), 
                      Expanded(
                        child: Text(
                          "• Dub | Action, Thriller, Drama", 
                          style: TextStyle(color: getSubText(context), fontSize: 13), 
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
                        backgroundColor: primColor, 
                        padding: const EdgeInsets.symmetric(vertical: 14), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                        elevation: 5
                      ), 
                      onPressed: () { 
                        if (episodesList.isNotEmpty) {
                          int playIndex = widget.isLatestOnly ? currentSeason.episodes.length - 1 : 0;
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => VideoPlayerPage(anime: widget.anime, seasonIndex: _selectedSeasonIndex, episodeIndex: playIndex))
                          ).then((_) { _fetchEpisodeViews(); fetchGlobalAnimeViews(); }); 
                        }
                      }, 
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28), 
                      label: const Text(
                        "Play Now", 
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                      )
                    )
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Kiyotaka Ayanokouji enters the prestigious Tokyo Metropolitan Advanced Nurturing High School, which is dedicated to fostering the best and brightest students. But he ends up in Class-D, a dumping ground for the school's worst. A cruel meritocracy awaits where he must use his dark intellect to survive in a school of ruthless competition and psychological warfare.", 
                    maxLines: _isExpanded ? null : 2, 
                    overflow: _isExpanded ? null : TextOverflow.ellipsis, 
                    style: TextStyle(color: getSubText(context), fontSize: 13, height: 1.5)
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded), 
                    child: Text(
                      _isExpanded ? "Read Less" : "Read More", 
                      style: TextStyle(color: primColor, fontWeight: FontWeight.bold, fontSize: 13)
                    )
                  ),
                  const SizedBox(height: 30),
                  
                  if (!widget.isLatestOnly) ...[
                    Text(
                      "Seasons", 
                      style: TextStyle(color: getText(context), fontSize: 18, fontWeight: FontWeight.bold)
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
                            child: _buildSeasonTab(index, widget.anime.seasonsList[index].name, primColor)
                          ); 
                        }
                      )
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text(
                    widget.isLatestOnly ? "Latest Episode" : "Episodes", 
                    style: TextStyle(color: getText(context), fontSize: 18, fontWeight: FontWeight.bold)
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
                          
                          int actualEpIndex = widget.isLatestOnly ? currentSeason.episodes.length - 1 : index;

                          double progress = 0.0; 
                          final cwIndex = cwList.indexWhere((item) => item.anime.title == widget.anime.title && item.seasonIndex == _selectedSeasonIndex && item.episodeIndex == actualEpIndex); 
                          if (cwIndex != -1) { 
                            if (cwList[cwIndex].totalDuration.inMilliseconds > 0) {
                              progress = cwList[cwIndex].position.inMilliseconds / cwList[cwIndex].totalDuration.inMilliseconds; 
                            }
                          } 
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerPage(anime: widget.anime, seasonIndex: _selectedSeasonIndex, episodeIndex: actualEpIndex, startPosition: cwIndex != -1 ? cwList[cwIndex].position : null)
                              )
                            ).then((_) { _fetchEpisodeViews(); fetchGlobalAnimeViews(); }), 
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12), 
                              padding: const EdgeInsets.all(10), 
                              decoration: BoxDecoration(
                                color: getCard(context), 
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
                                                valueColor: AlwaysStoppedAnimation<Color>(primColor), 
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
                                          "${actualEpIndex + 1}. ${ep.title}", 
                                          style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 15), 
                                          maxLines: 1, 
                                          overflow: TextOverflow.ellipsis
                                        ), 
                                        const SizedBox(height: 6), 
                                        Row(
                                          children:[
                                            Text(
                                              ep.duration, 
                                              style: TextStyle(color: getSubText(context), fontSize: 12)
                                            ), 
                                            const SizedBox(width: 10), 
                                            Icon(Icons.visibility, color: getSubText(context), size: 12), 
                                            const SizedBox(width: 4), 
                                            Text(
                                              _episodeViews[actualEpIndex] ?? ep.views, 
                                              style: TextStyle(color: getSubText(context), fontSize: 12)
                                            )
                                          ]
                                        )
                                      ]
                                    )
                                  ), 
                                  Container(
                                    padding: const EdgeInsets.all(8), 
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle, 
                                      color: Colors.white12
                                    ), 
                                    child: Icon(Icons.play_arrow_rounded, color: getText(context), size: 24)
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
      onTap: () {
        setState(() {
          _selectedSeasonIndex = index;
        });
        _fetchEpisodeViews(); 
      }, 
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
        decoration: BoxDecoration(
          color: isActive ? primaryColor : getCard(context), 
          borderRadius: BorderRadius.circular(8)
        ), 
        child: Center(
          child: Text(
            title, 
            style: TextStyle(color: isActive ? Colors.white : getSubText(context), fontWeight: FontWeight.bold, fontSize: 13)
          )
        )
      )
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
  
  bool _isLiked = false; 
  bool _isDisliked = false;
  int _likesCount = 0;
  int _dislikesCount = 0;
  String _currentViews = "0";

  @override 
  void initState() { 
    super.initState(); 
    _incrementAndFetchViews(); 
    _fetchLikesDislikes(); 
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

  Future<void> _incrementAndFetchViews() async {
    final episodeId = "${widget.anime.title}_${widget.seasonIndex}_${widget.episodeIndex}";
    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      final userView = await Supabase.instance.client
          .from('user_views')
          .select()
          .eq('user_id', userId)
          .eq('episode_id', episodeId)
          .maybeSingle();

      if (userView == null) {
        await Supabase.instance.client.from('user_views').insert({
          'user_id': userId,
          'episode_id': episodeId,
        });

        final response = await Supabase.instance.client
            .from('episode_views')
            .select('view_count')
            .eq('episode_id', episodeId)
            .maybeSingle();

        int currentViews = response?['view_count'] ?? 0;
        int newViews = currentViews + 1;

        await Supabase.instance.client.from('episode_views').upsert({
          'episode_id': episodeId,
          'view_count': newViews,
        });

        final currentMap = Map<String, int>.from(globalAnimeViewsNotifier.value);
        currentMap[widget.anime.title] = (currentMap[widget.anime.title] ?? 0) + 1;
        globalAnimeViewsNotifier.value = currentMap;

        if (mounted) setState(() => _currentViews = formatViewsCount(newViews));
      } else {
        final response = await Supabase.instance.client
            .from('episode_views')
            .select('view_count')
            .eq('episode_id', episodeId)
            .maybeSingle();
            
        int currentViews = response?['view_count'] ?? 0;
        if (mounted) setState(() => _currentViews = formatViewsCount(currentViews));
      }
    } catch (e) {
      print("Views error: $e");
    }
  }

  Future<void> _fetchLikesDislikes() async {
    final episodeId = "${widget.anime.title}_${widget.seasonIndex}_${widget.episodeIndex}";
    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      final likesData = await Supabase.instance.client
          .from('user_likes')
          .select('user_id')
          .eq('episode_id', episodeId)
          .eq('is_liked', true);
          
      final dislikesData = await Supabase.instance.client
          .from('user_likes')
          .select('user_id')
          .eq('episode_id', episodeId)
          .eq('is_disliked', true);

      final myStatus = await Supabase.instance.client
          .from('user_likes')
          .select('is_liked, is_disliked')
          .eq('episode_id', episodeId)
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _likesCount = likesData.length;
          _dislikesCount = dislikesData.length;
          _isLiked = myStatus?['is_liked'] ?? false;
          _isDisliked = myStatus?['is_disliked'] ?? false;
        });
      }
    } catch (e) {
      print("Error fetching likes/dislikes: $e");
    }
  }

  Future<void> _updateLikesDislikes(bool newLike, bool newDislike) async {
    final episodeId = "${widget.anime.title}_${widget.seasonIndex}_${widget.episodeIndex}";
    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
        await Supabase.instance.client.from('user_likes').upsert({
          'user_id': userId,
          'episode_id': episodeId,
          'is_liked': newLike,
          'is_disliked': newDislike,
        });

        final likesData = await Supabase.instance.client
            .from('user_likes')
            .select('user_id')
            .eq('episode_id', episodeId)
            .eq('is_liked', true);
            
        final dislikesData = await Supabase.instance.client
            .from('user_likes')
            .select('user_id')
            .eq('episode_id', episodeId)
            .eq('is_disliked', true);

        if (mounted) {
            setState(() {
                _likesCount = likesData.length;
                _dislikesCount = dislikesData.length;
            });
        }
    } catch (e) {
        print("Error updating content counts: $e");
    }
  }

  void _toggleLike() { 
    final newLike = !_isLiked;
    final newDislike = false;
    
    setState(() { 
      if (newLike) {
        _likesCount++;
        if (_isDisliked) _dislikesCount = max(0, _dislikesCount - 1);
      } else {
        _likesCount = max(0, _likesCount - 1);
      }
      _isLiked = newLike;
      _isDisliked = false;
    });
    
    _updateLikesDislikes(newLike, newDislike);
  }

  void _toggleDislike() { 
    final newLike = false;
    final newDislike = !_isDisliked;

    setState(() { 
      if (newDislike) {
        _dislikesCount++;
        if (_isLiked) _likesCount = max(0, _likesCount - 1);
      } else {
        _dislikesCount = max(0, _dislikesCount - 1);
      }
      _isDisliked = newDislike;
      _isLiked = false;
    });

    _updateLikesDislikes(newLike, newDislike);
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
    MyListService(Supabase.instance.client).saveMyList(currentUserEmail, list); 
    setState(() {}); 
  }

  String _formatDuration(Duration duration) { 
    String twoDigits(int n) => n.toString().padLeft(2, '0'); 
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}"; 
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor; 
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
            : Center(
                child: CircularProgressIndicator(color: primColor)
              ),
              
        if (_controller.value.isInitialized)
          Positioned(
            top: 20,
            left: 20,
            child: Opacity(
              opacity: 0.3,
              child: Text(
                "AnimeMX",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)]
                ),
              ),
            ),
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
                                  activeColor: primColor, 
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
                        style: TextStyle(color: primColor, fontSize: 14, fontWeight: FontWeight.bold)
                      ), 
                      const SizedBox(height: 4), 
                      Text(
                        widget.anime.title, 
                        style: const TextStyle(color: Colors.white70, fontSize: 12)
                      ), 
                      const SizedBox(height: 4), 
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentEpisode.title, 
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.visibility, color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Text(_currentViews, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ), 
                      const SizedBox(height: 20),
                      
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
                              child: AnimatedContainer( 
                                duration: const Duration(milliseconds: 150),
                                transform: Matrix4.identity()..scale(_isLiked ? 1.1 : 1.0),
                                child: Row(
                                  children:[
                                    Icon(_isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, color: _isLiked ? primColor : Colors.white, size: 22), 
                                    const SizedBox(width: 8), 
                                    Text(_likesCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))
                                  ]
                                )
                              )
                            ), 
                            Container(width: 1, height: 24, color: Colors.white24), 
                            GestureDetector(
                              onTap: _toggleDislike, 
                              child: AnimatedContainer( 
                                duration: const Duration(milliseconds: 150),
                                transform: Matrix4.identity()..scale(_isDisliked ? 1.1 : 1.0),
                                child: Row(
                                  children:[
                                    Icon(_isDisliked ? Icons.thumb_down : Icons.thumb_down_alt_outlined, color: _isDisliked ? primColor : Colors.white, size: 22), 
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
                                  Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: _isSaved ? primColor : Colors.white, size: 22), 
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
                                          style: TextStyle(color: primColor, fontWeight: FontWeight.bold, fontSize: 13)
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
// BROWSE (SEARCH) SCREEN 
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
    _fetchRecentSearches(); 
  }

  Future<void> _fetchRecentSearches() async {
    try {
      final response = await Supabase.instance.client
          .from('user_preferences')
          .select('recent_searches')
          .eq('email', currentUserEmail) 
          .maybeSingle();

      if (response != null && response['recent_searches'] != null) {
        setState(() {
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

  Future<void> _updateRecentSearchesInDb(String query) async {
    final newSearches = [...globalRecentSearches];
    if (newSearches.length > 5) newSearches.removeLast(); 
    if (!newSearches.contains(query)) newSearches.insert(0, query);
    
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
    if (query.isNotEmpty) {
      _updateRecentSearchesInDb(query); 
    }
  }

  void _submitSearch(String query) { 
    if (query.trim().isNotEmpty && !globalRecentSearches.contains(query.trim())) { 
      setState(() {
        globalRecentSearches.insert(0, query.trim());
      }); 
      _updateRecentSearchesInDb(query.trim()); 
    } 
    _performSearch(query); 
  }

  void _removeRecentSearch(int index) {
    setState(() {
      globalRecentSearches.removeAt(index);
    });
    _updateRecentSearchesInDb(globalRecentSearches.join(',')); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Container(
                decoration: BoxDecoration(
                  color: getCard(context), 
                  borderRadius: BorderRadius.circular(12)
                ), 
                child: TextField(
                  controller: _searchController, 
                  onChanged: _performSearch, 
                  onSubmitted: _submitSearch, 
                  style: TextStyle(color: getText(context)), 
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: getText(context))
                ), 
                const SizedBox(height: 12), 
                if (_searchResults.isEmpty) 
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 20), 
                      child: Text("No anime found.", style: TextStyle(color: Colors.grey))
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
                Text(
                  "Recent Searches", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: getText(context))
                ), 
                const SizedBox(height: 12), 
                _isLoadingSearches
                    ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                    : (globalRecentSearches.isEmpty) 
                        ? const Text("No recent searches.", style: TextStyle(color: Colors.grey)) 
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
          color: getCard(context), 
          borderRadius: BorderRadius.circular(10)
        ), 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children:[
            Expanded( 
              child: Text(
                title, 
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: getText(context)),
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
// DUBS SCREEN 
// ==========================================
class DubsScreen extends StatelessWidget {
  const DubsScreen({super.key}); 

  @override 
  Widget build(BuildContext context) { 
    Color primColor = Theme.of(context).primaryColor;
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: getBg(context), 
        appBar: AppBar(
          backgroundColor: getBg(context), 
          elevation: 0, 
          toolbarHeight: 10, 
          bottom: TabBar(
            indicatorColor: primColor, 
            indicatorWeight: 3, 
            labelColor: primColor, 
            unselectedLabelColor: Colors.grey, 
            tabs: const [
              Tab(text: "DUBBED"), 
              Tab(text: "ORIGINAL")
            ]
          )
        ), 
        body: TabBarView(
          children:[
            GridView.builder(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100), 
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 14, mainAxisSpacing: 16), 
              itemCount: animeData.length, 
              itemBuilder: (context, index) {
                final anime = animeData[index];
                if (anime.dubStatus == "DUB" || anime.dubStatus == "MIX") {
                  return GridCategoryCard(anime: anime, pageTitle: "DUB"); 
                }
                return const SizedBox.shrink();
              }
            ), 
            GridView.builder(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100), 
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 14, mainAxisSpacing: 16), 
              itemCount: animeData.length, 
              itemBuilder: (context, index) {
                final anime = animeData[index];
                if (anime.dubStatus == "ORIGINAL" || anime.dubStatus == "MIX") {
                  return GridCategoryCard(anime: anime, pageTitle: "ORIGINAL"); 
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
// MY LIST SCREEN
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

  Future<void> _fetchSavedAnime() async {
    try {
      final response = await Supabase.instance.client
          .from('user_preferences')
          .select('saved_anime')
          .eq('email', currentUserEmail) 
          .maybeSingle();

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
      backgroundColor: getBg(context),
      appBar: AppBar(
        title: Text("My List", style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: getBg(context),
        elevation: 0,
      ),
      body: _isLoadingSavedAnime
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : ValueListenableBuilder<List<SavedEpisode>>(
              valueListenable: myListNotifier,
              builder: (context, savedList, child) {
                if (savedList.isEmpty) {
                  return Center(
                    child: Text(
                      "Your watch list is empty.", 
                      style: TextStyle(color: getSubText(context), fontSize: 16)
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
// PROFILE SCREEN
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key}); 

  Widget _buildMenuGroup(List<Widget> items, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: getCard(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget item = entry.value;
          if (idx == items.length - 1) return item;
          return Column(
            children: [
              item,
              const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16), 
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGroupedItem({required String title, required VoidCallback onTap, String? trailingText, Color? trailingColor, BuildContext? context}) {
    return Material(
      color: Colors.transparent, 
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: getText(context!), fontSize: 16, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  if (trailingText != null) ...[
                    Text(trailingText, style: TextStyle(color: trailingColor ?? getSubText(context), fontSize: 15)),
                    const SizedBox(width: 8),
                  ],
                  Icon(Icons.arrow_forward_ios, color: getSubText(context).withOpacity(0.5), size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(
        title: Text("My Account", style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: getBg(context),
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 24, top: 10),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: getAvatarColor(currentUserName),
                      child: Text(
                        getAvatarLetter(currentUserName),
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(currentUserName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: userActivePlan.isEmpty ? Colors.white12 : Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        userActivePlan.isEmpty ? "FREE PLAN" : userActivePlan.toUpperCase(), 
                        style: TextStyle(color: userActivePlan.isEmpty ? Colors.white70 : Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text("Account", style: TextStyle(color: getSubText(context), fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              _buildMenuGroup([
                _buildGroupedItem(
                  context: context,
                  title: "Subscription", 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())), 
                  trailingText: userActivePlan.isEmpty ? "Upgrade" : userActivePlan, 
                  trailingColor: Theme.of(context).primaryColor
                ),
                _buildGroupedItem(
                  context: context,
                  title: "Notifications", 
                  onTap: () {}, 
                  trailingText: "On"
                ),
                _buildGroupedItem(
                  context: context,
                  title: "Email & Password", 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordPage())), 
                ),
                _buildGroupedItem(
                  context: context,
                  title: "App Theme", 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemeSettingsPage())), 
                  trailingText: "Customize", 
                ),
              ], context),

              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text("Payments", style: TextStyle(color: getSubText(context), fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              _buildMenuGroup([
                _buildGroupedItem(
                  context: context,
                  title: "Payment Verification", 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentProofPage())), 
                ),
                _buildGroupedItem(
                  context: context,
                  title: "Order History", 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityPage())), 
                ),
              ], context),

              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text("Support", style: TextStyle(color: getSubText(context), fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              _buildMenuGroup([
                _buildGroupedItem(
                  context: context,
                  title: "Support Center", 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportPage())), 
                ),
              ], context),

              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                   await Supabase.instance.client.auth.signOut();
                }, 
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: getCard(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text("Log Out", textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// CHANGE PASSWORD PAGE
// ==========================================
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    if (_newPassController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password must be at least 6 characters")));
      return;
    }
    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPassController.text.trim()),
      );
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password changed successfully!")));
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(
        title: Text("Change Password", style: TextStyle(color: getText(context))),
        backgroundColor: getBg(context),
        iconTheme: IconThemeData(color: getText(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Create New Password", style: TextStyle(color: getText(context), fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Your new password must be different from previous used passwords.", style: TextStyle(color: getSubText(context))),
            const SizedBox(height: 30),
            
            TextField(
              controller: _newPassController,
              obscureText: true,
              style: TextStyle(color: getText(context)),
              decoration: InputDecoration(
                hintText: "New Password",
                hintStyle: TextStyle(color: getSubText(context)),
                filled: true,
                fillColor: getCard(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primColor, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPassController,
              obscureText: true,
              style: TextStyle(color: getText(context)),
              decoration: InputDecoration(
                hintText: "Confirm Password",
                hintStyle: TextStyle(color: getSubText(context)),
                filled: true,
                fillColor: getCard(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primColor, width: 2)),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _isLoading ? null : _updatePassword,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Password", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// THEME SETTINGS PAGE 
// ==========================================
class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(
        title: Text("App Theme", style: TextStyle(color: getText(context))),
        backgroundColor: getBg(context),
        iconTheme: IconThemeData(color: getText(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Accent Color", style: TextStyle(color: getText(context), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: [
                _buildColorOption(animeMxPurple, "AnimeMX", context), 
                _buildColorOption(Colors.red, "Red", context),
                _buildColorOption(Colors.blue, "Blue", context),
                _buildColorOption(Colors.green, "Green", context),
                _buildColorOption(Colors.orange, "Orange", context),
                _buildColorOption(Colors.pink, "Pink", context),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color, String name, BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: primaryColorNotifier,
      builder: (context, currentColor, _) {
        bool isSelected = currentColor == color;
        return GestureDetector(
          onTap: () => primaryColorNotifier.value = color,
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? getText(context) : Colors.transparent, width: 3),
                  boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)] : []
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
              ),
              const SizedBox(height: 5),
              Text(name, style: TextStyle(color: getSubText(context), fontSize: 12))
            ],
          ),
        );
      }
    );
  }
}

// ==========================================
// PLACEHOLDER PAGES FOR MENU OPTIONS
// ==========================================
class PrivacyPolicyPage extends StatelessWidget { 
  const PrivacyPolicyPage({super.key});

  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      backgroundColor: getBg(context), 
      appBar: AppBar(
        title: Text("Privacy Policy", style: TextStyle(color: getText(context))), 
        backgroundColor: getBg(context), 
        iconTheme: IconThemeData(color: getText(context))
      ), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16), 
        child: Text(
          "Privacy Policy\n\nWelcome to AnimeMX. At AnimeMX, we value your privacy. This Privacy Policy outlines how we collect, use, and protect your data.\n\nWe do not sell your personal data to third parties. All user preferences, including recent searches and saved episodes, are stored locally on your device unless connected via cloud synchronization. For more details, please contact our support team.", 
          style: TextStyle(color: getSubText(context), fontSize: 14, height: 1.5)
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
      backgroundColor: getBg(context), 
      appBar: AppBar(
        title: Text("About Us", style: TextStyle(color: getText(context))), 
        backgroundColor: getBg(context), 
        iconTheme: IconThemeData(color: getText(context))
      ), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text("About AnimeMX", style: TextStyle(color: getText(context), fontSize: 20, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 12), 
            Text(
              "Welcome to AnimeMX, your ultimate destination for streaming the best and latest anime! Our mission is to provide an ad-free, high-quality, and seamless viewing experience for anime lovers around the world.\n\nWe offer dubbed anime in Hindi, English, and Japanese languages. Enjoy HD & 4K quality, dubbed & subbed versions, and lightning-fast streaming anywhere, anytime.", 
              style: TextStyle(color: getSubText(context), fontSize: 14, height: 1.5)
            ), 
            const SizedBox(height: 30), 
            Text("Contact Us", style: TextStyle(color: getText(context), fontSize: 20, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 12), 
            Text("Email: animemx.official@gmail.com", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14, fontWeight: FontWeight.bold))
          ]
        )
      ),
    ); 
  } 
}

// ==========================================
// UPDATED PREMIUM PAGE WITH NEW PLANS
// ==========================================
class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBg(context), 
      appBar: AppBar(
        title: Text("Upgrade Plan", style: TextStyle(fontWeight: FontWeight.bold, color: getText(context))), 
        backgroundColor: getBg(context), 
        iconTheme: IconThemeData(color: getText(context))
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
                children: [
                  Text("Choose Your Plan", style: TextStyle(color: getText(context), fontSize: 28, fontWeight: FontWeight.bold)), 
                  const SizedBox(height: 8), 
                  Text("Unlock premium features and an ad-free experience.", style: TextStyle(color: getSubText(context), fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              height: 400, 
              child: ListView(
                scrollDirection: Axis.horizontal, 
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildNewPlanCard(
                    context: context, 
                    title: "Basic Plan", 
                    price: "55", 
                    quality: "720p", 
                    ads: "No", 
                    slot: "1", 
                    earlyAccess: "No", 
                    support: "24/7 support",
                    color: Colors.blue.shade800,
                  ), 
                  const SizedBox(width: 16),
                  
                  _buildNewPlanCard(
                    context: context, 
                    title: "Standard Plan", 
                    price: "99", 
                    quality: "720p", 
                    ads: "No", 
                    slot: "3", 
                    earlyAccess: "Yes", 
                    support: "24/7 support",
                    color: Colors.deepOrange.shade800,
                  ), 
                  const SizedBox(width: 16),
                  
                  _buildNewPlanCard(
                    context: context, 
                    title: "Elite Plan", 
                    price: "149", 
                    quality: "1080p", 
                    ads: "No", 
                    slot: "7", 
                    earlyAccess: "Yes", 
                    support: "24/7 support",
                    color: Colors.purple.shade800,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            
            // Detailed Information Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Why go Premium?", style: TextStyle(color: getText(context), fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInfoRow(context, Icons.block, "Ad-Free Streaming", "Enjoy anime without any annoying interruptions."),
                  _buildInfoRow(context, Icons.hd, "High Quality Video", "Watch your favorite shows in crystal clear 720p and 1080p."),
                  _buildInfoRow(context, Icons.timer, "Early Access", "Watch new episodes before they are available to free users."),
                  _buildInfoRow(context, Icons.devices, "Multiple Devices", "Share your account with friends and family on multiple slots."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: getText(context), fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: getSubText(context), fontSize: 13, height: 1.4)),
              ],
            ),
          )
        ],
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
    required String earlyAccess,
    required String support,
    required Color color, 
  }) {
    return Container(
      width: 270, 
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [getCard(context), color.withOpacity(0.2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: color.withOpacity(0.5), width: 1.5), 
      ), 
      padding: const EdgeInsets.all(20), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(title.toUpperCase(), style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)), 
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline, 
            textBaseline: TextBaseline.alphabetic, 
            children: [
              Text("₹$price", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)), 
              const Text("/month", style: TextStyle(color: Colors.white54, fontSize: 14))
            ]
          ),
          const SizedBox(height: 20), 
          const Divider(color: Colors.white12, height: 1), 
          const SizedBox(height: 20), 
          
          _buildGridRow("Quality", quality, Icons.tv), 
          _buildGridRow("Ads", ads, Icons.block), 
          _buildGridRow("Early Access", earlyAccess, Icons.timelapse), 
          _buildGridRow("Device Slot", slot, Icons.devices), 
          _buildGridRow("Support", support, Icons.headset_mic), 
          
          const Spacer(), 
          
          GestureDetector(
            onTap: () { 
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QRCodePaymentPage(planName: title, price: price)),
              );
            }, 
            child: Container(
              height: 45, 
              alignment: Alignment.center, 
              decoration: BoxDecoration(
                color: color, 
                borderRadius: BorderRadius.circular(10)
              ), 
              child: const Text("Choose Plan", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
            )
          )
        ],
      ),
    );
  }
  
  Widget _buildGridRow(String feature, String value, IconData icon) { 
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), 
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Text(feature, style: const TextStyle(color: Colors.white70, fontSize: 14)), 
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
        ]
      )
    ); 
  }
}

// ==========================================
// NEW QR CODE PAYMENT PAGE (WITH UPI BUTTON)
// ==========================================
class QRCodePaymentPage extends StatelessWidget {
  final String planName;
  final String price;

  const QRCodePaymentPage({super.key, required this.planName, required this.price});

  void _launchUPIApp(BuildContext context) async {
    String cleanPrice = price.replaceAll("₹", "");
    final Uri uri = Uri.parse("upi://pay?pa=wicvlox.i@oksbi&pn=AnimeMX&am=$cleanPrice&cu=INR&tn=Buy%20$planName");
    if (await canLaunchUrl(uri)) { 
      await launchUrl(uri, mode: LaunchMode.externalApplication); 
    } else { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No UPI App found on this device!"))); 
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    
    // Fixed Custom QR Image provided by User
    String qrImageUrl = "https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEh4wZ-2FEPEhofbqHtjDJ4fSwQUBK2iiyRtQAtikhZeAoQ1GSwBzWh1qfpaelzZWZBW7C_bTtNUdLDAGm8rK71pV4aJ65jRimqxADOR5m_EV6_lK2bI_Ok7R0PpXoDfaYKTn7VO-_a9pfkhjQj_IrZlGfBiP4TFe-2yBab3wE3g8CV0_VLX9KyW5JfnL0s/s769/IMG_20260425_204423.webp";

    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(
        title: Text("Scan to Pay", style: TextStyle(color: getText(context))),
        backgroundColor: getBg(context),
        iconTheme: IconThemeData(color: getText(context)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Payment for $planName",
                style: TextStyle(color: getText(context), fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Amount to Pay: ₹$price",
                style: TextStyle(color: primColor, fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),
              
              // QR Code Display (Clean Shape)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: primColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
                  ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    qrImageUrl,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // UPI ID DISPLAY
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: getCard(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12)
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("UPI ID", style: TextStyle(color: getSubText(context), fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text("wicvlox.i@oksbi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              
              // PAY NOW BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // specified color 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: () => _launchUPIApp(context),
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: const Text("Pay Now", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 40),
              
              // ENGLISH INSTRUCTIONS
              Text(
                "Scan the QR Code or click Pay Now.",
                style: TextStyle(color: getText(context), fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "After successful payment, click below to submit your payment screenshot and plan details for verification.",
                style: TextStyle(color: getSubText(context), fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primColor, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => PaymentProofPage(initialPlan: "$planName - ₹$price/mo")),
                    );
                  },
                  child: const Text("Go to Verification Page", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PAYMENT PROOF PAGE (UPDATED VALIDATION & TOAST)
// ==========================================
class PaymentProofPage extends StatefulWidget {
  final String? initialPlan;
  const PaymentProofPage({super.key, this.initialPlan});

  @override 
  State<PaymentProofPage> createState() => _PaymentProofPageState();
}

class _PaymentProofPageState extends State<PaymentProofPage> {
  String? _selectedPlan;
  File? _imageFile;
  final TextEditingController _trxController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _plans = [
    "Basic Plan - ₹55/mo",
    "Standard Plan - ₹99/mo",
    "Elite Plan - ₹149/mo"
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPlan != null && _plans.contains(widget.initialPlan)) {
      _selectedPlan = widget.initialPlan;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showFloatingToast() {
    OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0,
        left: 16.0,
        right: 16.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), 
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15.0,
                  offset: const Offset(0, 5),
                )
              ]
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECA71), 
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 24, weight: 700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Payment proof submitted!", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("It will be approved within 24 hours.", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.close, color: Colors.white54, size: 20),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
      if(mounted) {
        Navigator.pop(context); 
      }
    });
  }

  Future<void> _submitRequest() async {
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a plan.")));
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload a payment screenshot.")));
      return;
    }
    
    // TRANSACTION ID 12-DIGIT VALIDATION (ONLY NUMBERS)
    String trxId = _trxController.text.trim();
    if (trxId.length != 12 || !RegExp(r'^[0-9]+$').hasMatch(trxId)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid 12-digit number.")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String imageUrl = "No URL (RLS issue)";
      
      try {
        final pathParts = _imageFile!.path.split('.');
        final ext = pathParts.length > 1 ? pathParts.last : 'jpg'; 
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        
        await Supabase.instance.client.storage
            .from('payment_proofs')
            .upload(fileName, _imageFile!, fileOptions: const FileOptions(cacheControl: '3600', upsert: false));
            
        imageUrl = Supabase.instance.client.storage
            .from('payment_proofs')
            .getPublicUrl(fileName);
            
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Storage Upload Error: Make sure Storage RLS is disabled/configured. Details: $e")));
        }
        setState(() => _isSubmitting = false);
        return; 
      }

      try {
        await Supabase.instance.client.from('payment_requests').insert({
          'email': currentUserEmail,
          'plan': _selectedPlan,
          'transaction_id': trxId,
          'image_path': imageUrl,
          'status': 'Pending',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Database Error: Make sure Table RLS is configured. Details: $e")));
        }
        setState(() => _isSubmitting = false);
        return;
      }

      if (mounted) {
        _showFloatingToast(); 
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("An unexpected error occurred: ${e.toString()}"),
          duration: const Duration(seconds: 5),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _trxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: getBg(context), 
      appBar: AppBar(
        title: Text("Verify Payment", style: TextStyle(color: getText(context))), 
        backgroundColor: getBg(context), 
        iconTheme: IconThemeData(color: getText(context))
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Container(
              padding: const EdgeInsets.all(15), 
              decoration: BoxDecoration(color: primColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: primColor.withOpacity(0.3))), 
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primColor), 
                  const SizedBox(width: 10), 
                  Expanded(
                    child: Text("Provide your payment details below to instantly activate your plan.", style: TextStyle(color: primColor, fontSize: 13))
                  )
                ]
              )
            ),
            const SizedBox(height: 30), 
            
            Text("Select Plan", style: TextStyle(color: getText(context), fontSize: 16, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: getCard(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12)
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: getCard(context),
                  hint: Text("Choose your purchased plan", style: TextStyle(color: getSubText(context))),
                  value: _selectedPlan,
                  icon: Icon(Icons.arrow_drop_down, color: getSubText(context)),
                  style: TextStyle(color: getText(context), fontSize: 15),
                  items: _plans.map((String plan) {
                    return DropdownMenuItem<String>(
                      value: plan,
                      child: Text(plan),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPlan = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text("Payment Screenshot", style: TextStyle(color: getText(context), fontSize: 16, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: getCard(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12, style: BorderStyle.solid),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, color: primColor, size: 40),
                          const SizedBox(height: 10),
                          Text("Tap to upload screenshot", style: TextStyle(color: getSubText(context), fontSize: 14)),
                          const SizedBox(height: 4),
                          Text("(JPG, PNG allowed)", style: TextStyle(color: getSubText(context).withOpacity(0.5), fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            Text("Transaction ID (UTR)", style: TextStyle(color: getText(context), fontSize: 16, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 10),
            TextField(
              controller: _trxController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12), 
              ],
              style: TextStyle(color: getText(context)),
              decoration: InputDecoration(
                hintText: "Enter 12-digit UTR number",
                hintStyle: TextStyle(color: getSubText(context), fontSize: 14),
                prefixIcon: Icon(Icons.tag, color: primColor),
                filled: true,
                fillColor: getCard(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primColor),
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity, 
              height: 50, 
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primColor, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ), 
                onPressed: _isSubmitting ? null : _submitRequest, 
                child: _isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Submit Proof", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              )
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
      backgroundColor: getBg(context), 
      appBar: AppBar(
        title: Text("Help Center", style: TextStyle(color: getText(context))), 
        backgroundColor: getBg(context), 
        iconTheme: IconThemeData(color: getText(context))
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
                gradient: LinearGradient(colors:[Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)])
              ), 
              child: Row(
                children:[
                  Container(
                    padding: const EdgeInsets.all(10), 
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), 
                    child: const Icon(Icons.headset_mic, color: Colors.white, size: 30)
                  ), 
                  const SizedBox(width: 15), 
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: const [
                        Text("How can we help?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), 
                        Text("We're here to help you with any issues.", style: TextStyle(color: Colors.white70, fontSize: 12))
                      ]
                    )
                  )
                ]
              )
            ), 
            const SizedBox(height: 30), 
            Text("Contact Options", style: TextStyle(color: getText(context), fontSize: 18, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 16), 
            
            _buildSupportTile(
              Icons.telegram, 
              "Telegram", 
              "Instant Chat Support", 
              Colors.blueAccent, 
              context,
              onTap: () => launchTelegram("+918987927874"), 
            ), 
            _buildSupportTile(
              Icons.chat, 
              "WhatsApp", 
              "Chat Support", 
              Colors.green, 
              context,
              onTap: () => launchWhatsApp("+918987927874"), 
            ), 
            _buildSupportTile(
              Icons.email, 
              "Email", 
              "24-hour Response", 
              Colors.orangeAccent, 
              context,
              onTap: () => launchInBrowser("mailto:animemx.official@gmail.com"), 
            ),

            const SizedBox(height: 30),
            Text("Frequently Asked Questions", style: TextStyle(color: getText(context), fontSize: 18, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 16), 
            
            _buildFaqItem(context, "How do I activate my Premium Plan?", "After scanning the QR code and making the payment, submit your 12-digit UTR in the Payment Verification page. Your account will be upgraded within 24 hours."),
            _buildFaqItem(context, "What is Early Access?", "Early Access allows Premium users to watch the latest episodes immediately as they are released, before free users."),
            _buildFaqItem(context, "How many devices can I use?", "Basic Plan allows 1 device, Standard allows 3 devices, and Elite allows up to 7 devices simultaneously."),
          ]
        )
      ), 
    ); 
  }
  
  Widget _buildSupportTile(IconData icon, String title, String sub, Color color, BuildContext context, {required VoidCallback onTap}) { 
    return Container(
      margin: const EdgeInsets.only(bottom: 12), 
      child: Material(
        color: getCard(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12), 
            child: Row(
              children:[
                Container(
                  padding: const EdgeInsets.all(10), 
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), 
                  child: Icon(icon, color: color)
                ), 
                const SizedBox(width: 15), 
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children:[
                      Text(title, style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 16)), 
                      Text(sub, style: TextStyle(color: getSubText(context), fontSize: 12))
                    ]
                  )
                ), 
                Icon(Icons.arrow_forward_ios, color: getSubText(context).withOpacity(0.5), size: 16)
              ]
            ),
          ),
        ),
      ),
    ); 
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getCard(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(answer, style: TextStyle(color: getSubText(context), fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

// ==========================================
// ACTIVITY PAGE (FETCHES DATA FROM SUPABASE)
// ==========================================
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override 
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  List<OrderItem> _fetchedOrders = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final response = await Supabase.instance.client
          .from('payment_requests')
          .select()
          .eq('email', currentUserEmail) 
          .order('created_at', ascending: false)
          .limit(10); 

      if (response != null && response.isNotEmpty) {
        final List<OrderItem> fetchedList = [];
        for (var data in response) {
          String fullPlanName = data['plan'] ?? 'N/A';
          List<String> planParts = fullPlanName.split(' - ');
          String planNameOnly = planParts.length > 0 ? planParts[0] : fullPlanName;
          String priceOnly = planParts.length > 1 ? planParts[1] : '₹0';

          fetchedList.add(OrderItem(
            planName: planNameOnly,
            amount: priceOnly,
            status: data['status'] ?? 'Pending',
            date: data['created_at'] != null ? data['created_at'].substring(0, 10) : 'N/A', 
          ));
        }
        setState(() {
          _fetchedOrders = fetchedList;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }

    } catch (e) {
      print("Error fetching orders: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBg(context), 
      appBar: AppBar(
        title: Text("Order History", style: TextStyle(color: getText(context))), 
        backgroundColor: getBg(context), 
        iconTheme: IconThemeData(color: getText(context))
      ), 
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
        : _fetchedOrders.isEmpty 
          ? Center(child: Text("No recent activity.", style: TextStyle(color: getSubText(context)))) 
          : ListView.builder(
              padding: const EdgeInsets.all(16), 
              itemCount: _fetchedOrders.length, 
              itemBuilder: (context, index) { 
                final item = _fetchedOrders[index]; 
                Color statusColor; 
                if (item.status == "Verified" || item.status == "Approved") {
                  statusColor = Colors.green;
                } else if (item.status == "Pending") {
                  statusColor = Colors.orange;
                } else {
                  statusColor = Colors.redAccent;
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 12), 
                  padding: const EdgeInsets.all(16), 
                  decoration: BoxDecoration(
                    color: getCard(context), 
                    borderRadius: BorderRadius.circular(12)
                  ), 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children:[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children:[
                          Text(item.planName, style: TextStyle(color: getText(context), fontSize: 16, fontWeight: FontWeight.bold)), 
                          const SizedBox(height: 4), 
                          Text(item.date, style: TextStyle(color: getSubText(context), fontSize: 12))
                        ]
                      ), 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end, 
                        children:[
                          Text(item.amount, style: TextStyle(color: getText(context), fontSize: 16, fontWeight: FontWeight.bold)), 
                          const SizedBox(height: 4), 
                          Text(item.status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold))
                        ]
                      )
                    ]
                  )
                ); 
              }
            )
    ); 
  }
}