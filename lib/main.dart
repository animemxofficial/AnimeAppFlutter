import 'dart:io'; 
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';

// ==========================================
// APP VERSION FOR OTA UPDATES
// ==========================================
const String CURRENT_APP_VERSION = "1.0.1"; 

// ==========================================
// DATA MODELS & GLOBAL STATE
// ==========================================
String currentDeviceId = "";
String currentUserName = "User"; 
bool hasAcceptedCookies = false; 

String globalWebsiteUrl = "https://google.com"; 

String globalTelegramLink = "";

String globalPrivacyPolicy = "At SYNEX MX, your privacy and security are our highest priorities. We are fully committed to providing a safe streaming experience for both Anime and Movies without compromising your personal data.\n\nData Security & Storage\nWe utilize encryption to protect your hardware identifiers. All your personal preferences—such as your watch history, recent searches, and saved items—are securely synchronized to your device.\n\nContent Information\nSYNEX MX provides a vast library of Anime and Movies. To ensure fast and consistent releases, a large portion of our dubbed content is powered by high-quality AI Dubbing technology, alongside our Original dubs.\n\nHardware Tracking\nSYNEX MX securely scans and hashes your device's hardware ID to keep your account safe without needing passwords.";

List<String> globalRecentSearches = [];
List<String> recommendedSearches = ["Naruto", "One Piece", "Solo Leveling", "Action", "Romance", "Demon Slayer", "Jujutsu Kaisen", "Movie"];

final ValueNotifier<List<Anime>> animeListNotifier = ValueNotifier([]);
final ValueNotifier<List<Map<String, dynamic>>> heroSliderNotifier = ValueNotifier([]);
final ValueNotifier<List<CWItem>> continueWatchingNotifier = ValueNotifier([]);
final ValueNotifier<List<SavedEpisode>> myListNotifier = ValueNotifier([]);
final ValueNotifier<Map<String, int>> globalAnimeViewsNotifier = ValueNotifier({});

const Color animeMxPurple = Color(0xFF8A2BE2); 
final ValueNotifier<Color> primaryColorNotifier = ValueNotifier(animeMxPurple); 

Color getBg(BuildContext context) => Colors.black;
Color getCard(BuildContext context) => const Color(0xFF1A1A1A);
Color getText(BuildContext context) => Colors.white;
Color getSubText(BuildContext context) => Colors.white54;

final List<Color> avatarColors = [Colors.redAccent, Colors.blueAccent, Colors.green, Colors.purpleAccent, Colors.teal, Colors.orange, Colors.pinkAccent, Colors.indigo];

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
    final response = await Supabase.instance.client.from('episode_views').select('episode_id, view_count');
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
  } catch (e) { }
}

Future<String> getHardwareDeviceId() async {
  try {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return "${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}".replaceAll(' ', ''); 
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return "${iosInfo.name}_${iosInfo.identifierForVendor}".replaceAll(' ', '');
    }
  } catch (e) {}
  return const Uuid().v4(); 
}

// ==========================================
// SUPABASE DATA PERSISTENCE SERVICES
// ==========================================
class CWService {
  Future<void> saveCWList(String devId, List<CWItem> cwList) async {
    final savedData = cwList.map((item) => item.toJson()).toList();
    try {
      await Supabase.instance.client.from('user_preferences').upsert({'device_id': devId, 'continue_watching': savedData}, onConflict: 'device_id');
    } catch (e) {}
  }
}

class RecentSearchesService {
  Future<void> saveRecentSearches(String devId, List<String> searches) async {
    final newSearches = [...searches];
    if (newSearches.length > 5) newSearches.removeLast(); 
    final searchesJson = jsonEncode(newSearches);
    try {
      await Supabase.instance.client.from('user_preferences').upsert({'device_id': devId, 'recent_searches': searchesJson}, onConflict: 'device_id');
    } catch (e) {}
  }
}

class MyListService {
  Future<void> saveMyList(String devId, List<SavedEpisode> savedList) async {
    final savedData = savedList.map((item) => item.toJson()).toList();
    try {
      await Supabase.instance.client.from('user_preferences').upsert({'device_id': devId, 'saved_anime': savedData}, onConflict: 'device_id');
    } catch (e) {}
  }
}

// ==========================================
// DATA MODELS
// ==========================================
class CWItem {
  final Anime anime;
  int seasonIndex;
  int episodeIndex;
  Duration position;
  Duration totalDuration;

  CWItem({required this.anime, required this.seasonIndex, required this.episodeIndex, required this.position, required this.totalDuration});
  
  Map<String, dynamic> toJson() => {
    'animeTitle': anime.title, 
    'seasonIndex': seasonIndex, 
    'episodeIndex': episodeIndex, 
    'positionInSeconds': position.inSeconds, 
    'totalDurationInSeconds': totalDuration.inSeconds
  };
  
  static CWItem fromJson(Map<String, dynamic> json, List<Anime> allAnime) {
    try {
      final animeMatch = allAnime.firstWhere((anime) => anime.title == json['animeTitle']);
      return CWItem(anime: animeMatch, seasonIndex: json['seasonIndex'], episodeIndex: json['episodeIndex'], position: Duration(seconds: json['positionInSeconds']), totalDuration: Duration(seconds: json['totalDurationInSeconds']));
    } catch (e) {
      return CWItem(anime: allAnime.isNotEmpty ? allAnime[0] : _getDummyAnime(), seasonIndex: 0, episodeIndex: 0, position: Duration(seconds: json['positionInSeconds'] ?? 0), totalDuration: Duration(seconds: json['totalDurationInSeconds'] ?? 0));
    }
  }
}

class SavedEpisode {
  final Anime anime;
  final int seasonIndex;
  final int episodeIndex;
  SavedEpisode({required this.anime, required this.seasonIndex, required this.episodeIndex});
  Map<String, dynamic> toJson() => {'animeTitle': anime.title, 'seasonIndex': seasonIndex, 'episodeIndex': episodeIndex};
}

class Episode {
  final String id;
  final String title;
  final String image;
  final String duration;
  final String views;
  final String videoUrl;
  final DateTime createdAt;
  Episode({required this.id, required this.title, required this.image, required this.duration, this.views = "0", required this.videoUrl, required this.createdAt});
}

class Season {
  final String id;
  final String name;
  final List<Episode> episodes;
  Season({required this.id, required this.name, required this.episodes});
}

class Anime {
  final String id;
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
  final String category;
  final String subCategory;
  final bool isNew; 
  final String description; 
  final DateTime createdAt; 

  Anime({
    required this.id, required this.title, required this.image, this.genre = "Action", this.rating = "PG-13", this.dubStatus = "DUB", 
    this.season = "Season 1", this.status = "Ongoing", this.views = "0", this.dubColor = const Color(0xFFFF4D4D), 
    required this.seasonsList, this.category = "", this.subCategory = "", this.isNew = false, this.description = "",
    required this.createdAt,
  });
}

Anime _getDummyAnime() => Anime(id: '0', title: 'Loading...', image: '', seasonsList: [], createdAt: DateTime.now());

class LatestEpisodeItem {
  final Anime anime;
  final int seasonIndex;
  final int episodeIndex;
  final Episode episode;
  LatestEpisodeItem({required this.anime, required this.seasonIndex, required this.episodeIndex, required this.episode});
}

// ==========================================
// MAIN ENTRY POINT
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yngzfgfpyufusrbitagl.supabase.co',          
    anonKey: 'sb_publishable_6BD0moEpOnUTfihbRUpdOQ_U2gJCH5U', 
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  
  runApp(const SynexDubApp());
}

Future<void> launchInBrowser(String url) async {
  if (url.isEmpty) return;
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {}
}

// ==========================================
// ROOT APP
// ==========================================
class SynexDubApp extends StatelessWidget {
  const SynexDubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: primaryColorNotifier,
      builder: (context, currentColor, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          title: "SYNEX MX",
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: currentColor,
            scaffoldBackgroundColor: Colors.black,
            useMaterial3: true,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white),
          ),
          home: const DeviceTrackingGate(), 
        );
      }
    );
  }
}

// ==========================================
// DEVICE TRACKING GATE (AUTO LOGIN)
// ==========================================
class DeviceTrackingGate extends StatefulWidget {
  const DeviceTrackingGate({super.key});

  @override
  State<DeviceTrackingGate> createState() => _DeviceTrackingGateState();
}

class _DeviceTrackingGateState extends State<DeviceTrackingGate> {
  @override
  void initState() {
    super.initState();
    _checkDevice();
  }

  Future<void> _checkDevice() async {
    currentDeviceId = await getHardwareDeviceId();
    
    try {
      final response = await Supabase.instance.client.from('device_users').select().eq('device_id', currentDeviceId).maybeSingle();
      
      if (response != null && mounted) {
        currentUserName = "${response['first_name']} ${response['last_name']}".trim();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
      } else {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NameEntryScreen()));
      }
    } catch (e) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NameEntryScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(text: const TextSpan(children: [
              TextSpan(text: "SYNEX ", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)), 
              TextSpan(text: "MX", style: TextStyle(color: Color(0xFF8A2BE2), fontSize: 48, fontWeight: FontWeight.w900))
            ])),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Color(0xFF8A2BE2)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// NAME ENTRY SCREEN
// ==========================================
class NameEntryScreen extends StatefulWidget {
  const NameEntryScreen({super.key});

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveName() async {
    if (_firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("First Name is required!")));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('device_users').insert({
        'device_id': currentDeviceId,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim()
      });
      
      currentUserName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}".trim();
      
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error saving profile. Try again.")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_pin, color: Color(0xFF8A2BE2), size: 100),
              const SizedBox(height: 20),
              RichText(text: const TextSpan(children: [
                TextSpan(text: "SYNEX ", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 1.2)), 
                TextSpan(text: "MX", style: TextStyle(color: Color(0xFF8A2BE2), fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 1.2))
              ])),
              const SizedBox(height: 10),
              const Text("Welcome! Let's get to know you.", style: TextStyle(color: Colors.white54, fontSize: 16)),
              const SizedBox(height: 40),
              
              TextField(
                controller: _firstNameController, style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(hintText: "First Name", hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF0F0F13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(20)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController, style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(hintText: "Last Name (Optional)", hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF0F0F13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(20)),
              ),
              const SizedBox(height: 40),
              
              Container(
                width: double.infinity, height: 60,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFF6B21A8)])),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                  onPressed: _isLoading ? null : _saveName,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ENTER APP", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
// MAIN SCREEN & DATABASE LOADER
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  bool _isDataLoading = true;
  RealtimeChannel? _presenceChannel;

  @override
  void initState() {
    super.initState();
    _loadEverything();
    _initPresence(); 
  }

  void _initPresence() {
    _presenceChannel = Supabase.instance.client.channel('online-users');
    _presenceChannel?.subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _presenceChannel?.track({'user': currentDeviceId, 'online_at': DateTime.now().toIso8601String()});
      }
    });
  }

  @override
  void dispose() {
    _presenceChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadEverything() async {
    await _checkCookies(); 
    await _fetchSettings(); 
    await _checkForUpdates(context); 
    await fetchGlobalAnimeViews(); 
    await _fetchDatabaseCatalog();
    await _fetchUserPreferences(); 
    if(mounted) setState(() => _isDataLoading = false);
  }

  Future<void> _checkCookies() async {
    final prefs = await SharedPreferences.getInstance();
    bool accepted = prefs.getBool('cookies_accepted') ?? false;
    if (!accepted) {
      WidgetsBinding.instance.addPostFrameCallback((_) { _showCookieBanner(context); });
    } else { hasAcceptedCookies = true; }
  }

  void _showCookieBanner(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    showModalBottomSheet(
      context: context, isScrollControlled: true, isDismissible: false, enableDrag: false, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: getCard(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border.all(color: Colors.white12)),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.cookie, color: primColor, size: 32), const SizedBox(width: 12), const Text("Cookie Policy", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 20),
            const Text("We use cookies to improve your experience, personalize content, and analyze traffic.", style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(side: BorderSide(color: primColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)), onPressed: () async { final prefs = await SharedPreferences.getInstance(); await prefs.setBool('cookies_accepted', true); hasAcceptedCookies = true; Navigator.pop(context); }, child: Text("Decline", style: TextStyle(color: primColor, fontWeight: FontWeight.bold, fontSize: 16)))),
                const SizedBox(width: 15),
                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)), onPressed: () async { final prefs = await SharedPreferences.getInstance(); await prefs.setBool('cookies_accepted', true); hasAcceptedCookies = true; Navigator.pop(context); }, child: const Text("Accept All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
              ],
            )
          ],
        )
      )
    );
  }

  Future<void> _fetchSettings() async {
    try {
      final res = await Supabase.instance.client.from('app_settings').select('website_url, app_logo_url, telegram_url, privacy_policy').limit(1).maybeSingle();
      if (res != null) {
        if(res['website_url'] != null) globalWebsiteUrl = res['website_url'];
        if(res['telegram_url'] != null) globalTelegramLink = res['telegram_url'];
        if(res['privacy_policy'] != null && res['privacy_policy'].toString().isNotEmpty) globalPrivacyPolicy = res['privacy_policy'];
      }
    } catch(e) { }
  }

  bool _isVersionGreater(String latest, String current) {
    List<String> lParts = latest.split('.'); List<String> cParts = current.split('.');
    for(int i = 0; i < min(lParts.length, cParts.length); i++) {
      int l = int.tryParse(lParts[i]) ?? 0; int c = int.tryParse(cParts[i]) ?? 0;
      if(l > c) return true; if(l < c) return false;
    }
    return lParts.length > cParts.length;
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    try {
      final response = await Supabase.instance.client.from('app_updates').select().order('created_at', ascending: false).limit(1).maybeSingle();
      if (response != null) {
        String latestVersion = response['version'] ?? CURRENT_APP_VERSION;
        String updateUrl = response['apk_url'] ?? globalWebsiteUrl; 
        if (updateUrl.isEmpty) updateUrl = globalWebsiteUrl;
        if (_isVersionGreater(latestVersion, CURRENT_APP_VERSION)) { _showUpdateDialog(updateUrl); }
      }
    } catch (e) {}
  }

  void _showUpdateDialog(String updateUrl) {
    showDialog(
      context: context, barrierDismissible: false, 
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E1E24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 80, height: 80, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF9D4EDD), Color(0xFF6B21A8)])), child: const Icon(Icons.download_rounded, color: Colors.white, size: 40)),
              const SizedBox(height: 20),
              const Text("Install New Version", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
              Text("A new version of SYNEX MX is available.\nInstall now to enjoy the latest features.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.5)),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: const Text("Later", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))))),
                  const SizedBox(width: 16),
                  Expanded(child: GestureDetector(onTap: () { launchInBrowser(updateUrl); Navigator.pop(ctx); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFF6B21A8)]), borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: const Text("Install Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchDatabaseCatalog() async {
    try {
      var animeResponse;
      bool hasEpDate = true;
      try {
        animeResponse = await Supabase.instance.client.from('anime_list').select('''id, title, description, image_url, rating, genres, dub_status, dub_color, category, sub_category, created_at, anime_seasons (id, season_name, anime_episodes (id, episode_title, image_url, duration, video_url, created_at))''').order('created_at', ascending: false);
      } catch (e) {
        hasEpDate = false;
        animeResponse = await Supabase.instance.client.from('anime_list').select('''id, title, description, image_url, rating, genres, dub_status, dub_color, category, sub_category, created_at, anime_seasons (id, season_name, anime_episodes (id, episode_title, image_url, duration, video_url))''').order('created_at', ascending: false);
      }

      List<Anime> fetchedAnimeList = [];
      for (var item in animeResponse) {
        DateTime animeDate = DateTime.now().subtract(const Duration(days: 30));
        if (item['created_at'] != null) animeDate = DateTime.tryParse(item['created_at'].toString()) ?? animeDate;

        List<Season> parsedSeasons = [];
        var seasonsData = item['anime_seasons'] as List<dynamic>? ?? [];
        for (var s in seasonsData) {
          List<Episode> parsedEps = [];
          var epData = s['anime_episodes'] as List<dynamic>? ?? [];
          for (var e in epData) {
            DateTime epDate = animeDate; 
            if (hasEpDate && e['created_at'] != null) epDate = DateTime.tryParse(e['created_at'].toString()) ?? animeDate;
            parsedEps.add(Episode(id: e['id'].toString(), title: e['episode_title']?.toString() ?? "Episode", image: e['image_url']?.toString() ?? item['image_url'], duration: e['duration']?.toString() ?? "24m", videoUrl: e['video_url']?.toString() ?? "", createdAt: epDate));
          }
          parsedSeasons.add(Season(id: s['id'].toString(), name: s['season_name'].toString(), episodes: parsedEps));
        }

        fetchedAnimeList.add(Anime(id: item['id'].toString(), title: item['title']?.toString() ?? "Unknown", description: item['description']?.toString() ?? "", image: item['image_url']?.toString() ?? "", genre: item['genres']?.toString() ?? "Action", rating: item['rating']?.toString() ?? "PG-13", dubStatus: item['dub_status']?.toString() ?? "DUB", category: item['category']?.toString() ?? "", subCategory: item['sub_category']?.toString() ?? "", seasonsList: parsedSeasons, createdAt: animeDate));
      }
      animeListNotifier.value = fetchedAnimeList;

      final heroResponse = await Supabase.instance.client.from('hero_slider').select().order('created_at', ascending: false);
      heroSliderNotifier.value = List<Map<String, dynamic>>.from(heroResponse);
    } catch (e) {}
  }

  Future<void> _fetchUserPreferences() async {
    try {
      final response = await Supabase.instance.client.from('user_preferences').select('continue_watching, saved_anime').eq('device_id', currentDeviceId).maybeSingle();
      if (response != null) {
        if (response['continue_watching'] != null) {
          final List<dynamic> cwData = response['continue_watching'];
          continueWatchingNotifier.value = cwData.map((data) => CWItem.fromJson(data, animeListNotifier.value)).toList();
        }
        if (response['saved_anime'] != null) {
          final List<dynamic> savedData = response['saved_anime'];
          final List<SavedEpisode> fetchedList = [];
          for (var data in savedData) {
            try {
              final animeMatch = animeListNotifier.value.firstWhere((anime) => anime.title == data['animeTitle']);
              fetchedList.add(SavedEpisode(anime: animeMatch, seasonIndex: data['seasonIndex'] ?? 0, episodeIndex: data['episodeIndex'] ?? 0));
            } catch (e) { }
          }
          myListNotifier.value = fetchedList;
        }
      }
    } catch (e) {}
  }

  void _goToSearch() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) return Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)));

    final List<Widget> pages = [
      HomeScreen(onSearchTap: _goToSearch), 
      const BrowseScreen(), 
      const MoviesScreen(), 
      const MyListScreen(), 
      const ProfileScreen()
    ];

    return Scaffold(
      extendBody: true,
      body: pages[_index],
      bottomNavigationBar: SizedBox(
        height: 80,
        child: BottomNavigationBar(
          backgroundColor: getCard(context), 
          type: BottomNavigationBarType.fixed, 
          selectedItemColor: Theme.of(context).primaryColor, 
          unselectedItemColor: Colors.grey[500], 
          iconSize: 26, 
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), 
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
          currentIndex: _index, onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 6), child: Icon(Icons.home_filled)), label: "Home"),
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 6), child: Icon(Icons.search)), label: "Search"),
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 6), child: Icon(Icons.movie_creation_rounded)), label: "Movies"),
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 6), child: Icon(Icons.list_alt)), label: "My List"),
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 6), child: Icon(Icons.person)), label: "Account"),
          ],
        ),
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
    
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(
        backgroundColor: getBg(context), elevation: 0,
        title: RichText(text: const TextSpan(children: [
          TextSpan(text: "SYNEX ", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)), 
          TextSpan(text: "MX", style: TextStyle(color: Color(0xFF8A2BE2), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5))
        ])),
        actions:[IconButton(icon: Icon(Icons.search, color: getText(context), size: 28), onPressed: onSearchTap)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            ValueListenableBuilder<List<Map<String,dynamic>>>(
              valueListenable: heroSliderNotifier,
              builder: (context, heroList, child) {
                if (heroList.isEmpty) return const SizedBox.shrink();

                return CarouselSlider.builder(
                  itemCount: heroList.length, 
                  options: CarouselOptions(height: 220, autoPlay: true, enlargeCenterPage: false, viewportFraction: 1.0),
                  itemBuilder: (ctx, i, real) {
                    final hero = heroList[i];
                    final bool isCustom = hero['is_custom'] ?? false;
                    final String heroTitle = hero['title'] ?? "";
                    final String heroTag = hero['tag'] ?? "NEW";
                    String hexColor = hero['tag_color']?.toString().replaceAll('#', '') ?? "FF8A2BE2";
                    if(hexColor.length == 6) hexColor = 'FF$hexColor';
                    Color tagColor = Color(int.tryParse(hexColor, radix: 16) ?? 0xFF8A2BE2);
                    
                    return GestureDetector(
                      onTap: () { 
                        if (isCustom || hero['anime_id'] == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stay tuned for updates!")));
                        } else {
                          try {
                            final linkedAnime = animeListNotifier.value.firstWhere((a) => a.id == hero['anime_id'].toString());
                            Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: linkedAnime))); 
                          } catch(e) { }
                        }
                      }, 
                      child: Stack(
                        fit: StackFit.expand, 
                        children:[
                          Image.network(hero['image_url'], fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.white54)), 
                          Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.95), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter, stops: const [0.0, 0.6]))), 
                          Positioned(top: 15, right: 15, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: Text("${i + 1}/${heroList.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))), 
                          if (heroTitle.isNotEmpty)
                            Positioned(
                              bottom: 20, left: 15, 
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, 
                                children:[
                                  SizedBox(width: MediaQuery.of(context).size.width * 0.85, child: Text(heroTitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1), maxLines: 1, overflow: TextOverflow.ellipsis)), 
                                  const SizedBox(height: 8), 
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(4)), child: Text(heroTag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))
                                ]
                              )
                            )
                        ]
                      )
                    );
                  },
                );
              }
            ),
            const SizedBox(height: 20),
            
            ValueListenableBuilder<List<Anime>>(
              valueListenable: animeListNotifier,
              builder: (context, allAnime, child) {
                if (allAnime.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No Content found in Database", style: TextStyle(color: Colors.white54))));
                
                final trendingList = allAnime.where((a) => a.category.trim().toLowerCase().contains("trending")).toList();
                final actionList = allAnime.where((a) => a.category.trim().toLowerCase().contains("action") || a.subCategory.trim().toLowerCase().contains("action")).toList();
                final romanceList = allAnime.where((a) => a.category.trim().toLowerCase().contains("romance") || a.subCategory.trim().toLowerCase().contains("romance")).toList();
                final comedyList = allAnime.where((a) => a.category.trim().toLowerCase().contains("comedy") || a.subCategory.trim().toLowerCase().contains("comedy")).toList();
                
                List<Anime> popularList = List.from(allAnime);
                popularList.sort((a, b) {
                  int viewsA = globalAnimeViewsNotifier.value[a.title] ?? 0;
                  int viewsB = globalAnimeViewsNotifier.value[b.title] ?? 0;
                  return viewsB.compareTo(viewsA); 
                });

                List<LatestEpisodeItem> latestEpisodesFlatList = [];
                for (var anime in allAnime) {
                  for (int s = 0; s < anime.seasonsList.length; s++) {
                    for (int e = 0; e < anime.seasonsList[s].episodes.length; e++) {
                      latestEpisodesFlatList.add(LatestEpisodeItem(anime: anime, seasonIndex: s, episodeIndex: e, episode: anime.seasonsList[s].episodes[e]));
                    }
                  }
                }
                latestEpisodesFlatList.sort((a, b) => b.episode.createdAt.compareTo(a.episode.createdAt));
                if (latestEpisodesFlatList.length > 20) latestEpisodesFlatList = latestEpisodesFlatList.sublist(0, 20); 

                return Column(
                  children: [
                    _buildPortraitSection(context, "Recently Added", Icons.fiber_new, Colors.green, allAnime), 
                    if (trendingList.isNotEmpty) _buildPortraitSection(context, "Trending Now", Icons.local_fire_department_rounded, primColor, trendingList),
                    if (popularList.isNotEmpty) _buildPopularSection(context, "Popular Anime", Icons.emoji_events, Colors.amber, popularList),
                    if (latestEpisodesFlatList.isNotEmpty) _buildLatestEpisodesSection(context, "Latest Episodes", primColor, latestEpisodesFlatList),
                    if (actionList.isNotEmpty) _buildPortraitSection(context, "Action", null, null, actionList),
                    if (romanceList.isNotEmpty) _buildPortraitSection(context, "Romance", null, null, romanceList),
                    if (comedyList.isNotEmpty) _buildPortraitSection(context, "Comedy", null, null, comedyList),
                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestEpisodesSection(BuildContext context, String title, Color primColor, List<LatestEpisodeItem> latestList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Row(children:[Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: getText(context)))]), 
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LatestEpisodesSeeAllPage(latestList: latestList))), 
                child: Text("See All", style: TextStyle(color: primColor, fontWeight: FontWeight.bold, fontSize: 13))
              )
            ]
          ),
        ),
        SizedBox(
          height: 150, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), itemCount: latestList.length, 
            itemBuilder: (context, index) { 
              return ThumbnailLatestCard(item: latestList[index]); 
            }
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPortraitSection(BuildContext context, String title, IconData? icon, Color? iconColor, List<Anime> list) {
    if(list.isEmpty) return const SizedBox.shrink();
    Color primColor = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children:[
              Row(children:[Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: getText(context))), if (icon != null) ...[const SizedBox(width: 6), Icon(icon, color: iconColor, size: 20)]]), 
              GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SeeAllCategoryPage(title: title, animeList: list))), child: Text("See All", style: TextStyle(color: primColor, fontWeight: FontWeight.bold, fontSize: 13)))
            ]
          ),
        ),
        SizedBox(
          height: 260, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), itemCount: list.length, 
            itemBuilder: (context, index) { 
              String cardCategory = list[index].category.isNotEmpty ? list[index].category : list[index].genre;
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: list[index]))), 
                child: Container(
                  width: 140, margin: const EdgeInsets.only(right: 14), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children:[
                      Expanded(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 1.5)), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(list[index].image, fit: BoxFit.cover, width: double.infinity, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white54))))), 
                      const SizedBox(height: 8), 
                      Text(list[index].title, style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis), 
                      Text(cardCategory, style: TextStyle(color: getSubText(context), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)
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
              Row(children:[Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: getText(context))), const SizedBox(width: 8), Icon(icon, color: iconColor, size: 24)]), 
              GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SeeAllCategoryPage(title: title, animeList: list))), child: Text("See All", style: TextStyle(color: primColor, fontWeight: FontWeight.bold, fontSize: 13)))
            ]
          ),
        ),
        SizedBox(
          height: 250, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), itemCount: list.length, 
            itemBuilder: (context, index) { return OverlayPopularCard(anime: list[index]); }
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ==========================================
// LATEST EPISODES "SEE ALL" PAGE
// ==========================================
class LatestEpisodesSeeAllPage extends StatelessWidget {
  final List<LatestEpisodeItem> latestList;
  const LatestEpisodesSeeAllPage({super.key, required this.latestList});

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(title: Text("Latest Episodes", style: TextStyle(color: getText(context), fontWeight: FontWeight.bold)), backgroundColor: getBg(context), iconTheme: IconThemeData(color: getText(context)), elevation: 0),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), itemCount: latestList.length,
        itemBuilder: (context, index) {
          final item = latestList[index];
          String epImage = item.episode.image.isNotEmpty ? item.episode.image : item.anime.image;
          String displayTitle = (item.episode.title.isNotEmpty && item.episode.title != "Episode") ? item.episode.title : item.anime.title;

          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: item.anime, seasonIndex: item.seasonIndex, episodeIndex: item.episodeIndex))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16), height: 110,
              decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
              child: Row(
                children: [
                  SizedBox(
                    width: 160, height: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(epImage, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                          Container(color: Colors.black38), const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(displayTitle, style: TextStyle(color: getText(context), fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text(item.anime.title, style: TextStyle(color: primColor, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(children: [Icon(Icons.access_time, color: getSubText(context), size: 14), const SizedBox(width: 4), Text("Episode ${item.episodeIndex + 1}", style: TextStyle(color: getSubText(context), fontSize: 12))])
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
// CONTINUE WATCHING "SEE ALL" PAGE
// ==========================================
class CWSeeAllPage extends StatelessWidget {
  final List<CWItem> cwList;
  const CWSeeAllPage({super.key, required this.cwList});

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(title: Text("Continue Watching", style: TextStyle(color: getText(context), fontWeight: FontWeight.bold)), backgroundColor: getBg(context), iconTheme: IconThemeData(color: getText(context)), elevation: 0),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), itemCount: cwList.length,
        itemBuilder: (context, index) {
          final item = cwList[index];
          double progress = 0.0;
          if (item.totalDuration.inMilliseconds > 0) progress = item.position.inMilliseconds / item.totalDuration.inMilliseconds;
          final ep = item.anime.seasonsList[item.seasonIndex].episodes[item.episodeIndex];

          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: item.anime, seasonIndex: item.seasonIndex, episodeIndex: item.episodeIndex, startPosition: item.position))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16), height: 110,
              decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
              child: Row(
                children: [
                  SizedBox(
                    width: 160, height: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(ep.image, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                          Container(color: Colors.black38), const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40)),
                          if (progress > 0.0) Positioned(bottom: 0, left: 0, right: 0, child: LinearProgressIndicator(value: progress, backgroundColor: Colors.black54, valueColor: AlwaysStoppedAnimation<Color>(primColor), minHeight: 4))
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.anime.title, style: TextStyle(color: getText(context), fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text("Episode ${item.episodeIndex + 1}: ${ep.title}", style: TextStyle(color: getSubText(context), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(children: [Icon(Icons.access_time, color: primColor, size: 14), const SizedBox(width: 4), Text("${(progress * 100).toInt()}% Watched", style: TextStyle(color: primColor, fontSize: 12, fontWeight: FontWeight.bold))])
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
      final response = await Supabase.instance.client.from('user_preferences').select('recent_searches').eq('device_id', currentDeviceId).maybeSingle();
      if (response != null && response['recent_searches'] != null) {
        setState(() {
          var data = response['recent_searches'];
          if (data is String) { globalRecentSearches = List<String>.from(jsonDecode(data)); } else if (data is List) { globalRecentSearches = List<String>.from(data); } else { globalRecentSearches = []; }
          _isLoadingSearches = false;
        });
      } else { setState(() => _isLoadingSearches = false); }
    } catch (e) { setState(() => _isLoadingSearches = false); }
  }

  Future<void> _updateRecentSearchesInDb(String query) async {
    final newSearches = [...globalRecentSearches];
    if (newSearches.length > 5) newSearches.removeLast(); 
    if (!newSearches.contains(query)) newSearches.insert(0, query);
    String searchesJson = jsonEncode(newSearches);
    try { await Supabase.instance.client.from('user_preferences').upsert({'device_id': currentDeviceId, 'recent_searches': searchesJson}, onConflict: 'device_id'); } catch (e) {}
  }

  void _performSearch(String query) { 
    if (query.isEmpty) { setState(() { _searchResults = []; }); } else { 
      setState(() { 
        _searchResults = animeListNotifier.value.where((anime) {
          return anime.title.toLowerCase().contains(query.toLowerCase()) || anime.genre.toLowerCase().contains(query.toLowerCase()) || anime.category.toLowerCase().contains(query.toLowerCase());
        }).toList(); 
      }); 
    } 
  }

  void _setSearchQuery(String query) { _searchController.text = query; _performSearch(query); if (query.isNotEmpty) { _updateRecentSearchesInDb(query); } }

  void _submitSearch(String query) { 
    if (query.trim().isNotEmpty && !globalRecentSearches.contains(query.trim())) { setState(() { globalRecentSearches.insert(0, query.trim()); }); _updateRecentSearchesInDb(query.trim()); } 
    _performSearch(query); 
  }

  void _removeRecentSearch(int index) { setState(() { globalRecentSearches.removeAt(index); }); _updateRecentSearchesInDb(globalRecentSearches.join(',')); }

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
                decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(12)), 
                child: TextField(
                  controller: _searchController, onChanged: _performSearch, onSubmitted: _submitSearch, style: TextStyle(color: getText(context), fontSize: 15), 
                  decoration: InputDecoration(hintText: "Search anime, movies, episodes...", hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15), prefixIcon: Icon(Icons.search, color: Colors.grey[500]), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: Icon(Icons.cancel, color: Colors.grey[600]), onPressed: () { _searchController.clear(); _performSearch(""); }) : null, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16))
                )
              ),
              const SizedBox(height: 24),
              
              if (_searchController.text.isNotEmpty) ...[
                if (_searchResults.isEmpty) const Center(child: Padding(padding: EdgeInsets.only(top: 20), child: Text("No content found.", style: TextStyle(color: Colors.grey, fontSize: 15)))) 
                else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 14, mainAxisSpacing: 16), itemCount: _searchResults.length, itemBuilder: (context, index) => GridCategoryCard(anime: _searchResults[index], pageTitle: ""))
              ] else ...[
                Text("Recommended", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: getText(context))), 
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: recommendedSearches.map((e) => GestureDetector(
                    onTap: () => _setSearchQuery(e),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                      child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    )
                  )).toList(),
                ),
                const SizedBox(height: 30),

                Text("Recent Searches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: getText(context))), 
                const SizedBox(height: 12), 
                _isLoadingSearches
                    ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                    : (globalRecentSearches.isEmpty) 
                        ? const Text("No recent searches.", style: TextStyle(color: Colors.grey, fontSize: 14)) 
                        : ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: globalRecentSearches.length, itemBuilder: (context, index) { return _buildRecentItem(globalRecentSearches[index], index); })
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
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(12)), 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children:[
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: getText(context)), maxLines: 1, overflow: TextOverflow.ellipsis)), 
            Row(children:[GestureDetector(onTap: () => _removeRecentSearch(index), child: Icon(Icons.close, size: 18, color: Colors.grey[500])), const SizedBox(width: 12), Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[600])])
          ]
        )
      )
    ); 
  }
}

// ==========================================
// MOVIES SCREEN 
// ==========================================
class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key}); 

  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      backgroundColor: getBg(context), 
      appBar: AppBar(
        title: Text("Movies", style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 26)), 
        backgroundColor: getBg(context), 
        elevation: 0
      ), 
      body: ValueListenableBuilder<List<Anime>>(
        valueListenable: animeListNotifier, 
        builder: (context, list, child) { 
          final movies = list.where((a) => a.category.toLowerCase().contains("movie") || a.genre.toLowerCase().contains("movie")).toList(); 
          if(movies.isEmpty) {
            return const Center(child: Text("No Movies Available", style: TextStyle(color: Colors.white54, fontSize: 16)));
          }
          return GridView.builder(
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100), 
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 14, mainAxisSpacing: 16), 
            itemCount: movies.length, 
            itemBuilder: (context, index) { 
              return GridCategoryCard(anime: movies[index], pageTitle: "MOVIE"); 
            }
          ); 
        }
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
      final response = await Supabase.instance.client.from('user_preferences').select('saved_anime').eq('device_id', currentDeviceId).maybeSingle();
      if (response != null && response['saved_anime'] != null) {
        final List<dynamic> savedData = response['saved_anime'];
        final List<SavedEpisode> fetchedList = [];
        for (var data in savedData) {
          try {
            final animeMatch = animeListNotifier.value.firstWhere((anime) => anime.title == data['animeTitle']);
            fetchedList.add(SavedEpisode(anime: animeMatch, seasonIndex: data['seasonIndex'] ?? 0, episodeIndex: data['episodeIndex'] ?? 0));
          } catch (e) {}
        }
        setState(() { myListNotifier.value = fetchedList; _isLoadingSavedAnime = false; });
      } else { setState(() => _isLoadingSavedAnime = false); }
    } catch (e) { setState(() => _isLoadingSavedAnime = false); }
  }

  void _removeSavedAnime(SavedEpisode episode) {
    final list = List<SavedEpisode>.from(myListNotifier.value);
    list.removeWhere((item) => item.anime.title == episode.anime.title);
    myListNotifier.value = list;
    MyListService().saveMyList(currentDeviceId, list);
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(title: Text("My List", style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 26)), backgroundColor: getBg(context), elevation: 0),
      body: _isLoadingSavedAnime
          ? Center(child: CircularProgressIndicator(color: primColor))
          : ValueListenableBuilder<List<SavedEpisode>>(
              valueListenable: myListNotifier,
              builder: (context, savedList, child) {
                if (savedList.isEmpty) return Center(child: Text("Your watch list is empty.", style: TextStyle(color: getSubText(context), fontSize: 16)));
                
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100), 
                  itemCount: savedList.length, 
                  itemBuilder: (context, index) { 
                    final anime = savedList[index].anime;
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: anime))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 130,
                        decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))]),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)), 
                              child: Image.network(anime.image, width: 100, height: 130, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image))
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(anime.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 8),
                                    Text("${anime.season} • ${anime.dubStatus}", style: TextStyle(color: primColor, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ]
                                )
                              )
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(icon: Icon(Icons.play_circle_fill, color: primColor, size: 40), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: anime)))),
                                GestureDetector(
                                  onTap: () => _removeSavedAnime(savedList[index]),
                                  child: const Padding(padding: EdgeInsets.only(bottom: 8), child: Icon(Icons.delete_outline, color: Colors.white54, size: 24)),
                                )
                              ],
                            ),
                            const SizedBox(width: 10),
                          ]
                        )
                      ),
                    );
                  }
                );
              },
            ),
    );
  }
}

// ==========================================
// PARTICLES BACKGROUND CustomPainter
// ==========================================
class ParticlesBackground extends StatefulWidget {
  const ParticlesBackground({super.key});
  @override
  _ParticlesBackgroundState createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 40; i++) {
      particles.add(Particle());
    }
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() { 
    _controller.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (var p in particles) { p.update(); }
        return CustomPaint(painter: ParticlePainter(particles, Theme.of(context).primaryColor), size: Size.infinite);
      },
    );
  }
}

class Particle {
  double x = Random().nextDouble() * 400; 
  double y = Random().nextDouble() * 800;
  double speed = Random().nextDouble() * 1 + 0.5;
  double radius = Random().nextDouble() * 2 + 1;
  void update() {
    y -= speed;
    if (y < 0) { y = 800; x = Random().nextDouble() * 400; }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color pColor;
  ParticlePainter(this.particles, this.pColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = pColor.withOpacity(0.3);
    for (var p in particles) {
      double dx = (p.x / 400) * size.width;
      double dy = (p.y / 800) * size.height;
      canvas.drawCircle(Offset(dx, dy), p.radius, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// CLEAN PROFILE SCREEN (WITH PARTICLES)
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key}); 

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: getBg(context),
      body: Stack(
        children: [
          const ParticlesBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, 
                children: [
                  Container(
                    padding: const EdgeInsets.all(4), 
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primColor, width: 2)),
                    child: CircleAvatar(radius: 45, backgroundColor: getAvatarColor(currentUserName), child: Text(getAvatarLetter(currentUserName), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(currentUserName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), 
                  const SizedBox(height: 6),
                  Text("ID: $currentDeviceId", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, letterSpacing: 1.2)),
                  
                  const SizedBox(height: 60),
                  
                  Container(
                    decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.telegram, color: Colors.blueAccent, size: 28),
                      ),
                      title: const Text("Join our Community", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                      onTap: () => launchInBrowser(globalTelegramLink),
                    ),
                  ),
                  
                  const SizedBox(height: 60), 
                  
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Privacy Policy", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Text(globalPrivacyPolicy, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
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
  
  const SeeAllCategoryPage({super.key, required this.title, required this.animeList, this.isLatestOnly = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(backgroundColor: getBg(context), elevation: 0, title: Text(title, style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 20)), iconTheme: IconThemeData(color: getText(context))),
      body: GridView.builder(
        padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 40), 
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.70, crossAxisSpacing: 14, mainAxisSpacing: 16), 
        itemCount: animeList.length, 
        itemBuilder: (context, index) => GridCategoryCard(anime: animeList[index], pageTitle: title, isLatestOnly: isLatestOnly)
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: anime))), 
      child: Container(
        width: 160, margin: const EdgeInsets.only(right: 12), 
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 1.5)), 
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10), 
          child: Stack(
            children:[
              Image.network(anime.image, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.white54)), 
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors:[Colors.black.withOpacity(0.9), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center)))), 
              Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: Colors.cyan, borderRadius: BorderRadius.circular(4)), child: const Text("POPULAR", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)))), 
              Positioned(
                bottom: 10, left: 10, right: 10, 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children:[
                    Text(anime.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis), 
                    const SizedBox(height: 4), 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children:[
                        Text("${anime.season} | Ep 3", style: const TextStyle(color: Colors.white70, fontSize: 10)), 
                        Row(
                          children:[
                            const Icon(Icons.visibility, color: Colors.white70, size: 12), const SizedBox(width: 4), 
                            ValueListenableBuilder<Map<String, int>>(valueListenable: globalAnimeViewsNotifier, builder: (context, viewsMap, child) { int totalViews = viewsMap[anime.title] ?? 0; return Text(formatViewsCount(totalViews), style: const TextStyle(color: Colors.white70, fontSize: 10)); })
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
  final bool isLatestOnly;
  const GridCategoryCard({super.key, required this.anime, required this.pageTitle, this.isLatestOnly = false});

  @override
  State<GridCategoryCard> createState() => _GridCategoryCardState();
}

class _GridCategoryCardState extends State<GridCategoryCard> {
  void _toggleSaveAnime() {
    final list = List<SavedEpisode>.from(myListNotifier.value);
    final isSaved = list.any((item) => item.anime.title == widget.anime.title);
    if (isSaved) { list.removeWhere((item) => item.anime.title == widget.anime.title); } else { list.add(SavedEpisode(anime: widget.anime, seasonIndex: 0, episodeIndex: 0)); }
    myListNotifier.value = list;
    MyListService().saveMyList(currentDeviceId, list);
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    String? tagText; Color? tagBgColor; Color tagTextColor = Colors.black;
    
    if (widget.pageTitle == "Trending Now") { tagText = "TRENDING"; tagBgColor = primColor; tagTextColor = Colors.white; } 
    else if (widget.pageTitle == "Popular Anime") { tagText = "POPULAR"; tagBgColor = Colors.cyan; tagTextColor = Colors.black; } 
    else if (widget.pageTitle == "DUB" || widget.anime.dubStatus == "DUB" || widget.anime.dubStatus == "AMX DUB") { 
      tagText = "SYNEX MX"; tagBgColor = const Color(0xFF8A2BE2); tagTextColor = Colors.white; 
    }
    
    final bool isSaved = myListNotifier.value.any((item) => item.anime.title == widget.anime.title);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: widget.anime)));
      }, 
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 1.5)), 
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10), 
          child: Stack(
            children:[
              Image.network(widget.anime.image, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.white54)), 
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors:[Colors.black.withOpacity(0.9), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center)))), 
              if (tagText != null) Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: tagBgColor, borderRadius: BorderRadius.circular(4)), child: Text(tagText, style: TextStyle(color: tagTextColor, fontSize: 10, fontWeight: FontWeight.bold)))), 
              Positioned(
                bottom: 10, left: 10, right: 10, 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children:[
                    Text(widget.anime.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis), 
                    const SizedBox(height: 4), 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children:[
                        Text("${widget.anime.season} | Ep 3", style: const TextStyle(color: Colors.white70, fontSize: 10)), 
                        Row(children:[const Icon(Icons.visibility, color: Colors.white70, size: 12), const SizedBox(width: 4), ValueListenableBuilder<Map<String, int>>(valueListenable: globalAnimeViewsNotifier, builder: (context, viewsMap, child) { int totalViews = viewsMap[widget.anime.title] ?? 0; return Text(formatViewsCount(totalViews), style: const TextStyle(color: Colors.white70, fontSize: 10)); })])
                      ]
                    )
                  ]
                )
              ),
              Positioned(top: 8, left: 8, child: GestureDetector(onTap: () { _toggleSaveAnime(); }, child: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: primColor, size: 24))),
            ]
          )
        ),
      ),
    );
  }
}

class ThumbnailLatestCard extends StatelessWidget {
  final LatestEpisodeItem item; 
  const ThumbnailLatestCard({super.key, required this.item});
  
  @override
  Widget build(BuildContext context) {
    int latestEpNum = item.episodeIndex + 1;
    String displayImage = item.episode.image.isNotEmpty ? item.episode.image : item.anime.image;
    String displayTitle = (item.episode.title.isNotEmpty && item.episode.title != "Episode") ? item.episode.title : item.anime.title;

    int daysOld = DateTime.now().difference(item.episode.createdAt).inDays;
    bool isBrandNew = daysOld <= 14;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: item.anime, seasonIndex: item.seasonIndex, episodeIndex: item.episodeIndex)));
      }, 
      child: Container(
        width: 180, margin: const EdgeInsets.only(right: 14), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children:[
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 1.5)),
              child: AspectRatio(
                aspectRatio: 16 / 9, 
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), 
                  child: Stack(
                    fit: StackFit.expand, 
                    children:[
                      Image.network(displayImage, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)), 
                      Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.8), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center))),
                      if (isBrandNew) Positioned(top: 6, right: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)), child: const Text("NEW", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                      Positioned(bottom: 6, right: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)), child: Text("Ep $latestEpNum", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))
                    ]
                  )
                )
              ),
            ), 
            const SizedBox(height: 8), 
            Text(displayTitle, style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis), 
            const SizedBox(height: 2), 
            Text(item.anime.title, style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)
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
    if (widget.item.totalDuration.inMilliseconds > 0) progress = widget.item.position.inMilliseconds / widget.item.totalDuration.inMilliseconds;
    
    String epImage = "";
    if (widget.item.anime.seasonsList.length > widget.item.seasonIndex) {
      if (widget.item.anime.seasonsList[widget.item.seasonIndex].episodes.length > widget.item.episodeIndex) {
        epImage = widget.item.anime.seasonsList[widget.item.seasonIndex].episodes[widget.item.episodeIndex].image;
      }
    }
    if (epImage.isEmpty) epImage = widget.item.anime.image;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true), 
      onTapUp: (_) { 
        setState(() => _isTapped = false); 
        Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: widget.item.anime, seasonIndex: widget.item.seasonIndex, episodeIndex: widget.item.episodeIndex, startPosition: widget.item.position)));
      }, 
      onTapCancel: () => setState(() => _isTapped = false), 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150), curve: Curves.easeOut, transform: Matrix4.identity()..scale(_isTapped ? 0.96 : 1.0), width: 180, margin: const EdgeInsets.only(right: 12), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children:[
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 1.5)),
              child: AspectRatio(
                aspectRatio: 16 / 9, 
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), 
                  child: Stack(
                    fit: StackFit.expand, 
                    children: [
                      Image.network(epImage, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)), 
                      Container(color: Colors.black38), const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40)), 
                      Positioned(bottom: 0, left: 0, right: 0, child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation<Color>(primColor), minHeight: 4))
                    ]
                  )
                )
              ),
            ), 
            const SizedBox(height: 8), 
            Text(widget.item.anime.title, style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis), 
            Text("Episode ${widget.item.episodeIndex + 1}", style: TextStyle(color: getSubText(context), fontSize: 11))
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
      final response = await Supabase.instance.client.from('episode_views').select('episode_id, view_count').like('episode_id', '${widget.anime.title}_${_selectedSeasonIndex}_%');
      if (mounted && response != null) {
        Map<int, String> viewsMap = {};
        for (var row in response) {
          String epId = row['episode_id']; int vCount = row['view_count'] ?? 0;
          List<String> parts = epId.split('_');
          if (parts.isNotEmpty) { int? eIdx = int.tryParse(parts.last); if (eIdx != null) { viewsMap[eIdx] = formatViewsCount(vCount); } }
        }
        setState(() { _episodeViews = viewsMap; });
      }
    } catch (e) { }
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor; 
    
    if (widget.anime.seasonsList.isEmpty) { 
      return Scaffold(backgroundColor: getBg(context), appBar: AppBar(backgroundColor: getBg(context), title: Text(widget.anime.title, style: TextStyle(color: getText(context)))), body: Center(child: Text("Episodes Coming Soon!", style: TextStyle(color: getText(context))))); 
    }

    Season currentSeason = widget.anime.seasonsList[_selectedSeasonIndex]; 
    List<Episode> episodesList = currentSeason.episodes;
    if (widget.isLatestOnly && episodesList.isNotEmpty) { episodesList = [episodesList.last]; }

    return Scaffold(
      backgroundColor: getBg(context),
      body: CustomScrollView(
        slivers:[
          SliverAppBar(
            expandedHeight: 250, pinned: true, backgroundColor: getBg(context), 
            leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: getText(context), size: 28), onPressed: () => Navigator.pop(context)),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand, 
                children:[
                  Image.network(widget.anime.image, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 50, color: Colors.white54)), 
                  Container(decoration: BoxDecoration(gradient: LinearGradient(colors:[getBg(context), getBg(context).withOpacity(0.5), Colors.transparent], stops: const [0.0, 0.4, 1.0], begin: Alignment.bottomCenter, end: Alignment.topCenter)))
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
                  Text(widget.anime.title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: getText(context))), 
                  const SizedBox(height: 10),
                  Row(
                    children:[
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)), child: Text(widget.anime.rating, style: TextStyle(color: getText(context), fontSize: 13, fontWeight: FontWeight.bold))), 
                      const SizedBox(width: 10), 
                      Expanded(child: Text("• ${widget.anime.dubStatus} | ${widget.anime.genre.isNotEmpty ? widget.anime.genre : widget.anime.category}", style: TextStyle(color: getSubText(context), fontSize: 13), overflow: TextOverflow.ellipsis))
                    ]
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, 
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: primColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 5), 
                      onPressed: () { 
                        if (episodesList.isNotEmpty) {
                          int playIndex = widget.isLatestOnly ? currentSeason.episodes.length - 1 : 0;
                          Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: widget.anime, seasonIndex: _selectedSeasonIndex, episodeIndex: playIndex)));
                        }
                      }, 
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32), 
                      label: const Text("Play Now", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                    )
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.anime.description.isNotEmpty ? widget.anime.description : "Watch it now on SYNEX MX!", 
                    maxLines: _isExpanded ? null : 3, overflow: _isExpanded ? null : TextOverflow.ellipsis, style: TextStyle(color: getSubText(context), fontSize: 13, height: 1.5)
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(onTap: () => setState(() => _isExpanded = !_isExpanded), child: Text(_isExpanded ? "Read Less" : "Read More", style: TextStyle(color: primColor, fontWeight: FontWeight.bold, fontSize: 13))),
                  const SizedBox(height: 30),
                  
                  if (!widget.isLatestOnly) ...[
                    Text("Seasons", style: TextStyle(color: getText(context), fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(height: 40, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: widget.anime.seasonsList.length, itemBuilder: (context, index) { return Padding(padding: const EdgeInsets.only(right: 12), child: _buildSeasonTab(index, widget.anime.seasonsList[index].name, primColor)); })),
                    const SizedBox(height: 24),
                  ],

                  Text(widget.isLatestOnly ? "Latest Episode" : "Episodes", style: TextStyle(color: getText(context), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<List<CWItem>>(
                    valueListenable: continueWatchingNotifier, 
                    builder: (context, cwList, child) { 
                      return ListView.builder(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: episodesList.length, 
                        itemBuilder: (context, index) { 
                          final ep = episodesList[index]; 
                          int actualEpIndex = widget.isLatestOnly ? currentSeason.episodes.length - 1 : index;
                          double progress = 0.0; 
                          final cwIndex = cwList.indexWhere((item) => item.anime.title == widget.anime.title && item.seasonIndex == _selectedSeasonIndex && item.episodeIndex == actualEpIndex); 
                          if (cwIndex != -1) { if (cwList[cwIndex].totalDuration.inMilliseconds > 0) { progress = cwList[cwIndex].position.inMilliseconds / cwList[cwIndex].totalDuration.inMilliseconds; } } 
                          
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: widget.anime, seasonIndex: _selectedSeasonIndex, episodeIndex: actualEpIndex, startPosition: cwIndex != -1 ? cwList[cwIndex].position : null))), 
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(12)), 
                              child: Row(
                                children:[
                                  SizedBox(
                                    width: 120, height: 70, 
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8), 
                                      child: Stack(
                                        fit: StackFit.expand, 
                                        children:[
                                          Image.network(ep.image, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)), 
                                          if (progress > 0.0) Positioned(bottom: 0, left: 0, right: 0, child: LinearProgressIndicator(value: progress, backgroundColor: Colors.black54, valueColor: AlwaysStoppedAnimation<Color>(primColor), minHeight: 4))
                                        ]
                                      )
                                    )
                                  ), 
                                  const SizedBox(width: 16), 
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, 
                                      children:[
                                        Text("${actualEpIndex + 1}. ${ep.title}", style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis), 
                                        const SizedBox(height: 6), 
                                        Row(
                                          children:[
                                            Text(ep.duration, style: TextStyle(color: getSubText(context), fontSize: 12)), 
                                            const SizedBox(width: 10), Icon(Icons.visibility, color: getSubText(context), size: 12), const SizedBox(width: 4), 
                                            Text(_episodeViews[actualEpIndex] ?? ep.views, style: TextStyle(color: getSubText(context), fontSize: 12))
                                          ]
                                        )
                                      ]
                                    )
                                  ), 
                                  Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white12), child: Icon(Icons.play_arrow_rounded, color: getText(context), size: 24))
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
      onTap: () { setState(() { _selectedSeasonIndex = index; }); _fetchEpisodeViews(); }, 
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isActive ? primaryColor : getCard(context), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(title, style: TextStyle(color: isActive ? Colors.white : getSubText(context), fontWeight: FontWeight.bold, fontSize: 13))))
    ); 
  }
}

// ==========================================
// FAST LOAD VIDEO PLAYER PAGE (SYNEX MX STYLE)
// ==========================================
class VideoPlayerPage extends StatefulWidget {
  final Anime anime; 
  final int seasonIndex; 
  final int episodeIndex; 
  final Duration? startPosition;

  const VideoPlayerPage({super.key, required this.anime, required this.seasonIndex, required this.episodeIndex, this.startPosition});

  @override 
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller; 
  bool _showControls = true; 
  bool _isFullScreen = false; 
  double _forwardOpacity = 0.0; 
  double _rewindOpacity = 0.0;
  
  int _currentEpisodeIndex = 0; 

  bool _isLiked = false; 
  bool _isDisliked = false;

  @override 
  void initState() { 
    super.initState(); 
    _currentEpisodeIndex = widget.episodeIndex;
    _incrementAndFetchViews(); 
    _initPlayer();
  }

  void _initPlayer() {
    final ep = widget.anime.seasonsList[widget.seasonIndex].episodes[_currentEpisodeIndex]; 
    _controller = VideoPlayerController.networkUrl(Uri.parse(ep.videoUrl), videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))..initialize().then((_) { 
      if (widget.startPosition != null && _currentEpisodeIndex == widget.episodeIndex) { 
        _controller.seekTo(widget.startPosition!); 
      } 
      setState(() {}); 
      _controller.play(); 
    }); 
  }

  void _changeEpisode(int newIndex) {
    if (newIndex == _currentEpisodeIndex) return;
    _updateContinueWatching(); 
    _controller.pause();
    _controller.dispose();
    
    setState(() {
      _currentEpisodeIndex = newIndex;
      _showControls = true;
    });
    
    _initPlayer();
  }

  @override 
  void dispose() { 
    _updateContinueWatching(); 
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]); 
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); 
    _controller.dispose(); 
    super.dispose(); 
  }

  Future<void> _incrementAndFetchViews() async {
    final episodeId = "${widget.anime.title}_${widget.seasonIndex}_${_currentEpisodeIndex}";
    try {
      final userView = await Supabase.instance.client.from('user_views').select().eq('device_id', currentDeviceId).eq('episode_id', episodeId).maybeSingle();
      if (userView == null) {
        await Supabase.instance.client.from('user_views').insert({'device_id': currentDeviceId, 'episode_id': episodeId});
        final response = await Supabase.instance.client.from('episode_views').select('view_count').eq('episode_id', episodeId).maybeSingle();
        int currentViews = response?['view_count'] ?? 0;
        int newViews = currentViews + 1;
        await Supabase.instance.client.from('episode_views').upsert({'episode_id': episodeId, 'view_count': newViews});
        final currentMap = Map<String, int>.from(globalAnimeViewsNotifier.value);
        currentMap[widget.anime.title] = (currentMap[widget.anime.title] ?? 0) + 1;
        globalAnimeViewsNotifier.value = currentMap;
      }
    } catch (e) { }
  }

  void _updateContinueWatching() { 
    if (!_controller.value.isInitialized) return; 
    final pos = _controller.value.position; final dur = _controller.value.duration; 
    if (pos > const Duration(seconds: 2)) { 
      final list = List<CWItem>.from(continueWatchingNotifier.value); 
      final existingIdx = list.indexWhere((item) => item.anime.title == widget.anime.title && item.seasonIndex == widget.seasonIndex && item.episodeIndex == _currentEpisodeIndex); 
      if (existingIdx != -1) { 
        list[existingIdx].position = pos; list[existingIdx].totalDuration = dur; 
        final item = list.removeAt(existingIdx); list.insert(0, item); 
      } else { list.insert(0, CWItem(anime: widget.anime, seasonIndex: widget.seasonIndex, episodeIndex: _currentEpisodeIndex, position: pos, totalDuration: dur)); } 
      continueWatchingNotifier.value = list; 
      CWService().saveCWList(currentDeviceId, list);
    } 
  }

  void _toggleControls() { setState(() => _showControls = !_showControls); }

  void _toggleFullScreen() { 
    setState(() => _isFullScreen = !_isFullScreen); 
    if (_isFullScreen) { 
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]); 
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); 
    } else { 
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]); 
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); 
    } 
  }

  void _skipForward() { 
    _controller.seekTo(_controller.value.position + const Duration(seconds: 10)); 
    setState(() => _forwardOpacity = 1.0); 
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) setState(() => _forwardOpacity = 0.0); }); 
  }

  void _skipBackward() { 
    _controller.seekTo(_controller.value.position - const Duration(seconds: 10)); 
    setState(() => _rewindOpacity = 1.0); 
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) setState(() => _rewindOpacity = 0.0); }); 
  }

  String _formatDuration(Duration duration) { 
    String twoDigits(int n) => n.toString().padLeft(2, '0'); 
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}"; 
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor; 
    final currentSeason = widget.anime.seasonsList[widget.seasonIndex]; 

    Widget videoContent = Stack(
      children:[
        _controller.value.isInitialized 
            ? Center(child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))) 
            : Center(child: CircularProgressIndicator(color: primColor)),
        
        Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 40), child: AnimatedOpacity(opacity: _rewindOpacity, duration: const Duration(milliseconds: 200), child: Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Column(mainAxisSize: MainAxisSize.min, children:[Icon(Icons.fast_rewind, color: Colors.white, size: 36), Text("-10s", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))]))))),
        Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(right: 40), child: AnimatedOpacity(opacity: _forwardOpacity, duration: const Duration(milliseconds: 200), child: Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Column(mainAxisSize: MainAxisSize.min, children:[Icon(Icons.fast_forward, color: Colors.white, size: 36), Text("+10s", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))]))))),

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
                      IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28), onPressed: () { if (_isFullScreen) { _toggleFullScreen(); } else { Navigator.pop(context); } }), 
                      Row(children:[IconButton(icon: const Icon(Icons.cast, color: Colors.white), onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connecting to TV feature coming soon!"))); }), IconButton(icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white), onPressed: _toggleFullScreen)])
                    ]
                  ), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                    children:[
                      IconButton(icon: const Icon(Icons.replay_10, color: Colors.white, size: 40), onPressed: _skipBackward), 
                      IconButton(icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 60), onPressed: () { setState(() { _controller.value.isPlaying ? _controller.pause() : _controller.play(); }); _updateContinueWatching(); }), 
                      IconButton(icon: const Icon(Icons.forward_10, color: Colors.white, size: 40), onPressed: _skipForward)
                    ]
                  ), 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), 
                    child: Row(
                      children:[
                        ValueListenableBuilder(valueListenable: _controller, builder: (context, VideoPlayerValue value, child) { return Text(_formatDuration(value.position), style: const TextStyle(color: Colors.white, fontSize: 12)); }), 
                        Expanded(child: ValueListenableBuilder(valueListenable: _controller, builder: (context, VideoPlayerValue value, child) { return SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 3.0, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0), overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0)), child: Slider(activeColor: primColor, inactiveColor: Colors.white24, min: 0.0, max: value.duration.inSeconds.toDouble() == 0 ? 100 : value.duration.inSeconds.toDouble(), value: value.position.inSeconds.toDouble().clamp(0.0, value.duration.inSeconds.toDouble() == 0 ? 100 : value.duration.inSeconds.toDouble()), onChangeStart: (val) { _controller.pause(); }, onChanged: (val) { _controller.seekTo(Duration(seconds: val.toInt())); }, onChangeEnd: (val) { _controller.play(); _updateContinueWatching(); })); })), 
                        ValueListenableBuilder(valueListenable: _controller, builder: (context, VideoPlayerValue value, child) { return Text(_formatDuration(value.duration), style: const TextStyle(color: Colors.white, fontSize: 12)); })
                      ]
                    )
                  )
                ]
              )
            ),
          ) 
        else 
          GestureDetector(onTap: _toggleControls, child: Container(color: Colors.transparent)),
      ],
    );

    if (_isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: AspectRatio(aspectRatio: 16 / 9, child: videoContent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(widget.anime.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: videoContent),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  const Text("You're watching", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text("Episode ${_currentEpisodeIndex + 1}", style: TextStyle(color: primColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("If current player not working, select other server.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  
                  GestureDetector(
                    onTap: () => launchInBrowser(globalTelegramLink),
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                      child: Row(
                        children: [
                          const Icon(Icons.telegram, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(text: "Join our ", style: TextStyle(color: Colors.white, fontSize: 14)),
                                  TextSpan(text: "Telegram Channel ", style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                                  TextSpan(text: "for updates! ❤️", style: TextStyle(color: Colors.white, fontSize: 14)),
                                ]
                              )
                            )
                          ),
                          const Icon(Icons.close, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.mic, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              const Text("DUB: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                                child: const Text("720p Quality", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white12, height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.download, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              const Text("DOWNLOAD: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                                child: const Text("Server #1", style: TextStyle(color: Colors.white, fontSize: 12)),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Episode Lists", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                          child: Row(
                            children: const [
                              Icon(Icons.search, color: Colors.blueAccent, size: 16),
                              SizedBox(width: 8),
                              Text("Search Episode", style: TextStyle(color: Colors.white54, fontSize: 13)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(currentSeason.episodes.length, (index) {
                          bool isActive = index == _currentEpisodeIndex;
                          return GestureDetector(
                            onTap: () => _changeEpisode(index),
                            child: Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(
                                color: isActive ? Colors.redAccent : getCard(context),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isActive ? Colors.redAccent : Colors.white12)
                              ),
                              child: Center(
                                child: Text(
                                  "${index + 1}", 
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: isActive ? FontWeight.w900 : FontWeight.bold)
                                )
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [getCard(context), Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Row(children: [Icon(Icons.star, color: Colors.white, size: 16), SizedBox(width: 8), Text("10 (1 Voted)", style: TextStyle(color: Colors.white, fontSize: 14))]),
                            Text("Vote Now!", style: TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text("Rate this anime!", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            Icon(Icons.sentiment_very_dissatisfied, color: Colors.amber, size: 40),
                            Icon(Icons.sentiment_dissatisfied, color: Colors.amber, size: 40),
                            Icon(Icons.sentiment_neutral, color: Colors.amber, size: 40),
                            Icon(Icons.sentiment_satisfied, color: Colors.amber, size: 40),
                            Icon(Icons.sentiment_very_satisfied, color: Colors.amber, size: 40),
                          ],
                        )
                      ],
                    ),
                  )

                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}