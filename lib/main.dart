import 'dart:io'; 
import 'dart:async';
import 'dart:math';
import 'dart:convert'; 
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
import 'package:image_picker/image_picker.dart'; 

const String CURRENT_APP_VERSION = "1.0.1"; 

// SUPABASE AUTH UUID & USER INFO
String currentUserId = ""; 
String currentUserUid = ""; 
String currentDeviceName = "Unknown Device";
String currentUserName = "User"; 
bool hasAcceptedCookies = false; 

String globalWebsiteUrl = "https://google.com"; 
String globalTelegramLink = "";
String globalUpiId = "wicvlox.i@oksbi";
String globalPaymentQrUrl = "https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEh4wZ-2FEPEhofbqHtjDJ4fSwQUBK2iiyRtQAtikhZeAoQ1GSwBzWh1qfpaelzZWZBW7C_bTtNUdLDAGm8rK71pV4aJ65jRimqxADOR5m_EV6_lK2bI_Ok7R0PpXoDfaYKTn7VO-_a9pfkhjQj_IrZlGfBiP4TFe-2yBab3wE3g8CV0_VLX9KyW5JfnL0s/s769/IMG_20260425_204423.webp";

String globalPrivacyPolicy = "At AniXplayer, your privacy and security are our highest priorities. We are fully committed to providing a safe streaming experience for both Anime and Movies without compromising your personal data.\n\nData Security & Storage\nWe utilize encryption to protect your hardware identifiers. All your personal preferences—such as your watch history, recent searches, and saved items—are securely synchronized to your device.\n\nContent Information\nAniXplayer provides a vast library of Anime and Movies. To ensure fast and consistent releases, a large portion of our dubbed content is powered by high-quality AI Dubbing technology, alongside our Original dubs.\n\nHardware Tracking\nAniXplayer securely scans and hashes your device's hardware ID to keep your account safe without needing passwords.";

List<String> globalRecentSearches = [];
List<String> recommendedSearches = ["Naruto", "One Piece", "Solo Leveling", "Action", "Romance", "Demon Slayer", "Jujutsu Kaisen", "Movie"];

final ValueNotifier<List<Anime>> animeListNotifier = ValueNotifier([]);
final ValueNotifier<List<Map<String, dynamic>>> heroSliderNotifier = ValueNotifier([]);
final ValueNotifier<List<CWItem>> continueWatchingNotifier = ValueNotifier([]);
final ValueNotifier<List<SavedEpisode>> myListNotifier = ValueNotifier([]);
final ValueNotifier<Map<String, int>> globalAnimeViewsNotifier = ValueNotifier({});
final ValueNotifier<int> connectedServerNotifier = ValueNotifier(1);

const Color animeMxPurple = Color(0xFF8A2BE2); 
final ValueNotifier<Color> primaryColorNotifier = ValueNotifier(animeMxPurple); 

Color getBg(BuildContext context) => Colors.black;
Color getCard(BuildContext context) => const Color(0xFF1A1A1A);
Color getText(BuildContext context) => Colors.white;
Color getSubText(BuildContext context) => Colors.white54;

final List<Color> avatarColors = [Colors.redAccent, Colors.blueAccent, Colors.green, Colors.purpleAccent, Colors.teal, Colors.orange, Colors.pinkAccent, Colors.indigo];

Color getAvatarColor(String input) => input.isEmpty ? Colors.grey : avatarColors[input.codeUnitAt(0) % avatarColors.length];
String getAvatarLetter(String input) => input.isEmpty ? "?" : input[0].toUpperCase();
String formatViewsCount(int views) {
  if (views >= 1000000) return "${(views / 1000000).toStringAsFixed(1)}M";
  if (views >= 1000) return "${(views / 1000).toStringAsFixed(1)}K";
  return views.toString();
}

String getSeasonText(Anime anime) {
  if (anime.category.toLowerCase().contains("movie")) return "MOVIE";
  if (anime.seasonsList.isEmpty) return "SEASON 1";
  List<String> sNums = [];
  for (var s in anime.seasonsList) {
    String num = s.name.replaceAll(RegExp(r'[^0-9]'), '');
    if (num.isNotEmpty) sNums.add(num);
  }
  if (sNums.isEmpty) return "SEASON 1";
  return "SEASON ${sNums.join(',')}";
}

int getTotalEpisodes(Anime anime) {
  if (anime.seasonsList.isEmpty) return 0;
  return anime.seasonsList.fold(0, (sum, season) => sum + season.episodes.length);
}

// ==========================================
// SECURITY & DATABASE CONFIG
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

Future<String> getActualDeviceName() async {
  try {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return "${androidInfo.brand} ${androidInfo.model}";
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    }
  } catch (e) {}
  return "Unknown Device";
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

class CWService {
  Future<void> saveCWList(String userId, List<CWItem> cwList) async {
    final savedData = cwList.map((item) => item.toJson()).toList();
    try { await Supabase.instance.client.from('user_preferences').update({'continue_watching': savedData}).eq('id', userId); } catch (e) {}
  }
}
class RecentSearchesService {
  Future<void> saveRecentSearches(String userId, List<String> searches) async {
    final newSearches = [...searches]; if (newSearches.length > 5) newSearches.removeLast(); 
    try { await Supabase.instance.client.from('user_preferences').update({'recent_searches': jsonEncode(newSearches)}).eq('id', userId); } catch (e) {}
  }
}
class MyListService {
  Future<void> saveMyList(String userId, List<SavedEpisode> savedList) async {
    final savedData = savedList.map((item) => item.toJson()).toList();
    try { await Supabase.instance.client.from('user_preferences').update({'saved_anime': savedData}).eq('id', userId); } catch (e) {}
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
    } catch (e) { return CWItem(anime: allAnime.isNotEmpty ? allAnime[0] : _getDummyAnime(), seasonIndex: 0, episodeIndex: 0, position: const Duration(), totalDuration: const Duration()); }
  }
}

class SavedEpisode {
  final Anime anime; final int seasonIndex; final int episodeIndex;
  SavedEpisode({required this.anime, required this.seasonIndex, required this.episodeIndex});
  Map<String, dynamic> toJson() => {'animeTitle': anime.title, 'seasonIndex': seasonIndex, 'episodeIndex': episodeIndex};
}

class Episode {
  final String id, title, image, duration, views, videoUrl; final DateTime createdAt;
  Episode({required this.id, required this.title, required this.image, required this.duration, this.views = "0", required this.videoUrl, required this.createdAt});
}

class Season {
  final String id, name; final List<Episode> episodes;
  Season({required this.id, required this.name, required this.episodes});
}

class Anime {
  final String id, title, image, genre, rating, dubStatus, season, status, views, category, subCategory, description; 
  final Color dubColor; final List<Season> seasonsList; final bool isNew; final DateTime createdAt; 
  Anime({required this.id, required this.title, required this.image, this.genre = "Action", this.rating = "PG-13", this.dubStatus = "DUB", this.season = "Season 1", this.status = "Ongoing", this.views = "0", this.dubColor = const Color(0xFFFF4D4D), required this.seasonsList, this.category = "", this.subCategory = "", this.isNew = false, this.description = "", required this.createdAt});
}

Anime _getDummyAnime() => Anime(id: '0', title: 'Loading...', image: '', seasonsList: [], createdAt: DateTime.now());

class LatestEpisodeItem {
  final Anime anime; final int seasonIndex, episodeIndex; final Episode episode;
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
  runApp(const AniXApp());
}

Future<void> launchInBrowser(String url) async {
  if (url.isEmpty) return;
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {}
}

class AniXApp extends StatelessWidget {
  const AniXApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: primaryColorNotifier,
      builder: (context, currentColor, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false, themeMode: ThemeMode.dark, title: "AniXplayer",
          darkTheme: ThemeData(brightness: Brightness.dark, primaryColor: currentColor, scaffoldBackgroundColor: Colors.black, useMaterial3: true, splashColor: Colors.transparent, highlightColor: Colors.transparent, appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white)),
          home: const AuthGate(), 
        );
      }
    );
  }
}

// ==========================================
// SKELETON LOADER WIDGET
// ==========================================
class SkeletonLoader extends StatefulWidget {
  final double width; final double height; final double borderRadius;
  const SkeletonLoader({super.key, required this.width, required this.height, this.borderRadius = 10});
  @override _SkeletonLoaderState createState() => _SkeletonLoaderState();
}
class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width, height: widget.height,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(widget.borderRadius), gradient: LinearGradient(colors: [Colors.white10, Colors.white24, Colors.white10], stops: const [0.0, 0.5, 1.0], begin: Alignment(-1.0 + (_controller.value * 2), 0), end: Alignment(0.0 + (_controller.value * 2), 0))),
        );
      },
    );
  }
}

// ==========================================
// VPN & SECURITY BLOCKER SCREEN
// ==========================================
class SecurityBlockScreen extends StatelessWidget {
  final String title;
  final String message;
  const SecurityBlockScreen({super.key, this.title = "Security Violation", this.message = "VPN, Proxy, or unsecured connection detected.\n\nPlease disable any VPN to continue using AniXplayer."});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120000),
      body: Center(child: Padding(padding: const EdgeInsets.all(30.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.shield, color: Colors.redAccent, size: 100), const SizedBox(height: 30), Text(title, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 16), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5))]))),
    );
  }
}

// ==========================================
// SUPABASE AUTH GATE
// ==========================================
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override State<AuthGate> createState() => _AuthGateState();
}
class _AuthGateState extends State<AuthGate> {
  @override void initState() { super.initState(); _checkDeviceAndAuth(); }
  
  Future<void> _checkDeviceAndAuth() async {
    try {
      bool vpnActive = await checkVpnConnection();
      if (vpnActive) { if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SecurityBlockScreen())); return; }
      
      currentDeviceName = await getActualDeviceName();

      // 1. SUPABASE AUTH: Automatic Anonymous Sign-in
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        await Supabase.instance.client.auth.signInAnonymously();
      }
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) { 
        throw Exception("Failed to create User ID."); 
      }
      
      currentUserId = user.id;

      // 2. CHECK IF USER PROFILE EXISTS IN SUPABASE
      final response = await Supabase.instance.client.from('user_preferences').select().eq('id', currentUserId).maybeSingle();
      if (response != null && mounted) { 
        currentUserName = response['name'] ?? "User"; 
        currentUserUid = response['uid'] ?? currentUserId.substring(0,8).toUpperCase();
        
        if (response['status'] == 'Inactive') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SecurityBlockScreen(title: "Account Suspended", message: "Your account has been deactivated by the administrator.")));
          return;
        }
        
        await Supabase.instance.client.from('user_preferences').update({'device_name': currentDeviceName}).eq('id', currentUserId);
        
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen())); 
      } 
      else { 
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NameEntryScreen())); 
      }
    } catch (e) { 
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SecurityBlockScreen(
          title: "Connection Failed", 
          message: "Error: $e\n\nDeveloper: Please check Supabase Authentication settings."
        )));
      }
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [RichText(text: const TextSpan(children: [TextSpan(text: "AniX", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)), TextSpan(text: "player", style: TextStyle(color: Color(0xFF8A2BE2), fontSize: 40, fontWeight: FontWeight.w900))])), const SizedBox(height: 20), const CircularProgressIndicator(color: Color(0xFF8A2BE2))])));
  }
}

class NameEntryScreen extends StatefulWidget {
  const NameEntryScreen({super.key});
  @override State<NameEntryScreen> createState() => _NameEntryScreenState();
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
      String fullName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}".trim();
      String shortUid = currentUserId.replaceAll('-', '').substring(0, 8).toUpperCase();
      
      await Supabase.instance.client.from('user_preferences').insert({
        'id': currentUserId, 
        'device_id': currentDeviceName, 
        'name': fullName, 
        'uid': shortUid,
        'device_name': currentDeviceName,
        'status': 'Active',
        'continue_watching': [],
        'saved_anime': [],
        'recent_searches': []
      });
      
      currentUserName = fullName;
      currentUserUid = shortUid;
      
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
    } catch (e) { 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: $e"), 
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.redAccent
        )); 
      }
    } 
    finally { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.person_pin, color: Color(0xFF8A2BE2), size: 100), const SizedBox(height: 20), RichText(text: const TextSpan(children: [TextSpan(text: "AniX", style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1.2)), TextSpan(text: "player", style: TextStyle(color: Color(0xFF8A2BE2), fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1.2))])), const SizedBox(height: 10), const Text("Welcome! Let's get to know you.", style: TextStyle(color: Colors.white54, fontSize: 14)), const SizedBox(height: 40), TextField(controller: _firstNameController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(hintText: "First Name", hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF0F0F13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16))), const SizedBox(height: 16), TextField(controller: _lastNameController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(hintText: "Last Name (Optional)", hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF0F0F13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16))), const SizedBox(height: 40), Container(width: double.infinity, height: 55, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFF6B21A8)])), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent), onPressed: _isLoading ? null : _saveName, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ENTER APP", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))))]))));
  }
}

// ==========================================
// MAIN SCREEN
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  int _index = 0; bool _isDataLoading = true; RealtimeChannel? _presenceChannel; RealtimeChannel? _dbChannel;
  @override void initState() { super.initState(); _loadEverything(); _initPresence(); _initRealtimeSync(); }
  
  void _initPresence() { 
    _presenceChannel = Supabase.instance.client.channel('online-users'); 
    _presenceChannel?.subscribe((status, [error]) async { 
      if (status == RealtimeSubscribeStatus.subscribed) { 
        await _presenceChannel?.track({'user': currentUserId, 'online_at': DateTime.now().toIso8601String()}); 
      } 
    }); 
  }
  
  void _initRealtimeSync() {
    _dbChannel = Supabase.instance.client.channel('public:user_panel')
      ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'anime_list',
          callback: (payload) => _fetchDatabaseCatalog())
      ..onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'user_preferences',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: currentUserId),
          callback: (payload) => _handleUserUpdate(payload.newRecord))
      ..subscribe();
  }

  void _handleUserUpdate(Map<String, dynamic> newRecord) {
    if (newRecord['status'] == 'Inactive') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SecurityBlockScreen(title: "Account Suspended", message: "Your account has been deactivated by the administrator.")));
    }
  }

  @override void dispose() { _presenceChannel?.unsubscribe(); _dbChannel?.unsubscribe(); super.dispose(); }
  
  Future<void> _loadEverything() async {
    await _fetchSettings(); await _checkForUpdates(context); await fetchGlobalAnimeViews(); await _fetchDatabaseCatalog(); await _fetchUserPreferences(); 
    if(mounted) setState(() => _isDataLoading = false);
  }

  Future<void> _fetchSettings() async {
    try {
      final res = await Supabase.instance.client.from('app_settings').select('website_url, telegram_url, privacy_policy, payment_qr_url, upi_id').limit(1).maybeSingle();
      if (res != null) {
        if(res['website_url'] != null) globalWebsiteUrl = res['website_url'];
        if(res['telegram_url'] != null) globalTelegramLink = res['telegram_url'];
        if(res['privacy_policy'] != null) globalPrivacyPolicy = res['privacy_policy'];
        if(res['payment_qr_url'] != null) globalPaymentQrUrl = res['payment_qr_url'];
        if(res['upi_id'] != null) globalUpiId = res['upi_id'];
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
        String updateUrl = response['apk_url'] ?? globalWebsiteUrl; if (updateUrl.isEmpty) updateUrl = globalWebsiteUrl;
        if (_isVersionGreater(latestVersion, CURRENT_APP_VERSION)) { _showUpdateDialog(updateUrl); }
      }
    } catch (e) {}
  }

  void _showUpdateDialog(String updateUrl) {
    showDialog(
      context: context, barrierDismissible: false, 
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E1E24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 60, height: 60, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF9D4EDD), Color(0xFF6B21A8)])), child: const Icon(Icons.download_rounded, color: Colors.white, size: 30)),
              const SizedBox(height: 16),
              const Text("Install New Version", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
              Text("A new version of AniXplayer is available.\nInstall now to enjoy the latest features.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: const Text("Later", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))))),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(onTap: () { launchInBrowser(updateUrl); Navigator.pop(ctx); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFF6B21A8)]), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: const Text("Install Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))))),
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
      var animeResponse; bool hasEpDate = true;
      try { animeResponse = await Supabase.instance.client.from('anime_list').select('''id, title, description, image_url, rating, genres, dub_status, dub_color, category, sub_category, created_at, anime_seasons (id, season_name, anime_episodes (id, episode_title, image_url, duration, video_url, created_at))''').order('created_at', ascending: false); } 
      catch (e) { hasEpDate = false; animeResponse = await Supabase.instance.client.from('anime_list').select('''id, title, description, image_url, rating, genres, dub_status, dub_color, category, sub_category, created_at, anime_seasons (id, season_name, anime_episodes (id, episode_title, image_url, duration, video_url))''').order('created_at', ascending: false); }

      List<Anime> fetchedAnimeList = [];
      for (var item in animeResponse) {
        DateTime animeDate = DateTime.now().subtract(const Duration(days: 30));
        if (item['created_at'] != null) animeDate = DateTime.tryParse(item['created_at'].toString()) ?? animeDate;
        List<Season> parsedSeasons = []; var seasonsData = item['anime_seasons'] as List<dynamic>? ?? [];
        for (var s in seasonsData) {
          List<Episode> parsedEps = []; var epData = s['anime_episodes'] as List<dynamic>? ?? [];
          for (var e in epData) {
            DateTime epDate = animeDate; if (hasEpDate && e['created_at'] != null) epDate = DateTime.tryParse(e['created_at'].toString()) ?? animeDate;
            parsedEps.add(Episode(id: e['id'].toString(), title: e['episode_title']?.toString() ?? "Episode", image: e['image_url']?.toString() ?? item['image_url'], duration: e['duration']?.toString() ?? "24m", videoUrl: e['video_url']?.toString() ?? "", createdAt: epDate));
          }
          parsedSeasons.add(Season(id: s['id'].toString(), name: s['season_name'].toString(), episodes: parsedEps));
        }
        fetchedAnimeList.add(Anime(id: item['id'].toString(), title: item['title']?.toString() ?? "Unknown", description: item['description']?.toString() ?? "", image: item['image_url']?.toString() ?? "", genre: item['genres']?.toString() ?? "Action", rating: item['rating']?.toString() ?? "PG-13", dubStatus: item['dub_status']?.toString() ?? "DUB", status: item['status']?.toString() ?? "Completed", category: item['category']?.toString() ?? "", subCategory: item['sub_category']?.toString() ?? "", seasonsList: parsedSeasons, createdAt: animeDate));
      }
      animeListNotifier.value = fetchedAnimeList;
      final heroResponse = await Supabase.instance.client.from('hero_slider').select().order('created_at', ascending: false);
      heroSliderNotifier.value = List<Map<String, dynamic>>.from(heroResponse);
    } catch (e) {}
  }

  Future<void> _fetchUserPreferences() async {
    try {
      final response = await Supabase.instance.client.from('user_preferences').select('continue_watching, saved_anime').eq('id', currentUserId).maybeSingle();
      if (response != null) {
        if (response['continue_watching'] != null) {
          final List<dynamic> cwData = response['continue_watching'];
          continueWatchingNotifier.value = cwData.map((data) => CWItem.fromJson(data, animeListNotifier.value)).toList();
        }
        if (response['saved_anime'] != null) {
          final List<dynamic> savedData = response['saved_anime'];
          final List<SavedEpisode> fetchedList = [];
          for (var data in savedData) {
            try { final animeMatch = animeListNotifier.value.firstWhere((anime) => anime.title == data['animeTitle']); fetchedList.add(SavedEpisode(anime: animeMatch, seasonIndex: data['seasonIndex'] ?? 0, episodeIndex: data['episodeIndex'] ?? 0)); } catch (e) { }
          }
          myListNotifier.value = fetchedList;
        }
      }
    } catch (e) {}
  }

  void _goToSearch() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [HomeScreen(onSearchTap: _goToSearch, isDataLoading: _isDataLoading), const BrowseScreen(), const ServersScreen(), const MyListScreen(), const ProfileScreen()];
    return Scaffold(
      extendBody: true, body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: getCard(context), type: BottomNavigationBarType.fixed, selectedItemColor: Theme.of(context).primaryColor, unselectedItemColor: Colors.grey[500], selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
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
  final bool isDataLoading;
  const HomeScreen({super.key, required this.onSearchTap, required this.isDataLoading});

  Widget _buildSkeletonHome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLoader(width: double.infinity, height: 220, borderRadius: 0),
        const SizedBox(height: 20),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SkeletonLoader(width: 150, height: 20)),
        const SizedBox(height: 10),
        SizedBox(height: 260, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: 3, itemBuilder: (c, i) => const Padding(padding: EdgeInsets.only(right: 12), child: SkeletonLoader(width: 140, height: 260)))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(
        backgroundColor: getBg(context), elevation: 0,
        title: RichText(text: const TextSpan(children: [
          TextSpan(text: "AniX", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)), 
          TextSpan(text: "player", style: TextStyle(color: Color(0xFF8A2BE2), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5))
        ])),
        actions:[IconButton(icon: Icon(Icons.search, color: getText(context), size: 24), onPressed: onSearchTap)],
      ),
      body: isDataLoading 
      ? _buildSkeletonHome() 
      : SingleChildScrollView(
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
                        if (isCustom || hero['anime_id'] == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stay tuned for updates!"))); } 
                        else { try { final linkedAnime = animeListNotifier.value.firstWhere((a) => a.id == hero['anime_id'].toString()); Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: linkedAnime, seasonIndex: 0, episodeIndex: 0))); } catch(e) { } }
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
                final mysteryList = allAnime.where((a) => a.category.trim().toLowerCase().contains("mystery") || a.subCategory.trim().toLowerCase().contains("mystery")).toList();
                final horrorList = allAnime.where((a) => a.category.trim().toLowerCase().contains("horror") || a.subCategory.trim().toLowerCase().contains("horror")).toList();
                
                List<Anime> popularList = List.from(allAnime);
                popularList.sort((a, b) {
                  int viewsA = globalAnimeViewsNotifier.value[a.title] ?? 0; int viewsB = globalAnimeViewsNotifier.value[b.title] ?? 0;
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
                    _buildPortraitSection(context, "Recently Added", null, null, allAnime), 
                    if (trendingList.isNotEmpty) _buildPortraitSection(context, "Trending Now", null, null, trendingList),
                    if (popularList.isNotEmpty) _buildPopularSection(context, "Popular Anime", null, null, popularList),
                    if (latestEpisodesFlatList.isNotEmpty) _buildLatestEpisodesSection(context, "Latest Episodes", primColor, latestEpisodesFlatList),
                    if (actionList.isNotEmpty) _buildPortraitSection(context, "Action", null, null, actionList),
                    if (romanceList.isNotEmpty) _buildPortraitSection(context, "Romance", null, null, romanceList),
                    if (comedyList.isNotEmpty) _buildPortraitSection(context, "Comedy", null, null, comedyList),
                    if (mysteryList.isNotEmpty) _buildPortraitSection(context, "Mystery", null, null, mysteryList),
                    if (horrorList.isNotEmpty) _buildPortraitSection(context, "Horror", null, null, horrorList),
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
              Anime anime = list[index];
              String epCount = "E${getTotalEpisodes(anime)}";
              String views = formatViewsCount(globalAnimeViewsNotifier.value[anime.title] ?? 0);
              String bottomLine = anime.category.toLowerCase().contains("movie") ? "MOVIE  ■  $views" : "${getSeasonText(anime)}  ■  $views";
              String tagLang = anime.dubStatus.toUpperCase().contains("DUB") ? "HINDI" : "MULTI";

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: anime, seasonIndex: 0, episodeIndex: 0))), 
                child: Container(
                  width: 140, margin: const EdgeInsets.only(right: 14), 
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24, width: 1)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children:[
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(anime.image, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.white54)),
                              Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 40, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)))),
                              Positioned(bottom: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)), child: Text(tagLang, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                              Positioned(bottom: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)), child: Text(epCount, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))
                            ],
                          )
                        ), 
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(anime.title, style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis), 
                              const SizedBox(height: 4),
                              Text(bottomLine, style: TextStyle(color: getSubText(context), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        )
                      ]
                    ),
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

  Widget _buildPopularSection(BuildContext context, String title, IconData? icon, Color? iconColor, List<Anime> list) {
    Color primColor = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Row(children:[Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: getText(context))), if (icon != null) const SizedBox(width: 6), if (icon != null) Icon(icon, color: iconColor, size: 20)]), 
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
// THUMBNAIL LATEST CARD
// ==========================================
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: item.anime, seasonIndex: item.seasonIndex, episodeIndex: item.episodeIndex))),
      child: Container(
        width: 140, margin: const EdgeInsets.only(right: 14), 
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
                      Image.network(displayImage, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.white54)), 
                      Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.8), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center))),
                      const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 30)), 
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
      final response = await Supabase.instance.client.from('user_preferences').select('recent_searches').eq('id', currentUserId).maybeSingle();
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
    try { await Supabase.instance.client.from('user_preferences').update({'recent_searches': searchesJson}).eq('id', currentUserId); } catch (e) {}
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
                  decoration: InputDecoration(hintText: "Search anime, movies, episodes...", hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14), prefixIcon: Icon(Icons.search, color: Colors.grey[500]), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: Icon(Icons.cancel, color: Colors.grey[600]), onPressed: () { _searchController.clear(); _performSearch(""); }) : null, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16))
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
// SERVERS SCREEN 
// ==========================================
class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key}); 
  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  Timer? _pingTimer;
  int _currentPing = 45;

  @override
  void initState() {
    super.initState();
    _pingTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (mounted) setState(() => _currentPing = Random().nextInt(60) + 20);
    });
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
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
            margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: primColor)),
            child: Row(
              children: [
                Icon(Icons.wifi_tethering, color: primColor, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Currently Connected", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ValueListenableBuilder(
                        valueListenable: connectedServerNotifier,
                        builder: (ctx, val, _) => Text("Server $val", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                      )
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("$_currentPing ms", style: TextStyle(color: _currentPing < 50 ? Colors.green : Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text("Ping", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.5, crossAxisSpacing: 14, mainAxisSpacing: 14), 
              itemCount: 10, 
              itemBuilder: (context, index) { 
                return _buildServerCard(context, index + 1, primColor);
              }
            ),
          ),
        ],
      )
    ); 
  }

  Widget _buildServerCard(BuildContext context, int number, Color primColor) {
    return ValueListenableBuilder(
      valueListenable: connectedServerNotifier,
      builder: (ctx, connectedVal, _) {
        bool isConnected = connectedVal == number;
        return GestureDetector(
          onTap: () {
            connectedServerNotifier.value = number;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connected to Server $number")));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isConnected ? primColor.withOpacity(0.2) : getCard(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isConnected ? primColor : Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dns_rounded, color: isConnected ? primColor : Colors.white70, size: 20),
                const SizedBox(width: 10),
                Text("Server $number", style: TextStyle(color: isConnected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                if (isConnected) ...[
                  const SizedBox(width: 10),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle))
                ]
              ],
            ),
          ),
        );
      }
    );
  }
}

// ==========================================
// MY LIST SCREEN
// ==========================================
class MyListScreen extends StatefulWidget {
  const MyListScreen({super.key});
  @override State<MyListScreen> createState() => _MyListScreenState();
}
class _MyListScreenState extends State<MyListScreen> {
  bool _isLoadingSavedAnime = true;
  @override void initState() { super.initState(); _fetchSavedAnime(); }
  Future<void> _fetchSavedAnime() async {
    try {
      final response = await Supabase.instance.client.from('user_preferences').select('saved_anime').eq('id', currentUserId).maybeSingle();
      if (response != null && response['saved_anime'] != null) {
        final List<dynamic> savedData = response['saved_anime']; final List<SavedEpisode> fetchedList = [];
        for (var data in savedData) { try { final animeMatch = animeListNotifier.value.firstWhere((anime) => anime.title == data['animeTitle']); fetchedList.add(SavedEpisode(anime: animeMatch, seasonIndex: data['seasonIndex'] ?? 0, episodeIndex: data['episodeIndex'] ?? 0)); } catch (e) {} }
        setState(() { myListNotifier.value = fetchedList; _isLoadingSavedAnime = false; });
      } else { setState(() => _isLoadingSavedAnime = false); }
    } catch (e) { setState(() => _isLoadingSavedAnime = false); }
  }

  void _removeSavedAnime(SavedEpisode episode) {
    final list = List<SavedEpisode>.from(myListNotifier.value); list.removeWhere((item) => item.anime.title == episode.anime.title); myListNotifier.value = list; MyListService().saveMyList(currentUserId, list);
  }

  Future<void> _confirmRemoveSavedAnime(BuildContext context, SavedEpisode episode) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: getCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
        title: const Text("Remove from List?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to remove this anime from your list?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove", style: TextStyle(color: Colors.white))
          )
        ]
      )
    );
    if (confirm == true) _removeSavedAnime(episode);
  }

  @override Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(title: Text("My List", style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 20)), backgroundColor: getBg(context), elevation: 0),
      body: _isLoadingSavedAnime ? Center(child: CircularProgressIndicator(color: primColor)) : ValueListenableBuilder<List<SavedEpisode>>(
        valueListenable: myListNotifier,
        builder: (context, savedList, child) {
          if (savedList.isEmpty) return Center(child: Text("Your watch list is empty.", style: TextStyle(color: getSubText(context), fontSize: 16)));
          return ListView.builder(
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100), itemCount: savedList.length, 
            itemBuilder: (context, index) { 
              final anime = savedList[index].anime;
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: anime, seasonIndex: 0, episodeIndex: 0))),
                child: Container(margin: const EdgeInsets.only(bottom: 12), height: 110, decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))]),
                  child: Row(children: [ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)), child: Image.network(anime.image, width: 85, height: 110, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image))), Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(anime.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 6), Text("${anime.season} • ${anime.dubStatus}", style: TextStyle(color: primColor, fontSize: 12, fontWeight: FontWeight.w600))]))), Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [IconButton(icon: Icon(Icons.play_circle_fill, color: primColor, size: 36), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: anime, seasonIndex: 0, episodeIndex: 0)))), GestureDetector(onTap: () => _confirmRemoveSavedAnime(context, savedList[index]), child: const Padding(padding: EdgeInsets.only(bottom: 8), child: Icon(Icons.delete_outline, color: Colors.white54, size: 20)))]), const SizedBox(width: 8)])
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
  @override _ParticlesBackgroundState createState() => _ParticlesBackgroundState();
}
class _ParticlesBackgroundState extends State<ParticlesBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller; List<Particle> particles = [];
  @override void initState() { super.initState(); for (int i = 0; i < 40; i++) { particles.add(Particle()); } _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { return AnimatedBuilder(animation: _controller, builder: (context, child) { for (var p in particles) { p.update(); } return CustomPaint(painter: ParticlePainter(particles, Theme.of(context).primaryColor), size: Size.infinite); }); }
}
class Particle {
  double x = Random().nextDouble() * 400; double y = Random().nextDouble() * 800; double speed = Random().nextDouble() * 1 + 0.5; double radius = Random().nextDouble() * 2 + 1;
  void update() { y -= speed; if (y < 0) { y = 800; x = Random().nextDouble() * 400; } }
}
class ParticlePainter extends CustomPainter {
  final List<Particle> particles; final Color pColor;
  ParticlePainter(this.particles, this.pColor);
  @override void paint(Canvas canvas, Size size) { final paint = Paint()..color = pColor.withOpacity(0.3); for (var p in particles) { double dx = (p.x / 400) * size.width; double dy = (p.y / 800) * size.height; canvas.drawCircle(Offset(dx, dy), p.radius, paint); } }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// PROFILE SCREEN
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key}); 

  Widget _buildGroupedItem(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent, 
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(icon, color: Theme.of(context).primaryColor, size: 22), const SizedBox(width: 14), Text(title, style: TextStyle(color: getText(context), fontSize: 15, fontWeight: FontWeight.w600))]),
              Icon(Icons.arrow_forward_ios, color: getSubText(context).withOpacity(0.5), size: 14),
            ],
          ),
        ),
      ),
    );
  }

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
                  Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primColor, width: 2)), child: CircleAvatar(radius: 45, backgroundColor: getAvatarColor(currentUserName), child: Text(getAvatarLetter(currentUserName), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 16),
                  Text(currentUserName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), 
                  const SizedBox(height: 6),
                  Text("UID: $currentUserUid", style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Device: $currentDeviceName", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 1.0)),
                  const SizedBox(height: 40),
                  
                  Container(
                    margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      _buildGroupedItem(context, title: "Subscription", icon: Icons.workspace_premium, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPage()))),
                      const Divider(color: Colors.white12, height: 1, indent: 50, endIndent: 16),
                      _buildGroupedItem(context, title: "Payment Proof", icon: Icons.receipt_long_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentProofPage()))),
                      const Divider(color: Colors.white12, height: 1, indent: 50, endIndent: 16),
                      _buildGroupedItem(context, title: "Support", icon: Icons.support_agent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage()))),
                      const Divider(color: Colors.white12, height: 1, indent: 50, endIndent: 16),
                      _buildGroupedItem(context, title: "Privacy Policy", icon: Icons.privacy_tip_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()))),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Text("AniXplayer v1.0.1", style: TextStyle(color: Colors.white38, fontSize: 12))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});
  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: getBg(context), appBar: AppBar(title: Text("Premium Plans", style: TextStyle(color: getText(context))), backgroundColor: getBg(context), iconTheme: IconThemeData(color: getText(context))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPlanCard(context, "Basic Plan", "₹99", "1 Month", "Ad free monthly support 24/7", Colors.blueAccent),
          const SizedBox(height: 20),
          _buildPlanCard(context, "Standard Plan", "₹299", "3 Months", "Full access unlimited support 24/7", primColor),
        ],
      ),
    );
  }
  Widget _buildPlanCard(BuildContext context, String title, String price, String duration, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.5), width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(price, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)), Text(" / $duration", style: const TextStyle(color: Colors.white54, fontSize: 14))]),
          const SizedBox(height: 10),
          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 45, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QRCodePaymentPage(planName: title, price: price))), child: const Text("Choose Plan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
        ],
      ),
    );
  }
}

class QRCodePaymentPage extends StatelessWidget {
  final String planName; final String price;
  const QRCodePaymentPage({super.key, required this.planName, required this.price});
  void _launchUPIApp(BuildContext context) async {
    String cleanPrice = price.replaceAll(RegExp(r'[^0-9.]'), "");
    final Uri uri = Uri.parse("upi://pay?pa=$globalUpiId&pn=AniXplayer&am=$cleanPrice&cu=INR&tn=Buy%20$planName");
    if (await canLaunchUrl(uri)) { await launchUrl(uri, mode: LaunchMode.externalApplication); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No UPI App found!"))); }
  }
  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: getBg(context), appBar: AppBar(title: Text("Scan to Pay", style: TextStyle(color: getText(context))), backgroundColor: getBg(context)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Payment for $planName", style: TextStyle(color: getText(context), fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 8),
              Text("Amount to Pay: $price", style: TextStyle(color: primColor, fontSize: 20, fontWeight: FontWeight.w600)), const SizedBox(height: 30),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(globalPaymentQrUrl, width: 220, height: 220, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey)))), const SizedBox(height: 20),
              Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)), child: Column(children: [Text("UPI ID", style: TextStyle(color: getSubText(context), fontSize: 12)), const SizedBox(height: 4), Text(globalUpiId, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))])), const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => _launchUPIApp(context), icon: const Icon(Icons.payment, color: Colors.white), label: const Text("Pay via UPI App", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))), const SizedBox(height: 30),
              Text("After successful payment, click below to submit your screenshot.", style: TextStyle(color: getSubText(context), fontSize: 13, height: 1.5), textAlign: TextAlign.center), const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentProofPage(initialPlan: planName, initialPrice: price))); }, child: const Text("Go to Verification", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentProofPage extends StatefulWidget {
  final String? initialPlan;
  final String? initialPrice;
  const PaymentProofPage({super.key, this.initialPlan, this.initialPrice});
  @override State<PaymentProofPage> createState() => _PaymentProofPageState();
}
class _PaymentProofPageState extends State<PaymentProofPage> {
  String? _selectedPlan; File? _imageFile; final TextEditingController _trxController = TextEditingController(); bool _isSubmitting = false;
  final List<String> _plans = ["Basic Plan", "Standard Plan"];
  @override void initState() { super.initState(); if (widget.initialPlan != null && _plans.contains(widget.initialPlan)) { _selectedPlan = widget.initialPlan; } }
  Future<void> _pickImage() async { final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery); if (pickedFile != null) { setState(() { _imageFile = File(pickedFile.path); }); } }
  Future<void> _submitRequest() async {
    if (_selectedPlan == null || _imageFile == null || _trxController.text.length != 12) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all details correctly."))); return; }
    setState(() => _isSubmitting = true);
    try {
      final ext = _imageFile!.path.split('.').last; final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      await Supabase.instance.client.storage.from('payment_proofs').upload(fileName, _imageFile!);
      String imageUrl = Supabase.instance.client.storage.from('payment_proofs').getPublicUrl(fileName);
      
      String amountStr = widget.initialPrice?.replaceAll(RegExp(r'[^0-9.]'), '') ?? "0";
      double amount = double.tryParse(amountStr) ?? 0.0;

      await Supabase.instance.client.from('payment_requests').insert({
        'user_id': currentUserId, 
        'user_name': currentUserName,
        'uid': currentUserUid,
        'plan': _selectedPlan, 
        'amount': amount,
        'transaction_id': _trxController.text.trim(), 
        'image_path': imageUrl, 
        'status': 'Pending', 
        'created_at': DateTime.now().toIso8601String()
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Proof Submitted!"), backgroundColor: Colors.green)); Navigator.pop(context); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); } finally { if (mounted) setState(() => _isSubmitting = false); }
  }
  @override Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: getBg(context), appBar: AppBar(title: Text("Verify Payment", style: TextStyle(color: getText(context))), backgroundColor: getBg(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Text("Select Plan", style: TextStyle(color: getText(context), fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, dropdownColor: getCard(context), hint: Text("Choose your plan", style: TextStyle(color: getSubText(context))), value: _selectedPlan, items: _plans.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white)))).toList(), onChanged: (v) => setState(() => _selectedPlan = v)))), const SizedBox(height: 20),
            Text("Screenshot", style: TextStyle(color: getText(context), fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
            GestureDetector(onTap: _pickImage, child: Container(width: double.infinity, height: 160, decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(12)), child: _imageFile != null ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover)) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload, color: primColor, size: 40), const SizedBox(height: 10), Text("Tap to upload", style: TextStyle(color: getSubText(context)))]))), const SizedBox(height: 20),
            Text("12-Digit UTR", style: TextStyle(color: getText(context), fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
            TextField(controller: _trxController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)], style: TextStyle(color: getText(context)), decoration: InputDecoration(hintText: "Enter UTR number", filled: true, fillColor: getCard(context), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _isSubmitting ? null : _submitRequest, child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBg(context), appBar: AppBar(title: Text("Support", style: TextStyle(color: getText(context))), backgroundColor: getBg(context)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ListTile(tileColor: getCard(context), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), leading: const Icon(Icons.telegram, color: Colors.blueAccent, size: 30), title: const Text("Telegram Support", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: const Text("Instant Replies", style: TextStyle(color: Colors.white54)), onTap: () => launchInBrowser(globalTelegramLink)),
            const SizedBox(height: 16),
            ListTile(tileColor: getCard(context), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), leading: const Icon(Icons.email, color: Colors.redAccent, size: 30), title: const Text("Email Support", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: const Text("Response in 24 hrs", style: TextStyle(color: Colors.white54)), onTap: () => launchInBrowser("mailto:anixplayer.official@gmail.com")),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget { 
  const PrivacyPolicyPage({super.key});
  @override Widget build(BuildContext context) { 
    return Scaffold(backgroundColor: getBg(context), appBar: AppBar(title: Text("Privacy Policy", style: TextStyle(color: getText(context))), backgroundColor: getBg(context)), body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Text(globalPrivacyPolicy, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)))); 
  } 
}

// ==========================================
// CATEGORY PAGES & CARDS 
// ==========================================
class SeeAllCategoryPage extends StatelessWidget {
  final String title; final List<Anime> animeList; final bool isLatestOnly;
  const SeeAllCategoryPage({super.key, required this.title, required this.animeList, this.isLatestOnly = false});
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBg(context), appBar: AppBar(backgroundColor: getBg(context), elevation: 0, title: Text(title, style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 20)), iconTheme: IconThemeData(color: getText(context))),
      body: GridView.builder(padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 40), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.70, crossAxisSpacing: 14, mainAxisSpacing: 16), itemCount: animeList.length, itemBuilder: (context, index) => GridCategoryCard(anime: animeList[index], pageTitle: title, isLatestOnly: isLatestOnly))
    );
  }
}

class OverlayPopularCard extends StatelessWidget {
  final Anime anime; 
  const OverlayPopularCard({super.key, required this.anime});
  @override Widget build(BuildContext context) {
    String epCount = "E${getTotalEpisodes(anime)}";
    String views = formatViewsCount(globalAnimeViewsNotifier.value[anime.title] ?? 0);
    String bottomLine = anime.category.toLowerCase().contains("movie") ? "MOVIE  ■  $views" : "${getSeasonText(anime)}  ■  $views";
    String tagLang = anime.dubStatus.toUpperCase().contains("DUB") ? "HINDI" : "MULTI";
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: anime, seasonIndex: 0, episodeIndex: 0))), 
      child: Container(
        width: 140, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24, width: 1)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8), 
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Expanded(child: Stack(fit: StackFit.expand, children: [Image.network(anime.image, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.white54)), Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 40, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)))), Positioned(bottom: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)), child: Text(tagLang, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))), Positioned(bottom: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)), child: Text(epCount, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))])), Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(anime.title, style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text(bottomLine, style: TextStyle(color: getSubText(context), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)]))]
          )
        )
      )
    );
  }
}

class GridCategoryCard extends StatefulWidget {
  final Anime anime; final String pageTitle; final bool isLatestOnly;
  const GridCategoryCard({super.key, required this.anime, required this.pageTitle, this.isLatestOnly = false});
  @override State<GridCategoryCard> createState() => _GridCategoryCardState();
}
class _GridCategoryCardState extends State<GridCategoryCard> {
  @override Widget build(BuildContext context) {
    String epCount = "E${getTotalEpisodes(widget.anime)}";
    String views = formatViewsCount(globalAnimeViewsNotifier.value[widget.anime.title] ?? 0);
    String bottomLine = widget.anime.category.toLowerCase().contains("movie") ? "MOVIE  ■  $views" : "${getSeasonText(widget.anime)}  ■  $views";
    String tagLang = widget.anime.dubStatus.toUpperCase().contains("DUB") ? "HINDI" : "MULTI";
    
    return GestureDetector(
      onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: widget.anime, seasonIndex: 0, episodeIndex: 0))); }, 
      child: Container(
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24, width: 1)), 
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8), 
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Expanded(child: Stack(fit: StackFit.expand, children: [Image.network(widget.anime.image, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.white54)), Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 40, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)))), Positioned(bottom: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)), child: Text(tagLang, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))), Positioned(bottom: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)), child: Text(epCount, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))])), Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.anime.title, style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text(bottomLine, style: TextStyle(color: getSubText(context), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)]))]
          )
        )
      )
    );
  }
}

// ==========================================
// SEPARATE DESCRIPTION PAGE 
// ==========================================
class DescriptionPage extends StatelessWidget {
  final Anime anime;
  const DescriptionPage({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0, title: Text(anime.title, style: const TextStyle(color: Colors.white, fontSize: 16))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(anime.description, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6)),
      ),
    );
  }
}

// ==========================================
// FAST LOAD VIDEO PLAYER PAGE (RE-DESIGNED)
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
  double _playbackSpeed = 1.0;
  
  late int _currentSeasonIndex;
  late int _currentEpisodeIndex; 

  @override 
  void initState() { 
    super.initState(); 
    _currentSeasonIndex = widget.seasonIndex;
    _currentEpisodeIndex = widget.episodeIndex;
    
    if (widget.anime.seasonsList.isEmpty || widget.anime.seasonsList[_currentSeasonIndex].episodes.isEmpty) {
      return; 
    }
    
    _incrementAndFetchViews(); 
    _initPlayer();
  }

  void _initPlayer() {
    if (widget.anime.seasonsList.isEmpty || widget.anime.seasonsList[_currentSeasonIndex].episodes.isEmpty) return;
    
    final ep = widget.anime.seasonsList[_currentSeasonIndex].episodes[_currentEpisodeIndex]; 
    _controller = VideoPlayerController.networkUrl(Uri.parse(ep.videoUrl), videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))..initialize().then((_) { 
      if (widget.startPosition != null && _currentEpisodeIndex == widget.episodeIndex) { 
        _controller.seekTo(widget.startPosition!); 
      } 
      setState(() {}); 
      _controller.play(); 
      _controller.setPlaybackSpeed(_playbackSpeed);
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

  void _changeSeason(int newSeasonIndex) {
    if (newSeasonIndex == _currentSeasonIndex) return;
    _updateContinueWatching();
    _controller.pause();
    _controller.dispose();
    setState(() { _currentSeasonIndex = newSeasonIndex; _currentEpisodeIndex = 0; _showControls = true; });
    _initPlayer();
  }

  @override 
  void dispose() { 
    if (widget.anime.seasonsList.isNotEmpty && widget.anime.seasonsList[_currentSeasonIndex].episodes.isNotEmpty) {
      _updateContinueWatching(); 
      _controller.dispose(); 
    }
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]); 
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); 
    super.dispose(); 
  }

  Future<void> _incrementAndFetchViews() async {
    final episodeId = "${widget.anime.title}_${_currentSeasonIndex}_${_currentEpisodeIndex}";
    try {
      final userView = await Supabase.instance.client.from('user_views').select().eq('user_id', currentUserId).eq('episode_id', episodeId).maybeSingle();
      if (userView == null) {
        await Supabase.instance.client.from('user_views').insert({'user_id': currentUserId, 'episode_id': episodeId});
        final response = await Supabase.instance.client.from('episode_views').select('view_count').eq('episode_id', episodeId).maybeSingle();
        int currentViews = response?['view_count'] ?? 0;
        await Supabase.instance.client.from('episode_views').upsert({'episode_id': episodeId, 'view_count': currentViews + 1});
      }
    } catch (e) { }
  }

  void _updateContinueWatching() { 
    if (!_controller.value.isInitialized) return; 
    final pos = _controller.value.position; final dur = _controller.value.duration; 
    if (pos > const Duration(seconds: 2)) { 
      final list = List<CWItem>.from(continueWatchingNotifier.value); 
      final existingIdx = list.indexWhere((item) => item.anime.title == widget.anime.title && item.seasonIndex == _currentSeasonIndex && item.episodeIndex == _currentEpisodeIndex); 
      if (existingIdx != -1) { 
        list[existingIdx].position = pos; list[existingIdx].totalDuration = dur; 
        final item = list.removeAt(existingIdx); list.insert(0, item); 
      } else { list.insert(0, CWItem(anime: widget.anime, seasonIndex: _currentSeasonIndex, episodeIndex: _currentEpisodeIndex, position: pos, totalDuration: dur)); } 
      continueWatchingNotifier.value = list; 
      CWService().saveCWList(currentUserId, list);
    } 
  }

  void _toggleControls() { setState(() => _showControls = !_showControls); }

  void _toggleFullScreen() { 
    setState(() => _isFullScreen = !_isFullScreen); 
    if (_isFullScreen) { 
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]); 
    } else { 
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]); 
    } 
  }

  void _skipForward() { 
    _controller.seekTo(_controller.value.position + const Duration(seconds: 10)); 
  }

  void _skipBackward() { 
    _controller.seekTo(_controller.value.position - const Duration(seconds: 10)); 
  }

  String _formatDuration(Duration duration) { 
    String twoDigits(int n) => n.toString().padLeft(2, '0'); 
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}"; 
  }

  void _toggleSaveAnime() {
    final list = List<SavedEpisode>.from(myListNotifier.value); final isSaved = list.any((item) => item.anime.title == widget.anime.title);
    if (isSaved) { list.removeWhere((item) => item.anime.title == widget.anime.title); } else { list.add(SavedEpisode(anime: widget.anime, seasonIndex: 0, episodeIndex: 0)); }
    myListNotifier.value = list; MyListService().saveMyList(currentUserId, list);
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor; 

    if (widget.anime.seasonsList.isEmpty || widget.anime.seasonsList[_currentSeasonIndex].episodes.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text("Episodes Coming Soon!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
      );
    }

    final currentSeason = widget.anime.seasonsList[_currentSeasonIndex]; 
    List<Episode> displayedEpisodes = currentSeason.episodes;

    Widget videoContent = Stack(
      children:[
        _controller.value.isInitialized 
            ? Center(child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))) 
            : Center(child: CircularProgressIndicator(color: primColor)),

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
                      IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24), onPressed: () { if (_isFullScreen) { _toggleFullScreen(); } else { Navigator.pop(context); } }), 
                      Row(children:[
                        PopupMenuButton<double>(
                          initialValue: _playbackSpeed,
                          onSelected: (speed) {
                            setState(() => _playbackSpeed = speed);
                            _controller.setPlaybackSpeed(speed);
                          },
                          itemBuilder: (context) => [0.5, 1.0, 1.25, 1.5, 2.0].map((s) => PopupMenuItem(value: s, child: Text("${s}x", style: const TextStyle(color: Colors.white)))).toList(),
                          color: getCard(context),
                          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("${_playbackSpeed}x", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                        ),
                        IconButton(icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white), onPressed: _toggleFullScreen)
                      ])
                    ]
                  ), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                    children:[
                      IconButton(icon: const Icon(Icons.replay_10, color: Colors.white, size: 30), onPressed: _skipBackward), 
                      IconButton(icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 45), onPressed: () { setState(() { _controller.value.isPlaying ? _controller.pause() : _controller.play(); }); }), 
                      IconButton(icon: const Icon(Icons.forward_10, color: Colors.white, size: 30), onPressed: _skipForward)
                    ]
                  ), 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), 
                    child: Row(
                      children:[
                        ValueListenableBuilder(valueListenable: _controller, builder: (context, VideoPlayerValue value, child) { return Text(_formatDuration(value.position), style: const TextStyle(color: Colors.white, fontSize: 12)); }), 
                        Expanded(child: ValueListenableBuilder(valueListenable: _controller, builder: (context, VideoPlayerValue value, child) { return SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 3.0, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0), overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0)), child: Slider(activeColor: primColor, inactiveColor: Colors.white24, min: 0.0, max: value.duration.inSeconds.toDouble() == 0 ? 100 : value.duration.inSeconds.toDouble(), value: value.position.inSeconds.toDouble().clamp(0.0, value.duration.inSeconds.toDouble() == 0 ? 100 : value.duration.inSeconds.toDouble()), onChangeStart: (val) { _controller.pause(); }, onChanged: (val) { _controller.seekTo(Duration(seconds: val.toInt())); }, onChangeEnd: (val) { _controller.play(); })); })), 
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
      return Scaffold(backgroundColor: Colors.black, body: Center(child: AspectRatio(aspectRatio: 16 / 9, child: videoContent)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: videoContent),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(widget.anime.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                          ValueListenableBuilder<List<SavedEpisode>>(
                            valueListenable: myListNotifier,
                            builder: (context, savedList, child) {
                              bool isSaved = savedList.any((item) => item.anime.title == widget.anime.title);
                              return IconButton(
                                icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: primColor, size: 28),
                                onPressed: _toggleSaveAnime,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              );
                            }
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(widget.anime.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4)),
                    ),
                    if (widget.anime.description.length > 100)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DescriptionPage(anime: widget.anime))),
                          child: Text("Read More", style: TextStyle(color: primColor, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Episode Lists", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          
                          if (widget.anime.seasonsList.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  dropdownColor: getCard(context),
                                  value: _currentSeasonIndex,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                                  items: List.generate(widget.anime.seasonsList.length, (index) {
                                    return DropdownMenuItem(
                                      value: index,
                                      child: Text(widget.anime.seasonsList[index].name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null && val != _currentSeasonIndex) { _changeSeason(val); }
                                  },
                                )
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
                          spacing: 12, runSpacing: 12,
                          children: List.generate(displayedEpisodes.length, (index) {
                            bool isActive = index == _currentEpisodeIndex;
                            return GestureDetector(
                              onTap: () => _changeEpisode(index),
                              child: Container(
                                width: 55, height: 55,
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.redAccent : getCard(context),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isActive ? Colors.redAccent : Colors.white12)
                                ),
                                child: Center(
                                  child: Text(
                                    "${index + 1}", 
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: isActive ? FontWeight.w900 : FontWeight.bold)
                                  )
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Recommended For You", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220, 
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), itemCount: animeListNotifier.value.length, 
                        itemBuilder: (context, index) { 
                          Anime anime = animeListNotifier.value[index];
                          if(anime.title == widget.anime.title) return const SizedBox.shrink(); // Skip current
                          bool isCompleted = anime.status.toLowerCase() == "completed";
                          String epCount = "E${getTotalEpisodes(anime)}";
                          String views = formatViewsCount(globalAnimeViewsNotifier.value[anime.title] ?? 0);
                          String bottomLine = anime.category.toLowerCase().contains("movie") ? "MOVIE  ■  $views" : "${getSeasonText(anime)}  ■  $views";
                          String tagLang = anime.dubStatus.toUpperCase().contains("DUB") ? "HINDI" : "MULTI";

                          return GestureDetector(
                            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: anime, seasonIndex: 0, episodeIndex: 0))), 
                            child: Container(
                              width: 130, margin: const EdgeInsets.only(right: 12), 
                              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24, width: 1)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, 
                                  children:[
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(anime.image, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.white54)),
                                          if (isCompleted)
                                            Positioned(top: 15, left: -35, child: Transform.rotate(angle: -0.785398, child: Container(color: Colors.redAccent.withOpacity(0.9), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4), child: const Text("Completed", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))),
                                          Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 40, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)))),
                                          Positioned(bottom: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)), child: Text(tagLang, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                                          Positioned(bottom: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)), child: Text(epCount, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))
                                        ],
                                      )
                                    ), 
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(anime.title, style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis), 
                                          const SizedBox(height: 4),
                                          Text(bottomLine, style: TextStyle(color: getSubText(context), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    )
                                  ]
                                ),
                              )
                            )
                          ); 
                        }
                      ),
                    ),
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