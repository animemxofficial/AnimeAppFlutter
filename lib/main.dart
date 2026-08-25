import 'dart:io'; 
import 'dart:async';
import 'dart:math';
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
String currentHardwareId = ""; 
String currentDeviceName = "Unknown Device";
String currentUserName = "User"; 
String localProfileImagePath = ""; 

String globalWebsiteUrl = "https://google.com"; 
String globalTelegramLink = "";
String globalWhatsappLink = "https://wa.me/"; 
String globalUpiId = "wicvlox.i@oksbi";
String globalPaymentQrUrl = "https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEh4wZ-2FEPEhofbqHtjDJ4fSwQUBK2iiyRtQAtikhZeAoQ1GSwBzWh1qfpaelzZWZBW7C_bTtNUdLDAGm8rK71pV4aJ65jRimqxADOR5m_EV6_lK2bI_Ok7R0PpXoDfaYKTn7VO-_a9pfkhjQj_IrZlGfBiP4TFe-2yBab3wE3g8CV0_VLX9KyW5JfnL0s/s769/IMG_20260425_204423.webp";

String globalPrivacyPolicy = "At AniXplayer, your privacy and security are our highest priorities. We are fully committed to providing a safe streaming experience...";
String globalTermsConditions = "Terms and Conditions will be updated soon."; 

List<String> globalRecentSearches = [];
List<String> globalRecommendedSearches = ["Naruto", "One Piece", "Solo Leveling", "Action", "Romance", "Demon Slayer", "Jujutsu Kaisen", "Movie"];

final ValueNotifier<List<Anime>> animeListNotifier = ValueNotifier([]);
final ValueNotifier<List<Map<String, dynamic>>> heroSliderNotifier = ValueNotifier([]);
final ValueNotifier<List<CWItem>> continueWatchingNotifier = ValueNotifier([]);
final ValueNotifier<List<SavedEpisode>> myListNotifier = ValueNotifier([]);
final ValueNotifier<Map<String, int>> globalAnimeViewsNotifier = ValueNotifier({});

const Color animeMxPurple = Color(0xFF8A2BE2); 
final ValueNotifier<Color> primaryColorNotifier = ValueNotifier(animeMxPurple); 

Color getBg(BuildContext context) => Colors.black;
Color getCard(BuildContext context) => const Color(0xFF13131A); 
Color getText(BuildContext context) => Colors.white;
Color getSubText(BuildContext context) => Colors.white54;

final List<Color> avatarColors = [Colors.redAccent, Colors.blueAccent, Colors.green, Colors.purpleAccent, Colors.teal, Colors.orange, Colors.pinkAccent, Colors.indigo];

Color getAvatarColor(String input) => input.isEmpty ? Colors.grey : avatarColors[input.codeUnitAt(0) % avatarColors.length];
String getAvatarLetter(String input) => input.isEmpty ? "?" : input[0].toUpperCase();

String formatViewsCount(int views) {
  if (views >= 1000000) return "${(views / 1000000).toStringAsFixed(1)}M";
  if (views >= 1000) return "${(views / 1000).toStringAsFixed(1)}k";
  return views.toString();
}

String getSeasonText(Anime anime) {
  if (anime.category.toLowerCase().contains("movie")) return "MOVIE";
  if (anime.seasonsList.isEmpty) return "S1";
  List<String> sNums = [];
  for (var s in anime.seasonsList) {
    String num = s.name.replaceAll(RegExp(r'[^0-9]'), '');
    if (num.isNotEmpty) sNums.add(num);
  }
  if (sNums.isEmpty) return "S1";
  return "S${sNums.join(',')}";
}

int getTotalEpisodes(Anime anime) {
  if (anime.seasonsList.isEmpty) return 0;
  return anime.seasonsList.fold(0, (sum, season) => sum + season.episodes.length);
}

int getFirstValidSeason(Anime anime) {
  if (anime.seasonsList.isEmpty) return 0;
  int idx = anime.seasonsList.indexWhere((s) => s.episodes.isNotEmpty);
  return idx == -1 ? 0 : idx;
}

DateTime? getPlanExpiryDate(String createdAt, String planName) {
  DateTime start = DateTime.parse(createdAt).toLocal();
  if (planName.toLowerCase().contains("7 days") || planName.toLowerCase().contains("bronze")) return start.add(const Duration(days: 7));
  if (planName.toLowerCase().contains("1 month") || planName.toLowerCase().contains("silver") || planName.toLowerCase().contains("basic")) return start.add(const Duration(days: 30));
  if (planName.toLowerCase().contains("3 month") || planName.toLowerCase().contains("gold") || planName.toLowerCase().contains("standard")) return start.add(const Duration(days: 90));
  if (planName.toLowerCase().contains("6 month") || planName.toLowerCase().contains("premium")) return start.add(const Duration(days: 180));
  return start.add(const Duration(days: 30)); 
}

Future<bool?> showCustomDeleteDialog(BuildContext context, String title, String actionText) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF13131A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white54, fontSize: 16)),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(actionText, style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
                )
              ],
            )
          ],
        ),
      ),
    )
  );
}

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
  return digest.toString().substring(0, 16).toUpperCase(); 
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String secureUrl = utf8.decode(base64Decode('aHR0cHM6Ly95bmd6ZmdmcHl1ZnVzcmJpdGFnbC5zdXBhYmFzZS5jbw=='));
  String secureKey = utf8.decode(base64Decode('c2JfcHVibGlzaGFibGVfNkJEMG1vRXBPblVUZmloYlJVcGRPUV9VMmdKQ0g1VQ=='));
  await Supabase.initialize(url: secureUrl, anonKey: secureKey);
  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  localProfileImagePath = prefs.getString('local_avatar_path') ?? "";

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
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      themeMode: ThemeMode.dark, 
      title: "AniXplayer",
      darkTheme: ThemeData(
        brightness: Brightness.dark, 
        primaryColor: animeMxPurple, 
        scaffoldBackgroundColor: Colors.black, 
        useMaterial3: true, 
        splashColor: Colors.transparent, 
        highlightColor: Colors.transparent, 
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white)
      ),
      home: const AuthGate(), 
    );
  }
}

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

class SearchListSkeleton extends StatelessWidget {
  const SearchListSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 110, height: 160, borderRadius: 8),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLoader(width: double.infinity, height: 20, borderRadius: 4),
                SizedBox(height: 8),
                SkeletonLoader(width: 150, height: 14, borderRadius: 4),
                SizedBox(height: 8),
                SkeletonLoader(width: 100, height: 14, borderRadius: 4),
                SizedBox(height: 12),
                SkeletonLoader(width: double.infinity, height: 10, borderRadius: 2),
                SizedBox(height: 4),
                SkeletonLoader(width: double.infinity, height: 10, borderRadius: 2),
                SizedBox(height: 4),
                SkeletonLoader(width: 180, height: 10, borderRadius: 2),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class SecurityBlockScreen extends StatelessWidget {
  final String title;
  final String message;
  final bool isSuspended;
  const SecurityBlockScreen({super.key, this.title = "Security Violation", this.message = "VPN, Proxy, or unsecured connection detected.\n\nPlease disable any VPN to continue using AniXplayer.", this.isSuspended = false});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0), 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Icon(isSuspended ? Icons.gavel_rounded : Icons.security_rounded, color: Colors.redAccent, size: 80),
              const SizedBox(height: 32), 
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900), textAlign: TextAlign.center), 
              const SizedBox(height: 16), 
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6)),
              if(isSuspended) ...[
                const SizedBox(height: 40),
                SizedBox(
                  height: 50, width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => launchInBrowser(globalTelegramLink), 
                    icon: const Icon(Icons.support_agent, color: Colors.white),
                    label: const Text("Contact Support", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  )
                )
              ]
            ]
          )
        )
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override State<AuthGate> createState() => _AuthGateState();
}
class _AuthGateState extends State<AuthGate> {
  
  @override void initState() { 
    super.initState(); 
    _checkDeviceAndAuth(); 
  }

  Future<void> _checkDeviceAndAuth() async {
    try {
      bool vpnActive = await checkVpnConnection();
      if (vpnActive) { if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SecurityBlockScreen())); return; }
      
      currentHardwareId = await getHardwareDeviceId(); 
      currentDeviceName = await getActualDeviceName();

      final existingUser = await Supabase.instance.client.from('user_preferences').select().eq('device_id', currentHardwareId).maybeSingle();
      
      if (existingUser != null) {
        currentUserId = existingUser['id']; 
        currentUserName = existingUser['name'] ?? "User";
        currentUserUid = existingUser['uid'] ?? currentUserId.substring(0,8).toUpperCase();
        
        if (existingUser['status'] == 'Inactive') {
          if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SecurityBlockScreen(title: "Account Suspended", message: "Your account has been restricted due to violation of policies.", isSuspended: true)));
          return;
        }
        if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
        return;
      }

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        await Supabase.instance.client.auth.signInAnonymously();
      }
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) { throw Exception("Failed to create User Session."); }
      
      currentUserId = user.id;
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NameEntryScreen())); 

    } catch (e) { 
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SecurityBlockScreen(
          title: "Connection Failed", 
          message: "Error: $e\n\nPlease check your internet connection and restart the app."
        )));
      }
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            RichText(text: const TextSpan(children: [TextSpan(text: "AniX", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)), TextSpan(text: "player", style: TextStyle(color: Color(0xFF8A2BE2), fontSize: 40, fontWeight: FontWeight.w900))])),
            const SizedBox(height: 20), 
            const CircularProgressIndicator(color: Color(0xFF8A2BE2))
          ]
        )
      )
    );
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
        'device_id': currentHardwareId, 
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
    return Scaffold(backgroundColor: Colors.black, body: Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.person_pin, color: Color(0xFF8A2BE2), size: 100), const SizedBox(height: 20), RichText(text: const TextSpan(children: [TextSpan(text: "AniX", style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1.2)), TextSpan(text: "player", style: TextStyle(color: Color(0xFF8A2BE2), fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1.2))])), const SizedBox(height: 10), const Text("Welcome! Let's get to know you.", style: TextStyle(color: Colors.white54, fontSize: 14)), const SizedBox(height: 40), TextField(controller: _firstNameController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(hintText: "First Name", hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF16161E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16))), const SizedBox(height: 16), TextField(controller: _lastNameController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(hintText: "Last Name (Optional)", hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF16161E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16))), const SizedBox(height: 40), Container(width: double.infinity, height: 55, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFF6B21A8)])), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent), onPressed: _isLoading ? null : _saveName, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ENTER APP", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))))]))));
  }
}

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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SecurityBlockScreen(title: "Account Suspended", message: "Your account has been restricted due to violation of policies.", isSuspended: true)));
    }
  }

  @override void dispose() { _presenceChannel?.unsubscribe(); _dbChannel?.unsubscribe(); super.dispose(); }
  
  Future<void> _loadEverything() async {
    await _fetchSettings(); await fetchGlobalAnimeViews(); await _fetchDatabaseCatalog(); await _fetchUserPreferences(); 
    if(mounted) setState(() => _isDataLoading = false);
  }

  Future<void> _fetchSettings() async {
    try {
      final res = await Supabase.instance.client.from('app_settings').select('website_url, telegram_url, whatsapp_url, privacy_policy, terms_conditions, recommended_searches, payment_qr_url, upi_id').limit(1).maybeSingle();
      if (res != null) {
        if(res['website_url'] != null) globalWebsiteUrl = res['website_url'];
        if(res['telegram_url'] != null) globalTelegramLink = res['telegram_url'];
        if(res['whatsapp_url'] != null) globalWhatsappLink = res['whatsapp_url'];
        if(res['privacy_policy'] != null) globalPrivacyPolicy = res['privacy_policy'];
        if(res['terms_conditions'] != null) globalTermsConditions = res['terms_conditions'];
        if(res['payment_qr_url'] != null) globalPaymentQrUrl = res['payment_qr_url'];
        if(res['upi_id'] != null) globalUpiId = res['upi_id'];
        
        if(res['recommended_searches'] != null) {
          var recData = res['recommended_searches'];
          if (recData is String) { globalRecommendedSearches = List<String>.from(jsonDecode(recData)); } 
          else if (recData is List) { globalRecommendedSearches = List<String>.from(recData); }
        }
      }
    } catch(e) { }
  }

  Future<void> _fetchDatabaseCatalog() async {
    try {
      var animeResponse; 
      bool hasEpDate = true;
      try { 
        animeResponse = await Supabase.instance.client.from('anime_list').select('''id, title, description, image_url, dub_status, category, sub_category, created_at, anime_seasons (id, season_name, anime_episodes (id, episode_title, image_url, duration, video_url, created_at))''').order('created_at', ascending: false); 
      } 
      catch (e) { 
        hasEpDate = false; 
        animeResponse = await Supabase.instance.client.from('anime_list').select('''id, title, description, image_url, dub_status, category, sub_category, created_at, anime_seasons (id, season_name, anime_episodes (id, episode_title, image_url, duration, video_url))''').order('created_at', ascending: false); 
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
        
        fetchedAnimeList.add(Anime(
          id: item['id'].toString(), 
          title: item['title']?.toString() ?? "Unknown", 
          description: item['description']?.toString() ?? "", 
          image: item['image_url']?.toString() ?? "", 
          genre: item['category']?.toString() ?? "Action", 
          rating: "All Ages", 
          dubStatus: item['dub_status']?.toString() ?? "DUB", 
          status: item['status']?.toString() ?? "Completed", 
          category: item['category']?.toString() ?? "", 
          subCategory: item['sub_category']?.toString() ?? "", 
          seasonsList: parsedSeasons, 
          createdAt: animeDate
        ));
      }
      animeListNotifier.value = fetchedAnimeList;
      
      final heroResponse = await Supabase.instance.client.from('hero_slider').select().order('created_at', ascending: false);
      heroSliderNotifier.value = List<Map<String, dynamic>>.from(heroResponse);
      
    } catch (e) { }
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
    final List<Widget> pages = [HomeScreen(onSearchTap: _goToSearch, isDataLoading: _isDataLoading), const BrowseScreen(), const ExploreScreen(), const MyListScreen(), const ProfileScreen()];
    return Scaffold(
      extendBody: true, body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black, type: BottomNavigationBarType.fixed, selectedItemColor: Theme.of(context).primaryColor, unselectedItemColor: Colors.grey[500], selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
        currentIndex: _index, onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"), 
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "My List"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COMPACT PREMIUM HERO SLIDER WIDGET
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class PremiumHeroSlider extends StatefulWidget {
  final List<Map<String, dynamic>> heroList;
  const PremiumHeroSlider({super.key, required this.heroList});

  @override
  State<PremiumHeroSlider> createState() => _PremiumHeroSliderState();
}

class _PremiumHeroSliderState extends State<PremiumHeroSlider> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.heroList.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % widget.heroList.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleWatchNow(Anime linkedAnime) {
    int sIdx = getFirstValidSeason(linkedAnime);
    Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: linkedAnime, seasonIndex: sIdx, episodeIndex: 0)));
  }

  void _handleMyList(Anime linkedAnime) {
    final list = List<SavedEpisode>.from(myListNotifier.value);
    final isSaved = list.any((item) => item.anime.title == linkedAnime.title);
    if (!isSaved) {
      list.add(SavedEpisode(anime: linkedAnime, seasonIndex: 0, episodeIndex: 0));
      myListNotifier.value = list;
      MyListService().saveMyList(currentUserId, list);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added to My List"), backgroundColor: animeMxPurple, duration: const Duration(seconds: 1)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Already in My List"), duration: Duration(seconds: 1)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.heroList.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 230, // Compact horizontal height to fit naturally on mobile
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24), // Ensures 24px space before 'Recently Added'
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Listener(
          onPointerDown: (_) => _timer?.cancel(),
          onPointerUp: (_) => _startTimer(),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.heroList.length,
            itemBuilder: (context, index) {
              final hero = widget.heroList[index];
              final bool isCustom = hero['is_custom'] ?? false;
              String rawTitle = hero['title'] ?? "";
              String heroTag = hero['tag'] ?? "Top Pick";

              Anime? linkedAnime;
              if (!isCustom && hero['anime_id'] != null) {
                try {
                  linkedAnime = animeListNotifier.value.firstWhere((a) => a.id == hero['anime_id'].toString());
                  if (rawTitle.isEmpty) rawTitle = linkedAnime.title;
                } catch (e) {}
              }

              String displayTitle = rawTitle.isEmpty ? "Anime" : rawTitle;
              String category = linkedAnime?.category ?? "Movie";
              String dubStatus = linkedAnime != null && linkedAnime.dubStatus.toUpperCase().contains("DUB") ? "Hindi Dub" : "Multi";
              String metadata = "$category • $dubStatus";

              String rawGenres = linkedAnime?.genre ?? "Romance, Drama";
              List<String> genres = rawGenres.split(RegExp(r'[,\s]+')).where((e) => e.isNotEmpty).take(2).toList(); // Compact up to 2 genres

              return GestureDetector(
                onTap: () {
                  if (linkedAnime != null) {
                    _handleWatchNow(linkedAnime);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stay tuned for updates!")));
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Backdrop Image
                    Image.network(
                      hero['image_url'],
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter, // Keeps faces/characters visible in a horizontal crop
                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white54),
                    ),

                    // Strong Bottom Gradient for Text Readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.95), 
                            Colors.black.withOpacity(0.4), 
                            Colors.transparent
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0.0, 0.5, 1.0], // Fades nicely letting the top artwork shine
                        ),
                      ),
                    ),

                    // Top Left Badge
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: animeMxPurple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              heroTag,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Content Block
                    Positioned(
                      bottom: 14,
                      left: 14,
                      right: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            displayTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Metadata & Compact Genre Chips Inline
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                metadata,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 10),
                              ...genres.map((genre) => Container(
                                margin: const EdgeInsets.only(right: 6, top: 2, bottom: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  border: Border.all(color: animeMxPurple.withOpacity(0.7), width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  genre,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              )).toList(),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Buttons & Indicator Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Watch Now Button
                              SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  onPressed: () {
                                    if (linkedAnime != null) _handleWatchNow(linkedAnime);
                                  },
                                  icon: const Icon(Icons.play_arrow, size: 18),
                                  label: const Text("Watch Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // My List Button
                              SizedBox(
                                height: 40,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white70),
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.black38,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  onPressed: () {
                                    if (linkedAnime != null) _handleMyList(linkedAnime);
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text("My List", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),

                              const Spacer(),

                              // Custom Indicator (━ ━ ●)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      widget.heroList.length,
                                      (dotIdx) {
                                        bool isActive = _currentPage == dotIdx;
                                        return Container(
                                          width: isActive ? 16 : 6,
                                          height: 4,
                                          margin: const EdgeInsets.only(right: 4),
                                          decoration: BoxDecoration(
                                            color: isActive ? animeMxPurple : Colors.white38,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${_currentPage + 1} / ${widget.heroList.length}",
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  )
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class HomeScreen extends StatelessWidget {
  final VoidCallback onSearchTap;
  final bool isDataLoading;
  const HomeScreen({super.key, required this.onSearchTap, required this.isDataLoading});

  Widget _buildSkeletonHome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24),
          child: SkeletonLoader(width: double.infinity, height: 230, borderRadius: 16),
        ),
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
        title: RichText(text: TextSpan(children: [
          const TextSpan(text: "AniX", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)), 
          TextSpan(text: "player", style: TextStyle(color: primColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5))
        ])),
        actions:[
          IconButton(icon: Icon(Icons.notifications_none, color: getText(context), size: 24), onPressed: () {}),
          IconButton(icon: Icon(Icons.search, color: getText(context), size: 24), onPressed: onSearchTap)
        ],
      ),
      body: isDataLoading 
      ? _buildSkeletonHome() 
      : SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            
            // 🔥 REPLACED OLD SLIDER WITH NEW COMPACT PREMIUM HERO SLIDER 🔥
            ValueListenableBuilder<List<Map<String,dynamic>>>(
              valueListenable: heroSliderNotifier,
              builder: (context, heroList, child) {
                return PremiumHeroSlider(heroList: heroList);
              }
            ),
            
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
                onTap: () {
                  int sIdx = getFirstValidSeason(anime);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: anime, seasonIndex: sIdx, episodeIndex: 0))); 
                },
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

class SearchListCard extends StatelessWidget {
  final Anime anime;
  const SearchListCard({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    int totalEp = getTotalEpisodes(anime);
    int totalSeasons = anime.seasonsList.length;
    String langText = anime.dubStatus.toUpperCase().contains("DUB") ? "Hindi, Japanese" : "Japanese";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                anime.image,
                fit: BoxFit.cover,
                errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(anime.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(4)), 
                  child: const Text("SHOW", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                Text("$langText, ${anime.genre}, ${anime.createdAt.year}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text("$totalSeasons seasons, $totalEp episodes", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Text(anime.description, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: anime.seasonsList.asMap().entries.map((entry) {
                    int sIdx = entry.key;
                    Season s = entry.value;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: anime, seasonIndex: sIdx, episodeIndex: 0))); 
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(4)),
                        child: Text(s.name.isEmpty ? "Season ${sIdx+1}" : s.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key}); 
  @override 
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final TextEditingController _searchController = TextEditingController(); 
  List<Anime> _searchResults = [];
  bool _isLoadingSearches = true;
  bool _isSearching = false;

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
  
  Future<void> _clearAllRecentSearches() async {
    setState(() { globalRecentSearches.clear(); });
    try { await Supabase.instance.client.from('user_preferences').update({'recent_searches': '[]'}).eq('id', currentUserId); } catch (e) {}
  }

  void _performSearch(String query) async { 
    if (query.isEmpty) { 
      setState(() { _searchResults = []; _isSearching = false; }); 
    } else { 
      setState(() { _isSearching = true; });
      await Future.delayed(const Duration(milliseconds: 300)); 
      if(!mounted) return;
      setState(() { 
        _searchResults = animeListNotifier.value.where((anime) {
          return anime.title.toLowerCase().contains(query.toLowerCase()) || anime.genre.toLowerCase().contains(query.toLowerCase()) || anime.category.toLowerCase().contains(query.toLowerCase());
        }).toList(); 
        _isSearching = false;
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
                if (_isSearching)
                  ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 3, itemBuilder: (context, index) => const SearchListSkeleton())
                else if (_searchResults.isEmpty) 
                  const Center(child: Padding(padding: EdgeInsets.only(top: 20), child: Text("No content found.", style: TextStyle(color: Colors.grey, fontSize: 15)))) 
                else 
                  ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _searchResults.length, itemBuilder: (context, index) => SearchListCard(anime: _searchResults[index]))
              ] else ...[
                Text("Recommended", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: getText(context))), 
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: globalRecommendedSearches.map((e) => GestureDetector(
                    onTap: () => _setSearchQuery(e),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                      child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    )
                  )).toList(),
                ),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Recent Searches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: getText(context))),
                    if (globalRecentSearches.isNotEmpty)
                      GestureDetector(
                        onTap: () async {
                          bool? confirm = await showCustomDeleteDialog(context, "Clear all search history?", "Remove");
                          if (confirm == true) {
                            _clearAllRecentSearches();
                          }
                        },
                        child: Text("Clear All", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      )
                  ],
                ), 
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

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _exploreSearchCtrl = TextEditingController();
  String _selectedTag = "";
  List<Anime> _exploreResults = [];
  bool _isSearching = false;
  
  final List<Map<String, dynamic>> _tags = [
    {"name": "Action", "icon": "⚔️"},
    {"name": "Romance", "icon": "❤️"},
    {"name": "Comedy", "icon": "😂"},
    {"name": "Mystery", "icon": "♾️"},
    {"name": "Trailer", "icon": "🎬"},
    {"name": "Horror", "icon": "💀"},
  ];

  @override void initState() { super.initState(); _exploreResults = animeListNotifier.value; }

  void _filterExplore() async {
    setState(() { _isSearching = true; });
    await Future.delayed(const Duration(milliseconds: 300));
    if(!mounted) return;
    String q = _exploreSearchCtrl.text.toLowerCase();
    setState(() {
      _exploreResults = animeListNotifier.value.where((a) {
        bool matchesQ = q.isEmpty || a.title.toLowerCase().contains(q) || a.description.toLowerCase().contains(q);
        bool matchesTag = _selectedTag.isEmpty || a.category.toLowerCase().contains(_selectedTag.toLowerCase()) || a.subCategory.toLowerCase().contains(_selectedTag.toLowerCase());
        return matchesQ && matchesTag;
      }).toList();
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: getBg(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: primColor.withOpacity(0.3))), 
                child: TextField(
                  controller: _exploreSearchCtrl, onChanged: (v) => _filterExplore(), style: TextStyle(color: getText(context), fontSize: 15), 
                  decoration: InputDecoration(hintText: "Search anime...", hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14), prefixIcon: Icon(Icons.search, color: Colors.grey[500]), suffixIcon: const Icon(Icons.filter_alt_outlined, color: Colors.white54), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16))
                )
              ),
            ),
            
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _tags.length,
                itemBuilder: (ctx, i) {
                  bool isSelected = _selectedTag == _tags[i]['name'];
                  return GestureDetector(
                    onTap: () { setState(() { _selectedTag = isSelected ? "" : _tags[i]['name']; }); _filterExplore(); },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: isSelected ? primColor : getCard(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? primColor : Colors.white12)),
                      alignment: Alignment.center,
                      child: Text("${_tags[i]['icon']} ${_tags[i]['name']}", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  );
                }
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _isSearching
              ? GridView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.55, crossAxisSpacing: 10, mainAxisSpacing: 16),
                  itemCount: 6,
                  itemBuilder: (context, index) => const SkeletonLoader(width: double.infinity, height: double.infinity, borderRadius: 10)
                )
              : _exploreResults.isEmpty 
                  ? const Center(child: Text("No anime found.", style: TextStyle(color: Colors.white54)))
                  : GridView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.55, crossAxisSpacing: 10, mainAxisSpacing: 16),
                      itemCount: _exploreResults.length,
                      itemBuilder: (context, index) => ExploreAnimeCard(anime: _exploreResults[index])
                    ),
            )
          ],
        )
      )
    );
  }
}

class ExploreAnimeCard extends StatelessWidget {
  final Anime anime;
  const ExploreAnimeCard({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    int totalEp = getTotalEpisodes(anime);
    String seasonText = getSeasonText(anime);
    String views = formatViewsCount(globalAnimeViewsNotifier.value[anime.title] ?? 0);

    return GestureDetector(
      onTap: () {
        int sIdx = getFirstValidSeason(anime);
        Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: anime, seasonIndex: sIdx, episodeIndex: 0))); 
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 1.5) 
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(anime.image, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.white54)),
              Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.9), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center))),
              Positioned(
                bottom: 10, left: 8, right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(anime.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("$seasonText | Ep $totalEp", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            const Icon(Icons.remove_red_eye, color: Colors.white, size: 10),
                            const SizedBox(width: 4),
                            Text(views, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    )
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
    bool? confirm = await showCustomDeleteDialog(context, "Remove from List?", "Remove");
    if (confirm == true) _removeSavedAnime(episode);
  }

  @override Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("My List", style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 24)),
            const SizedBox(height: 2),
            const Text("Your saved anime, ready to watch anytime.", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ), 
        backgroundColor: getBg(context), elevation: 0, toolbarHeight: 70,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: getCard(context), shape: BoxShape.circle, border: Border.all(color: Colors.white10)), child: Icon(Icons.filter_alt_outlined, color: primColor, size: 20)),
          )
        ],
      ),
      body: _isLoadingSavedAnime ? Center(child: CircularProgressIndicator(color: primColor)) : ValueListenableBuilder<List<SavedEpisode>>(
        valueListenable: myListNotifier,
        builder: (context, savedList, child) {
          if (savedList.isEmpty) return Center(child: Text("Your watch list is empty.", style: TextStyle(color: getSubText(context), fontSize: 16)));
          return ListView.builder(
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100), itemCount: savedList.length, 
            itemBuilder: (context, index) { 
              final anime = savedList[index].anime;
              String tagLang = anime.dubStatus.toUpperCase().contains("DUB") ? "DUB" : "SUB";
              String seasonText = getSeasonText(anime);
              
              final cwList = continueWatchingNotifier.value;
              CWItem? cwItem;
              try {
                cwItem = cwList.firstWhere((item) => item.anime.title == anime.title);
              } catch (e) {}

              String epWatchedText = "Not Started";
              String timeText = "0m / 0m";
              double progressValue = 0.0;

              if (cwItem != null) {
                epWatchedText = "Episode ${cwItem.episodeIndex + 1} • Watched";
                int posMin = cwItem.position.inMinutes;
                int totalMin = cwItem.totalDuration.inMinutes;
                timeText = "${posMin}m / ${totalMin}m";
                if (cwItem.totalDuration.inSeconds > 0) {
                  progressValue = cwItem.position.inSeconds / cwItem.totalDuration.inSeconds;
                }
              }
              
              return GestureDetector(
                onTap: () {
                  int sIdx = getFirstValidSeason(anime);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: anime, seasonIndex: sIdx, episodeIndex: 0)));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12), height: 120, 
                  decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90, height: 120,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)), 
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(anime.image, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                              Positioned(top: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: primColor, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(6))), child: Text(tagLang, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                            ],
                          )
                        ),
                      ), 
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(anime.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), 
                                  const SizedBox(height: 4), 
                                  Text("$seasonText • $tagLang", style: TextStyle(color: primColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(epWatchedText, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progressValue, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(primColor), minHeight: 4))),
                                      const SizedBox(width: 10),
                                      Text(timeText, style: const TextStyle(color: Colors.white54, fontSize: 10))
                                    ],
                                  )
                                ],
                              )
                            ]
                          )
                        )
                      ), 
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                          children: [
                            Container(
                              decoration: BoxDecoration(color: primColor, shape: BoxShape.circle),
                              child: IconButton(icon: const Icon(Icons.play_arrow, color: Colors.white, size: 24), onPressed: () {
                                int sIdx = getFirstValidSeason(anime);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: anime, seasonIndex: sIdx, episodeIndex: 0)));
                              }, constraints: const BoxConstraints(minWidth: 40, minHeight: 40), padding: EdgeInsets.zero)
                            ), 
                            GestureDetector(onTap: () => _confirmRemoveSavedAnime(context, savedList[index]), child: const Icon(Icons.delete_outline, color: Colors.white70, size: 22))
                          ]
                        ),
                      )
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

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override State<EditProfileScreen> createState() => _EditProfileScreenState();
}
class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _selectedImage;

  @override void initState() {
    super.initState();
    if(localProfileImagePath.isNotEmpty) {
      _selectedImage = File(localProfileImagePath);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery); 
    if (pickedFile != null) { 
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_avatar_path', pickedFile.path);
      setState(() { 
        _selectedImage = File(pickedFile.path); 
        localProfileImagePath = pickedFile.path;
      }); 
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Photo Updated! (Saved locally)"), backgroundColor: Colors.green));
    } 
  }

  Future<void> _removeImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('local_avatar_path');
    setState(() { 
      _selectedImage = null; 
      localProfileImagePath = "";
    }); 
  }

  @override Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(title: const Text("My Profile", style: TextStyle(color: Colors.white)), backgroundColor: getBg(context)),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primColor, width: 2)), 
                  child: CircleAvatar(
                    radius: 60, 
                    backgroundColor: getAvatarColor(currentUserName), 
                    backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                    child: _selectedImage == null ? Text(getAvatarLetter(currentUserName), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)) : null
                  )
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.white, size: 20)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Text(currentUserName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("UID: $currentUserUid", style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 40),
            if(_selectedImage != null)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                onPressed: _removeImage, 
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                label: const Text("Remove Photo", style: TextStyle(color: Colors.redAccent))
              )
          ],
        ),
      ),
    );
  }
}

// Custom Animated Progress Bar with Particles
class AnimatedPlanProgressBar extends StatelessWidget {
  final double progress; 
  const AnimatedPlanProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: const Duration(seconds: 2),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double activeWidth = constraints.maxWidth * value;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))
                ),
                Container(
                  height: 8,
                  width: activeWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Colors.pink, Colors.redAccent, Colors.yellow, Colors.blueAccent],
                      begin: Alignment.centerLeft, end: Alignment.centerRight
                    ),
                  ),
                ),
                if (value > 0.0)
                  Positioned(
                    left: activeWidth - 8,
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.blueAccent.withOpacity(0.8), blurRadius: 8, spreadRadius: 2),
                          BoxShadow(color: Colors.pink.withOpacity(0.5), blurRadius: 15, spreadRadius: 4),
                        ]
                      ),
                    ),
                  )
              ],
            );
          },
        );
      },
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key}); 
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _activePlan;
  bool _isLoadingPlan = true;
  String _daysLeftText = "";
  double _planProgress = 0.0;
  Timer? _timeTimer;
  String _istTimeString = "";

  @override
  void initState() {
    super.initState();
    _fetchActivePlan();
    
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      DateTime istTime = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
      String ampm = istTime.hour >= 12 ? 'PM' : 'AM';
      int hour12 = istTime.hour > 12 ? istTime.hour - 12 : (istTime.hour == 0 ? 12 : istTime.hour);
      if(mounted) {
        setState(() {
          _istTimeString = "${hour12.toString().padLeft(2, '0')}:${istTime.minute.toString().padLeft(2, '0')}:${istTime.second.toString().padLeft(2, '0')} $ampm (IST)";
        });
      }
    });
  }
  
  @override
  void dispose() {
    _timeTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchActivePlan() async {
    try {
      final res = await Supabase.instance.client.from('payment_requests').select().eq('user_id', currentUserId).eq('status', 'Approved').order('created_at', ascending: false).limit(1).maybeSingle();
      if(res != null) {
        DateTime? expiry = getPlanExpiryDate(res['created_at'], res['plan']);
        if(expiry != null) {
          DateTime now = DateTime.now();
          DateTime start = DateTime.parse(res['created_at']).toLocal();
          
          if(expiry.isAfter(now)) {
            int daysLeft = expiry.difference(now).inDays;
            _daysLeftText = "$daysLeft days left";
            
            int totalDays = expiry.difference(start).inDays;
            int daysPassed = now.difference(start).inDays;
            _planProgress = totalDays > 0 ? (daysPassed / totalDays).clamp(0.0, 1.0) : 0.0;
            
            setState(() { _activePlan = res; _activePlan!['expiry'] = expiry; });
          }
        }
      }
    } catch(e) { }
    if(mounted) setState(() => _isLoadingPlan = false);
  }

  Widget _buildGroupedItem(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent, 
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
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

  String _formatJoinDate() {
    DateTime now = DateTime.now();
    return "${now.day} ${_getMonthStr(now.month)} ${now.year}";
  }
  String _getMonthStr(int m) { const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; return months[m-1]; }

  @override
  Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: (){}),
          IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: () async { await Supabase.instance.client.auth.signOut(); if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGate())); }),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              // User Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3), 
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primColor, width: 2), boxShadow: [BoxShadow(color: primColor.withOpacity(0.3), blurRadius: 20)]), 
                    child: CircleAvatar(
                      radius: 40, backgroundColor: getAvatarColor(currentUserName), 
                      backgroundImage: localProfileImagePath.isNotEmpty ? FileImage(File(localProfileImagePath)) : null,
                      child: localProfileImagePath.isEmpty ? Text(getAvatarLetter(currentUserName), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)) : null
                    )
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(currentUserName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          if(_activePlan != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: primColor.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                children: [
                                  Icon(Icons.star, color: primColor, size: 12),
                                  const SizedBox(width: 4),
                                  Text("Premium", style: TextStyle(color: primColor, fontSize: 10, fontWeight: FontWeight.bold))
                                ],
                              ),
                            )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("UID: $currentUserUid", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.white54, size: 12),
                          const SizedBox(width: 4),
                          Text("Member since ${_formatJoinDate()}", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(_istTimeString, style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 30),
              
              if(_isLoadingPlan)
                 Center(child: CircularProgressIndicator(color: primColor))
              else if(_activePlan != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primColor.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.diamond, color: primColor, size: 20)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_activePlan!['plan'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text("Valid till ${(_activePlan!['expiry'] as DateTime).day} ${_getMonthStr((_activePlan!['expiry'] as DateTime).month)} ${(_activePlan!['expiry'] as DateTime).year}", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                                ],
                              )
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: primColor.withOpacity(0.15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), elevation: 0),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPage())), 
                            child: Text("View Plan", style: TextStyle(color: primColor, fontWeight: FontWeight.bold, fontSize: 12))
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      AnimatedPlanProgressBar(progress: _planProgress),
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.centerRight, child: Text(_daysLeftText, style: const TextStyle(color: Colors.white54, fontSize: 11)))
                    ],
                  ),
                )
              else 
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPage())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFF6B21A8)]), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Upgrade to VIP", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text("Enjoy Ad-free 4K Streaming", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16))
                      ],
                    ),
                  ),
                ),
                
              const SizedBox(height: 30),

              const Text("ACCOUNT", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  _buildGroupedItem(context, title: "My Profile", icon: Icons.person, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())).then((_) => setState((){}));
                  }),
                  const Divider(color: Colors.white10, height: 1, indent: 50, endIndent: 16),
                  _buildGroupedItem(context, title: "Subscription", icon: Icons.workspace_premium, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPage()))),
                  const Divider(color: Colors.white10, height: 1, indent: 50, endIndent: 16),
                  _buildGroupedItem(context, title: "Order History", icon: Icons.history_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryPage())).then((_) => _fetchActivePlan())),
                  const Divider(color: Colors.white10, height: 1, indent: 50, endIndent: 16),
                  _buildGroupedItem(context, title: "Watch History", icon: Icons.schedule, onTap: () {}),
                  const Divider(color: Colors.white10, height: 1, indent: 50, endIndent: 16),
                  _buildGroupedItem(context, title: "Download Settings", icon: Icons.download, onTap: () {}),
                ]),
              ),
              const SizedBox(height: 30),

              const Text("SUPPORT & INFO", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  _buildGroupedItem(context, title: "Support", icon: Icons.support_agent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage()))),
                  const Divider(color: Colors.white10, height: 1, indent: 50, endIndent: 16),
                  _buildGroupedItem(context, title: "Privacy Policy", icon: Icons.privacy_tip_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()))),
                  const Divider(color: Colors.white10, height: 1, indent: 50, endIndent: 16),
                  _buildGroupedItem(context, title: "Terms & Conditions", icon: Icons.description_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsPage()))),
                  const Divider(color: Colors.white10, height: 1, indent: 50, endIndent: 16),
                  Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [Icon(Icons.info_outline, color: primColor, size: 22), const SizedBox(width: 14), const Text("About AniXplayer", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))]),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: primColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text("v$CURRENT_APP_VERSION", style: TextStyle(color: primColor, fontSize: 11, fontWeight: FontWeight.bold)))
                        ],
                      ),
                    ),
                  )
                ]),
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2CA5E0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => launchInBrowser(globalTelegramLink), 
                      icon: const Icon(Icons.telegram, color: Colors.white),
                      label: const Text("Telegram", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => launchInBrowser(globalWhatsappLink), 
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: const Text("WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    )
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});
  @override State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}
class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override void initState() { super.initState(); _fetchOrders(); }

  Future<void> _fetchOrders() async {
    try {
      final res = await Supabase.instance.client.from('payment_requests').select().eq('user_id', currentUserId).order('created_at', ascending: false);
      List<dynamic> updatedOrders = [];
      for(var order in res) {
        String status = order['status'] ?? "Pending";
        if (status == 'Approved' && order['created_at'] != null) {
          DateTime? expiry = getPlanExpiryDate(order['created_at'], order['plan'] ?? "");
          if (expiry != null && DateTime.now().isAfter(expiry)) {
            status = "Expired"; 
          }
        }
        order['display_status'] = status;
        updatedOrders.add(order);
      }
      setState(() { _orders = updatedOrders; _isLoading = false; });
    } catch(e) {
      setState(() => _isLoading = false);
    }
  }

  @override Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: getBg(context),
      appBar: AppBar(title: Text("Order History", style: TextStyle(color: getText(context))), backgroundColor: getBg(context)),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primColor))
        : _orders.isEmpty 
          ? Center(child: Text("No orders found.", style: TextStyle(color: getSubText(context), fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                String status = order['display_status'] ?? "Pending";
                Color statusColor = status == 'Approved' ? Colors.green : (status == 'Rejected' ? Colors.redAccent : (status == 'Expired' ? Colors.yellow : Colors.orange));
                String date = "Unknown";
                if(order['created_at'] != null) {
                  DateTime d = DateTime.parse(order['created_at']).toLocal();
                  date = "${d.day}/${d.month}/${d.year}";
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: getCard(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(order['plan'] ?? "Unknown Plan", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)))
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Amount", style: TextStyle(color: Colors.white54, fontSize: 12)), const SizedBox(height: 2), Text("₹${order['amount'] ?? 0}", style: TextStyle(color: primColor, fontSize: 16, fontWeight: FontWeight.bold))]),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("Date", style: TextStyle(color: Colors.white54, fontSize: 12)), const SizedBox(height: 2), Text(date, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.receipt_long, color: Colors.white54, size: 16), const SizedBox(width: 8), Text("UTR: ${order['transaction_id'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70, fontSize: 12))]))
                    ],
                  ),
                );
              }
            )
    );
  }
}

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});
  @override State<SubscriptionPage> createState() => _SubscriptionPageState();
}
class _SubscriptionPageState extends State<SubscriptionPage> {
  int _selectedPlanIndex = 1; 

  final List<Map<String, dynamic>> _plans = [
    {"name": "Bronze", "desc": "Premium for 7 Days", "price": "₹49", "duration": "week", "features": ["Stream in high-quality", "Free from ads"]},
    {"name": "Silver", "desc": "Premium for 1 Month", "price": "₹99", "duration": "month", "features": ["Stream in high-quality", "Free from ads", "Early access to the latest episodes"]},
    {"name": "Gold", "desc": "Premium for 3 Month", "price": "₹299", "duration": "3 months", "features": ["Stream in high-quality", "Free from ads", "Early access to the latest episodes"]},
  ];

  Widget _buildPerkRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(6)), padding: const EdgeInsets.all(2), child: const Icon(Icons.check, color: Colors.white, size: 14)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14))
        ],
      ),
    );
  }

  @override Widget build(BuildContext context) {
    Color btnColor = const Color(0xFF3B82F6); 
    return Scaffold(
      backgroundColor: getBg(context), 
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Image.network("https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEi9fdZQQdxD9-PxiUsl4kbRIahsqVu0ufAdxxJhCRsClKKEpp9O7hnPJ5ZM16fn6rABRKmz3WyYZPcFz6Lx18wqtObMm5KFQyYJdpBgv2DK6dQo-8I1uRtcVlGonZCg575af4xeDb1MHVhryl5rRBG-CELxfecVkMqALr7bjjUW5F0uF4GT-NQbr8sFlrI/s1536/file_0000000005dc8211b18c7b9ac42e35dc.webp", fit: BoxFit.cover, height: 280, width: double.infinity),
                      Container(
                        height: 280,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.black.withOpacity(0.1), Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.3, 1.0])
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10, left: 16,
                        child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
                      ),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)]),
                              child: const Icon(Icons.workspace_premium, color: Colors.white, size: 45),
                            ),
                            const SizedBox(height: 16),
                            const Text("Improve your experience", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text("Activate VIP membership to enjoy unlimited streaming no ads, 4K quality movies or series and more", style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
                        const SizedBox(height: 20),
                        _buildPerkRow("Stream in high-quality"),
                        _buildPerkRow("Free from ads"),
                        _buildPerkRow("Early access to the latest episodes"),
                        const SizedBox(height: 30),

                        const Text("Premium Plan", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        ...List.generate(_plans.length, (index) {
                          bool isSelected = _selectedPlanIndex == index;
                          final plan = _plans[index];

                          return GestureDetector(
                            onTap: () => setState(() => _selectedPlanIndex = index),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: getCard(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? btnColor : Colors.white10, width: isSelected ? 2 : 1)
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? btnColor : Colors.white54, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(plan['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(plan['desc'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                        const SizedBox(height: 8),
                                        ...List.generate(plan['features'].length, (fi) => Padding(padding: const EdgeInsets.only(bottom: 2), child: Row(children: [Container(width: 4, height: 4, decoration: BoxDecoration(color: btnColor, shape: BoxShape.circle)), const SizedBox(width: 6), Text(plan['features'][fi], style: const TextStyle(color: Colors.white54, fontSize: 11))]))),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(plan['price'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                      Text("/${plan['duration']}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: getBg(context),
              border: const Border(top: BorderSide(color: Colors.white10))
            ),
            child: SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: btnColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  final p = _plans[_selectedPlanIndex];
                  Navigator.push(context, MaterialPageRoute(builder: (_) => UnifiedPaymentScreen(planName: p['name'], price: p['price'])));
                }, 
                child: const Text("Continue to payment", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
              ),
            ),
          )
        ],
      )
    );
  }
}

class UnifiedPaymentScreen extends StatefulWidget {
  final String planName;
  final String price;
  const UnifiedPaymentScreen({super.key, required this.planName, required this.price});
  @override State<UnifiedPaymentScreen> createState() => _UnifiedPaymentScreenState();
}
class _UnifiedPaymentScreenState extends State<UnifiedPaymentScreen> {
  File? _imageFile;
  final TextEditingController _trxController = TextEditingController();
  bool _isSubmitting = false;

  void _launchUPIApp(BuildContext context) async {
    String cleanPrice = widget.price.replaceAll(RegExp(r'[^0-9.]'), "");
    final Uri uri = Uri.parse("upi://pay?pa=$globalUpiId&pn=AniXplayer&am=$cleanPrice&cu=INR&tn=Buy%20${widget.planName}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No UPI App found!")));
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() { _imageFile = File(pickedFile.path); });
    }
  }

  Future<void> _submitRequest() async {
    if (_imageFile == null || _trxController.text.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide both Screenshot and 12-Digit UTR.")));
      return;
    }
    setState(() => _isSubmitting = true);
    
    try {
      final ext = _imageFile!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      await Supabase.instance.client.storage.from('payment_proofs').upload(fileName, _imageFile!);
      String imageUrl = Supabase.instance.client.storage.from('payment_proofs').getPublicUrl(fileName);

      String amountStr = widget.price.replaceAll(RegExp(r'[^0-9.]'), '') ?? "0";
      double amount = double.tryParse(amountStr) ?? 0.0;

      await Supabase.instance.client.from('payment_requests').insert({
        'user_id': currentUserId,
        'user_name': currentUserName,
        'uid': currentUserUid,
        'plan': widget.planName,
        'amount': amount,
        'transaction_id': _trxController.text.trim(),
        'image_path': imageUrl,
        'status': 'Pending',
        'created_at': DateTime.now().toIso8601String()
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Proof Submitted Successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override Widget build(BuildContext context) {
    Color primColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: getCard(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("1. Scan & Pay", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text("Scan the QR code using any UPI app and pay the amount.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Row(
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(globalPaymentQrUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.qr_code_scanner, color: Colors.black))
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Amount to Pay", style: TextStyle(color: Colors.white54, fontSize: 12)),
                                  Text(widget.price, style: TextStyle(color: primColor, fontSize: 24, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  const Text("UPI ID", style: TextStyle(color: Colors.white54, fontSize: 12)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(globalUpiId, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        GestureDetector(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: globalUpiId));
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("UPI ID copied!")));
                                          },
                                          child: const Icon(Icons.copy, color: Colors.white70, size: 16)
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: primColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: () => _launchUPIApp(context),
                          icon: const Icon(Icons.payment, color: Colors.white, size: 20),
                          label: const Text("Pay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                        )
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: getCard(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("2. Verify Payment", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text("After successful payment, submit your proof.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 12),

                      const Text("Upload Screenshot", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12, style: BorderStyle.solid)),
                            child: _imageFile != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_imageFile!, fit: BoxFit.cover))
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_upload, color: primColor, size: 30),
                                      const SizedBox(height: 8),
                                      const Text("Tap to upload screenshot", style: TextStyle(color: Colors.white54, fontSize: 12))
                                    ]
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text("12-Digit UTR Number", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 45,
                        child: TextField(
                          controller: _trxController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Enter 12-digit UTR number",
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            filled: true,
                            fillColor: Colors.black45,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)
                          )
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: primColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: _isSubmitting ? null : _submitRequest,
                          child: _isSubmitting
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                        )
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.verified_user_outlined, color: Colors.white38, size: 14),
                          SizedBox(width: 4),
                          Text("Your payment will be verified within a few minutes.", style: TextStyle(color: Colors.white38, fontSize: 10))
                        ],
                      )
                    ],
                  ),
                )
              ),
            ],
          ),
        )
      )
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

class TermsConditionsPage extends StatelessWidget { 
  const TermsConditionsPage({super.key});
  @override Widget build(BuildContext context) { 
    return Scaffold(backgroundColor: getBg(context), appBar: AppBar(title: Text("Terms & Conditions", style: TextStyle(color: getText(context))), backgroundColor: getBg(context)), body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Text(globalTermsConditions, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)))); 
  } 
}

class SeeAllCategoryPage extends StatelessWidget {
  final String title; final List<Anime> animeList; final bool isLatestOnly;
  const SeeAllCategoryPage({super.key, required this.title, required this.animeList, this.isLatestOnly = false});
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBg(context), appBar: AppBar(backgroundColor: getBg(context), elevation: 0, title: Text(title, style: TextStyle(color: getText(context), fontWeight: FontWeight.bold, fontSize: 20)), iconTheme: IconThemeData(color: getText(context))),
      body: GridView.builder(padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 40), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.55, crossAxisSpacing: 10, mainAxisSpacing: 16), itemCount: animeList.length, itemBuilder: (context, index) => ExploreAnimeCard(anime: animeList[index]))
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
      onTap: () {
        int sIdx = getFirstValidSeason(anime);
        Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: anime, seasonIndex: sIdx, episodeIndex: 0))); 
      },
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
    return ExploreAnimeCard(anime: widget.anime); 
  }
}

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
  
  int _likeCount = 0;
  int _dislikeCount = 0;
  int _userLikeStatus = 0; 

  @override 
  void initState() { 
    super.initState(); 
    _currentSeasonIndex = widget.seasonIndex;
    _currentEpisodeIndex = widget.episodeIndex;
    
    if (widget.anime.seasonsList.isEmpty || widget.anime.seasonsList[_currentSeasonIndex].episodes.isEmpty) {
      return; 
    }
    
    _incrementAndFetchViews(); 
    _fetchLikes();
    _initPlayer();
  }

  Future<void> _fetchLikes() async {
    try {
      final res = await Supabase.instance.client.from('anime_likes').select('is_like').eq('anime_id', widget.anime.id);
      int likes = 0; int dislikes = 0;
      for (var r in res) {
        if (r['is_like'] == true) likes++;
        else if (r['is_like'] == false) dislikes++;
      }
      
      final userRes = await Supabase.instance.client.from('anime_likes').select('is_like').eq('anime_id', widget.anime.id).eq('user_id', currentUserId).maybeSingle();
      int userStatus = 0;
      if (userRes != null) {
        userStatus = userRes['is_like'] == true ? 1 : -1;
      }
      
      if (mounted) setState(() { _likeCount = likes; _dislikeCount = dislikes; _userLikeStatus = userStatus; });
    } catch(e) {}
  }
  
  Future<void> _toggleLike(bool isLikeAction) async {
    int targetStatus = isLikeAction ? 1 : -1;
    bool isRemoving = _userLikeStatus == targetStatus;
    
    setState(() {
      if (_userLikeStatus == 1) _likeCount--;
      if (_userLikeStatus == -1) _dislikeCount--;
      
      if (isRemoving) {
        _userLikeStatus = 0; 
      } else {
        _userLikeStatus = targetStatus;
        if (_userLikeStatus == 1) _likeCount++;
        if (_userLikeStatus == -1) _dislikeCount++;
      }
    });

    try {
      if (isRemoving) {
        await Supabase.instance.client.from('anime_likes').delete().eq('anime_id', widget.anime.id).eq('user_id', currentUserId);
      } else {
        await Supabase.instance.client.from('anime_likes').upsert({
          'anime_id': widget.anime.id,
          'user_id': currentUserId,
          'is_like': isLikeAction
        });
      }
    } catch (e) {
      _fetchLikes();
    }
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
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.anime.description.length > 100)
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DescriptionPage(anime: widget.anime))),
                              child: Text("Read More", style: TextStyle(color: primColor, fontWeight: FontWeight.bold, fontSize: 13)),
                            )
                          else const SizedBox(),
                          
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _toggleLike(true),
                                child: Row(
                                  children: [
                                    Icon(_userLikeStatus == 1 ? Icons.thumb_up : Icons.thumb_up_alt_outlined, color: _userLikeStatus == 1 ? primColor : Colors.white70, size: 20),
                                    const SizedBox(width: 4),
                                    Text("$_likeCount", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold))
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              GestureDetector(
                                onTap: () => _toggleLike(false),
                                child: Row(
                                  children: [
                                    Icon(_userLikeStatus == -1 ? Icons.thumb_down : Icons.thumb_down_alt_outlined, color: _userLikeStatus == -1 ? Colors.redAccent : Colors.white70, size: 20),
                                    const SizedBox(width: 4),
                                    Text("$_dislikeCount", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold))
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
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
                          if(anime.title == widget.anime.title) return const SizedBox.shrink(); 
                          String epCount = "E${getTotalEpisodes(anime)}";
                          String views = formatViewsCount(globalAnimeViewsNotifier.value[anime.title] ?? 0);
                          String bottomLine = anime.category.toLowerCase().contains("movie") ? "MOVIE  ■  $views" : "${getSeasonText(anime)}  ■  $views";
                          String tagLang = anime.dubStatus.toUpperCase().contains("DUB") ? "HINDI" : "MULTI";

                          return GestureDetector(
                            onTap: () {
                              int sIdx = getFirstValidSeason(anime);
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(anime: anime, seasonIndex: sIdx, episodeIndex: 0))); 
                            },
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