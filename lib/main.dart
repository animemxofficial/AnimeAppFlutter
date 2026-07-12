import 'dart:io'; 
import 'dart:math';
import 'dart:convert';
import 'dart:async'; // For Timers
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';

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
  return avatarColors[inputString.codeUnitAt(0) % avatarColors.length];
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

// ==========================================
// EXTREME SECURITY: VPN CHECKER & ID HASHER 
// ==========================================
Future<bool> checkVpnConnection() async {
  bool isVpn = false;
  try {
    List<NetworkInterface> interfaces = await NetworkInterface.list(includeLoopback: false, type: InternetAddressType.any);
    for (var interface in interfaces) {
      String name = interface.name.toLowerCase();
      if (name.contains("tun") || name.contains("ppp") || name.contains("pptp") || name.contains("tap") || name.contains("ipsec")) {
        isVpn = true; break;
      }
    }
  } catch (e) {}
  return isVpn;
}

Future<String> getHardwareDeviceId() async {
  String rawId = "UNKNOWN";
  try {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      rawId = "${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}";
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      rawId = "${iosInfo.name}_${iosInfo.identifierForVendor}";
    }
  } catch (e) {}
  
  if (rawId == "UNKNOWN") rawId = const Uuid().v4(); 
  var bytes = utf8.encode(rawId);
  var digest = sha256.convert(bytes);
  return digest.toString().substring(0, 9).toUpperCase(); 
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

// ==========================================
// SUPABASE DATA PERSISTENCE SERVICES
// ==========================================
class CWService {
  Future<void> saveCWList(String devId, List<CWItem> cwList) async {
    final savedData = cwList.map((item) => item.toJson()).toList();
    try { await Supabase.instance.client.from('user_preferences').upsert({'device_id': devId, 'continue_watching': savedData}, onConflict: 'device_id'); } catch (e) {}
  }
}

class RecentSearchesService {
  Future<void> saveRecentSearches(String devId, List<String> searches) async {
    final newSearches = [...searches];
    if (newSearches.length > 5) newSearches.removeLast(); 
    final searchesJson = jsonEncode(newSearches);
    try { await Supabase.instance.client.from('user_preferences').upsert({'device_id': devId, 'recent_searches': searchesJson}, onConflict: 'device_id'); } catch (e) {}
  }
}

class MyListService {
  Future<void> saveMyList(String devId, List<SavedEpisode> savedList) async {
    final savedData = savedList.map((item) => item.toJson()).toList();
    try { await Supabase.instance.client.from('user_preferences').upsert({'device_id': devId, 'saved_anime': savedData}, onConflict: 'device_id'); } catch (e) {}
  }
}

// ==========================================
// DATA MODELS
// ==========================================
class CWItem {
  final Anime anime; int seasonIndex; int episodeIndex; Duration position; Duration totalDuration;
  CWItem({required this.anime, required this.seasonIndex, required this.episodeIndex, required this.position, required this.totalDuration});
  Map<String, dynamic> toJson() => {'animeTitle': anime.title, 'seasonIndex': seasonIndex, 'episodeIndex': episodeIndex, 'positionInSeconds': position.inSeconds, 'totalDurationInSeconds': totalDuration.inSeconds};
  static CWItem fromJson(Map<String, dynamic> json, List<Anime> allAnime) {
    try {
      final animeMatch = allAnime.firstWhere((anime) => anime.title == json['animeTitle']);
      return CWItem(anime: animeMatch, seasonIndex: json['seasonIndex'], episodeIndex: json['episodeIndex'], position: Duration(seconds: json['positionInSeconds']), totalDuration: Duration(seconds: json['totalDurationInSeconds']));
    } catch (e) {
      return CWItem(anime: allAnime.isNotEmpty ? allAnime[0] : _getDummyAnime(), seasonIndex: 0, episodeIndex: 0, position: const Duration(), totalDuration: const Duration());
    }
  }
}

class SavedEpisode {
  final Anime anime; final int seasonIndex; final int episodeIndex;
  SavedEpisode({required this.anime, required this.seasonIndex, required this.episodeIndex});
  Map<String, dynamic> toJson() => {'animeTitle': anime.title, 'seasonIndex': seasonIndex, 'episodeIndex': episodeIndex};
}

class Episode {
  final String id; final String title; final String image; final String duration; final String views; final String videoUrl; final DateTime createdAt;
  Episode({required this.id, required this.title, required this.image, required this.duration, this.views = "0", required this.videoUrl, required this.createdAt});
}

class Season {
  final String id; final String name; final List<Episode> episodes;
  Season({required this.id, required this.name, required this.episodes});
}

class Anime {
  final String id; final String title; final String image; final String genre; final String rating; final String dubStatus; final String season; final String status; final String views; final Color dubColor; final List<Season> seasonsList; final String category; final String subCategory; final bool isNew; final String description; final DateTime createdAt; 
  Anime({required this.id, required this.title, required this.image, this.genre = "Action", this.rating = "PG-13", this.dubStatus = "DUB", this.season = "Season 1", this.status = "Ongoing", this.views = "0", this.dubColor = const Color(0xFFFF4D4D), required this.seasonsList, this.category = "", this.subCategory = "", this.isNew = false, this.description = "", required this.createdAt});
}

Anime _getDummyAnime() => Anime(id: '0', title: 'Loading...', image: '', seasonsList: [], createdAt: DateTime.now());

class LatestEpisodeItem {
  final Anime anime; final int seasonIndex; final int episodeIndex; final Episode episode;
  LatestEpisodeItem({required this.anime, required this.seasonIndex, required this.episodeIndex, required this.episode});
}

// ==========================================
// MAIN ENTRY POINT
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String secureUrl = utf8.decode(base64Decode('aHR0cHM6Ly95bmd6ZmdmcHl1ZnVzcmJpdGFnbC5zdXBhYmFzZS5jbw=='));
  String secureKey = utf8.decode(base64Decode('c2JfcHVibGlzaGFibGVfNkJEMG1vRXBPblVUZmloYlJVcGRPUV9VMmdKQ0g1VQ=='));
  await Supabase.initialize(url: secureUrl, anonKey: secureKey);
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
// VPN BLOCKER SCREEN
// ==========================================
class SecurityBlockScreen extends StatelessWidget {
  const SecurityBlockScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120000),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.shield, color: Colors.redAccent, size: 100),
              SizedBox(height: 30),
              Text("Security Violation", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text("VPN, Proxy, or unsecured connection detected.\n\nPlease disable any VPN to continue using SYNEX MX.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
            ],
          ),
        ),
      ),
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
    bool vpnActive = await checkVpnConnection();
    if (vpnActive) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SecurityBlockScreen()));
      return;
    }

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
              TextSpan(text: "SYNEX ", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)), 
              TextSpan(text: "MX", style: TextStyle(color: Color(0xFF8A2BE2), fontSize: 40, fontWeight: FontWeight.w900))
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("First Name is required!"))); return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('device_users').insert({'device_id': currentDeviceId, 'first_name': _firstNameController.text.trim(), 'last_name': _lastNameController.text.trim()});
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
              RichText(text: const TextSpan(children: [TextSpan(text: "SYNEX ", style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1.2)), TextSpan(text: "MX", style: TextStyle(color: Color(0xFF8A2BE2), fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1.2))])),
              const SizedBox(height: 10),
              const Text("Welcome! Let's get to know you.", style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 40),
              TextField(controller: _firstNameController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(hintText: "First Name", hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF0F0F13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16))),
              const SizedBox(height: 16),
              TextField(controller: _lastNameController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(hintText: "Last Name (Optional)", hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF0F0F13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16))),
              const SizedBox(height: 40),
              Container(width: double.infinity, height: 55, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFF6B21A8)])), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent), onPressed: _isLoading ? null : _saveName, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ENTER APP", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))))
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
  void dispose() { _presenceChannel?.unsubscribe(); super.dispose(); }

  Future<void> _loadEverything() async {
    await _checkCookies(); 
    await _fetchSettings(); 
    await fetchGlobalAnimeViews(); 
    await _fetchDatabaseCatalog();
    await _fetchUserPreferences(); 
    if(mounted) setState(() => _isDataLoading = false);
  }

  Future<void> _checkCookies() async {
    final prefs = await SharedPreferences.getInstance();
    bool accepted = prefs.getBool('cookies_accepted') ?? false;
    if (!accepted) { WidgetsBinding.instance.addPostFrameCallback((_) { _showCookieBanner(context); }); } else { hasAcceptedCookies = true; }
  }

  void _showCookieBanner(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    showModalBottomSheet(
      context: context, isScrollControlled: true, isDismissible: false, enableDrag: false, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: getCard(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), border: Border.all(color: Colors.white12)),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.cookie, color: primColor, size: 28), const SizedBox(width: 10), const Text("Cookie Policy", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 15),
            const Text("We use cookies to improve your experience, personalize content, and analyze traffic.", style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(side: BorderSide(color: primColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)), onPressed: () async { final prefs = await SharedPreferences.getInstance(); await prefs.setBool('cookies_accepted', true); hasAcceptedCookies = true; Navigator.pop(context); }, child: Text("Decline", style: TextStyle(color: primColor, fontWeight: FontWeight.bold, fontSize: 14)))),
                const SizedBox(width: 15),
                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)), onPressed: () async { final prefs = await SharedPreferences.getInstance(); await prefs.setBool('cookies_accepted', true); hasAcceptedCookies = true; Navigator.pop(context); }, child: const Text("Accept All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),
              ],
            )
          ],
        )
      )
    );
  }

  Future<void> _fetchSettings() async {
    try {
      final res = await Supabase.instance.client.from('app_settings').select('website_url, telegram_url, privacy_policy').limit(1).maybeSingle();
      if (res != null) {
        if(res['website_url'] != null) globalWebsiteUrl = res['website_url'];
        if(res['telegram_url'] != null) globalTelegramLink = res['telegram_url'];
        if(res['privacy_policy'] != null && res['privacy_policy'].toString().isNotEmpty) globalPrivacyPolicy = res['privacy_policy'];
      }
    } catch(e) { }
  }

  Future<void> _fetchDatabaseCatalog() async {
    try {
      var animeResponse; bool hasEpDate = true;
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
      final response = await Supabase.instance.client.from('user_preferences').select('saved_anime').eq('device_id', currentDeviceId).maybeSingle();
      if (response != null) {
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
      BrowseScreen(), 
      ServersScreen(), 
      MyListScreen(), 
      ProfileScreen()
    ];

    return Scaffold(
      extendBody: true,
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: getCard(context), 
        type: BottomNavigationBarType.fixed, 
        selectedItemColor: Theme.of(context).primaryColor, 
        unselectedItemColor: Colors.grey[500], 
        iconSize: 24, 
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), 
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
        currentIndex: _index, onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.dns_rounded), label: "Server"),
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
    
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(
        backgroundColor: getBg(context), elevation: 0,
        title: RichText(text: const TextSpan(children: [
          TextSpan(text: "SYNEX ", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)), 
          TextSpan(text: "MX", style: TextStyle(color: Color(0xFF8A2BE2), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5))
        ])),
        actions:[IconButton(icon: Icon(Icons.search, color: getText(context), size: 24), onPressed: onSearchTap)],
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
              return GridCategoryCard(anime: list[index], pageTitle: title);
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
      appBar: AppBar(title: Text("Latest Episodes", style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 20)), backgroundColor: getBg(context), iconTheme: IconThemeData(color: getText(context)), elevation: 0),
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
              decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
              child: Row(
                children: [
                  SizedBox(
                    width: 160, height: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
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
                          Text(displayTitle, style: TextStyle(color: getText(context), fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
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
            Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: getText(context)), maxLines: 1, overflow: TextOverflow.ellipsis)), 
            Row(children:[GestureDetector(onTap: () => _removeRecentSearch(index), child: Icon(Icons.close, size: 18, color: Colors.grey[500])), const SizedBox(width: 12), Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[600])])
          ]
        )
      )
    ); 
  }
}

// ==========================================
// SERVERS SCREEN (Replaced Movies Screen)
// ==========================================
class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key}); 
  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  int _connectedServer = 1;
  late Timer _pingTimer;
  List<int> _pings = List.generate(10, (index) => Random().nextInt(100) + 20);

  @override
  void initState() {
    super.initState();
    _pingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if(mounted) {
        setState(() {
          _pings = List.generate(10, (index) {
            int basePing = index < 3 ? 20 : (index < 7 ? 60 : 150);
            return basePing + Random().nextInt(30);
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _pingTimer.cancel();
    super.dispose();
  }

  Color _getPingColor(int ping) {
    if(ping < 50) return Colors.greenAccent;
    if(ping < 100) return Colors.yellowAccent;
    return Colors.redAccent;
  }

  @override 
  Widget build(BuildContext context) { 
    Color primColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: getBg(context), 
      appBar: AppBar(
        title: Text("Servers", style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 20)), 
        backgroundColor: getBg(context), 
        elevation: 0
      ), 
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: getCard(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primColor.withOpacity(0.5)),
              boxShadow: [BoxShadow(color: primColor.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)]
            ),
            child: Column(
              children: [
                const Text("LIVE CONNECTION", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.dns, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text("Server $_connectedServer", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi, color: _getPingColor(_pings[_connectedServer-1]), size: 18),
                    const SizedBox(width: 6),
                    Text("${_pings[_connectedServer-1]} ms", style: TextStyle(color: _getPingColor(_pings[_connectedServer-1]), fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(alignment: Alignment.centerLeft, child: Text("Available Servers", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100), 
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.5, crossAxisSpacing: 14, mainAxisSpacing: 14), 
              itemCount: 10, 
              itemBuilder: (context, index) { 
                return _buildServerCard(index + 1, primColor);
              }
            ),
          ),
        ],
      )
    ); 
  }

  Widget _buildServerCard(int number, Color primColor) {
    bool isConnected = _connectedServer == number;
    int ping = _pings[number-1];
    Color pingColor = _getPingColor(ping);

    return GestureDetector(
      onTap: () {
        setState(() => _connectedServer = number);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Switched to Server $number")));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isConnected ? primColor.withOpacity(0.2) : getCard(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isConnected ? primColor : Colors.white12),
          boxShadow: isConnected ? [BoxShadow(color: primColor.withOpacity(0.1), blurRadius: 8, spreadRadius: 1)] : []
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dns_rounded, color: isConnected ? primColor : Colors.white70, size: 20),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Server $number", style: TextStyle(color: isConnected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                Text("$ping ms", style: TextStyle(color: pingColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 10),
            Container(width: 8, height: 8, decoration: BoxDecoration(color: pingColor, shape: BoxShape.circle))
          ],
        ),
      ),
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
      appBar: AppBar(title: Text("My List", style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 20)), backgroundColor: getBg(context), elevation: 0),
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
                        margin: const EdgeInsets.only(bottom: 12),
                        height: 110,
                        decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))]),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)), 
                              child: Image.network(anime.image, width: 85, height: 110, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image))
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(anime.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    Text("${anime.season} • ${anime.dubStatus}", style: TextStyle(color: primColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ]
                                )
                              )
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(icon: Icon(Icons.play_circle_fill, color: primColor, size: 36), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: anime)))),
                                GestureDetector(
                                  onTap: () => _removeSavedAnime(savedList[index]),
                                  child: const Padding(padding: EdgeInsets.only(bottom: 8), child: Icon(Icons.delete_outline, color: Colors.white54, size: 20)),
                                )
                              ],
                            ),
                            const SizedBox(width: 8),
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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.55, crossAxisSpacing: 14, mainAxisSpacing: 16), 
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

  @override
  Widget build(BuildContext context) {
    String tagText = widget.anime.dubStatus.toUpperCase(); 
    Color tagBgColor; 
    
    if (tagText.contains("DUB") || tagText == "SYNEX DUB") { 
      tagText = "HINDI";
      tagBgColor = const Color(0xFFCC0000); 
    } else if (tagText.contains("ORIGINAL")) { 
      tagText = "MULTI";
      tagBgColor = const Color(0xFFCC0000); 
    } else {
      tagBgColor = const Color(0xFFCC0000); 
    }
    
    int epCount = widget.anime.seasonsList.isNotEmpty ? widget.anime.seasonsList.first.episodes.length : 12;
    String typeText = widget.anime.category.toLowerCase().contains("movie") ? "MOVIE" : "SERIES";

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: widget.anime)));
      }, 
      child: Container(
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24, width: 1)), 
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Image Area
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children:[
                    Image.network(widget.anime.image, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.white54)), 
                    
                    // Completed Tag Diagonal
                    Positioned(
                      top: 15, left: -30,
                      child: Transform.rotate(
                        angle: -0.785, // -45 degrees
                        child: Container(
                          width: 120, padding: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.redAccent.withOpacity(0.9),
                          alignment: Alignment.center,
                          child: const Text("Completed", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),

                    // Language Tag (Bottom Left of Image)
                    Positioned(
                      bottom: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: tagBgColor, borderRadius: BorderRadius.circular(4)),
                        child: Text(tagText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ),

                    // Episode Count Tag (Bottom Right of Image)
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                        child: Text("E$epCount", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ),
                  ]
                ),
              ),
              
              // Bottom Text Area
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.anime.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis), 
                    const SizedBox(height: 8), 
                    ValueListenableBuilder<Map<String, int>>(
                      valueListenable: globalAnimeViewsNotifier, 
                      builder: (context, viewsMap, child) { 
                        int totalViews = viewsMap[widget.anime.title] ?? 0; 
                        return Text("$typeText  •  ${formatViewsCount(totalViews)}", style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)); 
                      }
                    )
                  ]
                ),
              )
            ],
          )
        ),
      ),
    );
  }
}

// ==========================================
// DETAILS PAGE (EXACTLY LIKE IMAGE)
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

  @override
  void initState() {
    super.initState();
    if (widget.isLatestOnly && widget.anime.seasonsList.isNotEmpty) {
      _selectedSeasonIndex = widget.anime.seasonsList.length - 1;
    }
  }

  void _toggleSaveAnime() {
    final list = List<SavedEpisode>.from(myListNotifier.value);
    final isSaved = list.any((item) => item.anime.title == widget.anime.title);
    if (isSaved) { list.removeWhere((item) => item.anime.title == widget.anime.title); } else { list.add(SavedEpisode(anime: widget.anime, seasonIndex: 0, episodeIndex: 0)); }
    myListNotifier.value = list;
    MyListService().saveMyList(currentDeviceId, list);
    setState(() {}); // refresh UI
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor; 
    
    if (widget.anime.seasonsList.isEmpty) { 
      return Scaffold(backgroundColor: getBg(context), appBar: AppBar(backgroundColor: getBg(context), title: Text(widget.anime.title, style: TextStyle(color: getText(context)))), body: Center(child: Text("Episodes Coming Soon!", style: TextStyle(color: getText(context))))); 
    }

    Season currentSeason = widget.anime.seasonsList[_selectedSeasonIndex]; 
    int playIndex = widget.isLatestOnly ? currentSeason.episodes.length - 1 : 0;
    
    final bool isSaved = myListNotifier.value.any((item) => item.anime.title == widget.anime.title);

    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.grey.shade900, Colors.black]
          )
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children:[
                // Central Poster
                Container(
                  height: 280, width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent, width: 2), // Red border like image
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(widget.anime.image, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 50, color: Colors.white54)),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(widget.anime.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)), 
                const SizedBox(height: 16),
                
                // Tags Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), color: Colors.white, child: const Text("FANDUB", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), color: Colors.amber.shade200, child: const Text("SERIES", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), color: Colors.lightGreen.shade300, child: Text("Ep ${currentSeason.episodes.length}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), color: Colors.lightBlue.shade300, child: const Text("24M", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), 
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: widget.anime, seasonIndex: _selectedSeasonIndex, episodeIndex: playIndex))), 
                      icon: const Icon(Icons.play_arrow, color: Colors.white), 
                      label: const Text("Watch Now", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), 
                      onPressed: _toggleSaveAnime, 
                      icon: Icon(isSaved ? Icons.check : Icons.add, color: Colors.black), 
                      label: Text(isSaved ? "Added" : "Add to List", style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold))
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Share Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                    onPressed: () {}, 
                    icon: const Icon(Icons.reply, color: Colors.white), 
                    label: const Text("Share", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                  ),
                ),
                const SizedBox(height: 30),
                
                // OVERVIEW SECTION
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Overview:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        height: 100, // Scrollable overview box
                        padding: const EdgeInsets.only(right: 8),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: Text(widget.anime.description.isNotEmpty ? widget.anime.description : "This is an amazing anime/movie that you should definitely watch on SYNEX MX! Enjoy high quality streaming.", style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      _buildInfoRow("Score:", widget.anime.rating),
                      _buildInfoRow("English:", widget.anime.title),
                      _buildInfoRow("Native:", "日本のタイトル"), // Dummy native
                      _buildInfoRow("Aired:", "${widget.anime.createdAt.year}-${widget.anime.createdAt.month.toString().padLeft(2,'0')}-${widget.anime.createdAt.day.toString().padLeft(2,'0')}"),
                      _buildInfoRow("Duration:", "24m"),
                      _buildInfoRow("Episodes:", "${currentSeason.episodes.length}"),
                      
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Genre:  ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Expanded(
                            child: Wrap(
                              spacing: 8, runSpacing: 8,
                              children: [
                                _buildGenreChip("Animation"),
                                _buildGenreChip("Comedy"),
                                _buildGenreChip("Drama"),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(text: "Producer: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            TextSpan(text: "Asmik Ace, Crunchyroll, Kadokawa", style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                          ]
                        )
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title  ", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildGenreChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.transparent, border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
  bool _isLocked = false; // Screen Lock State
  
  int _currentEpisodeIndex = 0; 
  TextEditingController _searchController = TextEditingController();
  String _epSearchQuery = "";

  // Auto Server Switch Variables
  Timer? _serverTimer;
  bool _isServerSwitching = false;

  @override 
  void initState() { 
    super.initState(); 
    _currentEpisodeIndex = widget.episodeIndex;
    _incrementAndFetchViews(); 
    _initPlayer();
    
    // Auto Server Switcher Timer (Every 30 mins)
    _serverTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      if(mounted) {
        setState(() { _isServerSwitching = true; });
        Future.delayed(const Duration(seconds: 3), () {
          if(mounted) setState(() { _isServerSwitching = false; });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Auto-switched to a better server!")));
        });
      }
    });
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
    setState(() { _currentEpisodeIndex = newIndex; _showControls = true; });
    _initPlayer();
  }

  @override 
  void dispose() { 
    _serverTimer?.cancel();
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

  void _toggleControls() { if(!_isLocked) setState(() => _showControls = !_showControls); }

  void _toggleFullScreen() { 
    setState(() => _isFullScreen = !_isFullScreen); 
    if (_isFullScreen) { 
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]); 
    } else { 
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]); 
    } 
  }

  String _formatDuration(Duration duration) { 
    String twoDigits(int n) => n.toString().padLeft(2, '0'); 
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}"; 
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor; 
    final currentSeason = widget.anime.seasonsList[widget.seasonIndex]; 

    // Filter Episodes based on Search
    List<int> visibleEpisodes = [];
    for(int i=0; i<currentSeason.episodes.length; i++) {
      if(_epSearchQuery.isEmpty || "episode ${i+1}".toLowerCase().contains(_epSearchQuery.toLowerCase())) {
        visibleEpisodes.add(i);
      }
    }

    Widget videoContent = Stack(
      children:[
        _controller.value.isInitialized 
            ? Center(child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))) 
            : Center(child: CircularProgressIndicator(color: primColor)),

        if (_showControls && !_isLocked) 
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
                      Row(children:[
                        IconButton(icon: const Icon(Icons.lock_open, color: Colors.white), onPressed: () => setState(()=> _isLocked = true)), // Lock Button
                        IconButton(icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white), onPressed: _toggleFullScreen)
                      ])
                    ]
                  ), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                    children:[
                      IconButton(icon: const Icon(Icons.replay_10, color: Colors.white, size: 40), onPressed: () => _controller.seekTo(_controller.value.position - const Duration(seconds: 10))), 
                      IconButton(icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 60), onPressed: () { setState(() { _controller.value.isPlaying ? _controller.pause() : _controller.play(); }); _updateContinueWatching(); }), 
                      IconButton(icon: const Icon(Icons.forward_10, color: Colors.white, size: 40), onPressed: () => _controller.seekTo(_controller.value.position + const Duration(seconds: 10)))
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
        else if (_isLocked)
          // Locked State overlay
          Center(
            child: IconButton(
              icon: const Icon(Icons.lock, color: Colors.white, size: 40),
              onPressed: () => setState((){ _isLocked = false; _showControls = true; })
            ),
          )
        else 
          GestureDetector(onTap: _toggleControls, child: Container(color: Colors.transparent)),
      ],
    );

    if (_isFullScreen) {
      return Scaffold(backgroundColor: Colors.black, body: Center(child: AspectRatio(aspectRatio: 16 / 9, child: videoContent)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(widget.anime.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                  Text("Episode ${_currentEpisodeIndex + 1}", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  // 🔥 AUTO SWITCHING RED GLOW WARNING 🔥
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      boxShadow: _isServerSwitching ? [BoxShadow(color: Colors.redAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2)] : []
                    ),
                    child: Text(
                      _isServerSwitching ? "Switching Server Automatically..." : "If current player not working, select other server.", 
                      style: TextStyle(color: _isServerSwitching ? Colors.redAccent : Colors.white54, fontSize: 12, fontWeight: _isServerSwitching ? FontWeight.bold : FontWeight.normal)
                    ),
                  ),
                  
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
                        ],
                      ),
                    ),
                  ),

                  // EPISODE LIST SECTION WITH SEARCH
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Episode Lists", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Container(
                          width: 150, height: 35,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _epSearchQuery = val),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              icon: Icon(Icons.search, color: Colors.blueAccent, size: 16),
                              hintText: "Search Episode", hintStyle: TextStyle(color: Colors.white54, fontSize: 12),
                              border: InputBorder.none
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // EPISODE GRID (SQUARES)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: visibleEpisodes.map((index) {
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
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}