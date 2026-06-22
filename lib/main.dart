import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// GLOBAL CONFIG & THEME
// ==========================================
const Color adminPurple = Color(0xFF8A2BE2);
const Color bgDark = Color(0xFF0B0B0F);
const Color cardDark = Color(0xFF16161E);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://yngzfgfpyufusrbitagl.supabase.co',          
    anonKey: 'sb_publishable_6BD0moEpOnUTfihbRUpdOQ_U2gJCH5U', 
  );

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SYNEX Admin',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: adminPurple,
        scaffoldBackgroundColor: bgDark,
        appBarTheme: const AppBarTheme(backgroundColor: bgDark, elevation: 0, centerTitle: true),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: adminPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
      home: const AdminAuthGate(),
    );
  }
}

// ==========================================
// AUTH GATE
// ==========================================
class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: adminPurple)));
        }
        final session = snapshot.data?.session;
        if (session != null) {
          return const AdminDashboard();
        }
        return const AdminLoginScreen();
      },
    );
  }
}

// ==========================================
// IMPROVED ADMIN LOGIN SCREEN (SYNEX ADMIN)
// ==========================================
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // GLOW BACKGROUND EFFECT
          Positioned(
            top: -50, left: 0, right: 0,
            child: Container(
              height: 400, 
              decoration: BoxDecoration(gradient: RadialGradient(colors: [adminPurple.withOpacity(0.15), Colors.transparent], radius: 0.8))
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: cardDark, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: adminPurple.withOpacity(0.1), blurRadius: 30, spreadRadius: 5)],
                  border: Border.all(color: adminPurple.withOpacity(0.2), width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LOGO & STYLISH TEXT
                    const Icon(Icons.admin_panel_settings, size: 70, color: adminPurple),
                    const SizedBox(height: 16),
                    RichText(text: const TextSpan(children: [
                      TextSpan(text: "SYNEX ", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.2)), 
                      TextSpan(text: "ADMIN", style: TextStyle(color: adminPurple, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.2, shadows: [Shadow(color: adminPurple, blurRadius: 10)]))
                    ])),
                    const SizedBox(height: 8),
                    const Text("Master Control Center", style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1)),
                    const SizedBox(height: 32),
                    
                    TextField(
                      controller: _emailController, style: const TextStyle(color: Colors.white), 
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined, color: adminPurple), 
                        hintText: "Admin Email", hintStyle: const TextStyle(color: Colors.white38),
                        filled: true, fillColor: bgDark, 
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: adminPurple.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple, width: 2)),
                      )
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController, obscureText: _obscureText, style: const TextStyle(color: Colors.white), 
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, color: adminPurple), 
                        suffixIcon: IconButton(icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white54), onPressed: ()=>setState(()=>_obscureText = !_obscureText)), 
                        hintText: "Password", hintStyle: const TextStyle(color: Colors.white38),
                        filled: true, fillColor: bgDark, 
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: adminPurple.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple, width: 2)),
                      )
                    ),
                    const SizedBox(height: 30),
                    
                    Container(
                      width: double.infinity, height: 50,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: adminPurple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("ENTER DASHBOARD", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16, letterSpacing: 1)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ADMIN DASHBOARD & MENU
// ==========================================
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Widget _currentScreen = const AdminHomeScreen();
  String _currentTitle = "Dashboard Analytics";

  void _selectScreen(Widget screen, String title) {
    setState(() { _currentScreen = screen; _currentTitle = title; });
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle, style: const TextStyle(color: adminPurple, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
        iconTheme: const IconThemeData(color: adminPurple),
        actions: [
          IconButton(icon: const Icon(Icons.power_settings_new, color: Colors.redAccent), onPressed: () => Supabase.instance.client.auth.signOut())
        ],
      ),
      drawer: Drawer(
        backgroundColor: cardDark,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: bgDark),
              accountName: RichText(text: const TextSpan(children: [
                TextSpan(text: "SYNEX ", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), 
                TextSpan(text: "ADMIN", style: TextStyle(color: adminPurple, fontSize: 20, fontWeight: FontWeight.w900))
              ])),
              accountEmail: const Text("Master Access Enabled", style: TextStyle(color: adminPurple, fontSize: 12)),
              currentAccountPicture: const CircleAvatar(backgroundColor: adminPurple, child: Icon(Icons.security, color: Colors.white, size: 30)),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.dashboard, "Dashboard Analytics", const AdminHomeScreen()),
                  const Divider(color: Colors.white12),
                  _buildDrawerItem(Icons.payments_outlined, "Manage Payments", const ManagePaymentsScreen()),
                  _buildDrawerItem(Icons.people_outline, "Manage Users", const UsersListScreen()),
                  const Divider(color: Colors.white12),
                  _buildDrawerItem(Icons.movie_creation_outlined, "Manage Anime", const ManageAnimeScreen()),
                  _buildDrawerItem(Icons.video_library_outlined, "Manage Episodes", const ManageEpisodesScreen()),
                  _buildDrawerItem(Icons.view_carousel_outlined, "Hero Section", const ManageHeroScreen()),
                  const Divider(color: Colors.white12),
                  _buildDrawerItem(Icons.settings_outlined, "App Settings & Links", const AppSettingsScreen()),
                  _buildDrawerItem(Icons.policy_outlined, "Manage App Pages", const ManagePagesScreen()), // 🔥 NAYA FEATURE
                  _buildDrawerItem(Icons.system_update_outlined, "Push App Update", const AppUpdateScreen()),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _currentScreen,
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Widget screen) {
    bool isSelected = _currentTitle == title;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? adminPurple.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10)
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? adminPurple : Colors.white70),
        title: Text(title, style: TextStyle(color: isSelected ? adminPurple : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        onTap: () => _selectScreen(screen, title),
      ),
    );
  }
}

// ==========================================
// 1. DASHBOARD HOME (LIVE STATS & DAILY USERS)
// ==========================================
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int totalUsers = 0;
  int premiumUsers = 0;
  int freeUsers = 0;
  int liveUsers = 0;
  int offlineUsers = 0;
  int dailyActiveUsers = 0; 
  bool _isLoading = true;
  RealtimeChannel? _presenceChannel;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _initLiveTracking();
  }

  Future<void> _fetchStats() async {
    try {
      final userRes = await Supabase.instance.client.from('user_preferences').select('email');
      Set<String> uniqueEmails = {};
      for(var r in userRes) { if(r['email'] != null) uniqueEmails.add(r['email']); }
      totalUsers = uniqueEmails.length;

      final premiumRes = await Supabase.instance.client.from('payment_requests').select('email').eq('status', 'Approved');
      Set<String> premiumEmails = {};
      for(var r in premiumRes) { if(r['email'] != null) premiumEmails.add(r['email']); }
      premiumUsers = premiumEmails.length;

      freeUsers = totalUsers - premiumUsers;
      if(freeUsers < 0) freeUsers = 0;
      offlineUsers = totalUsers; 

      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day).toUtc().toIso8601String();
      try {
        final dailyRes = await Supabase.instance.client.from('user_views').select('user_id').gte('created_at', startOfToday);
        Set<String> uniqueDaily = {};
        for(var r in dailyRes) { if(r['user_id'] != null) uniqueDaily.add(r['user_id'].toString()); }
        dailyActiveUsers = uniqueDaily.length;
      } catch(e) { print("DAU error: $e"); }
      
      setState(() => _isLoading = false);
    } catch(e) { print(e); setState(() => _isLoading = false); }
  }

  void _initLiveTracking() {
    _presenceChannel = Supabase.instance.client.channel('online-users');
    _presenceChannel?.onPresenceSync((payload) {
      final activeStates = _presenceChannel?.presenceState();
      int count = 0;
      
      if (activeStates != null) {
        final rawMap = activeStates as Map<dynamic, dynamic>;
        for (var value in rawMap.values) {
          if (value is List) {
            count += value.length;
          }
        }
      }
      
      setState(() {
        liveUsers = count;
        offlineUsers = totalUsers - liveUsers;
        if(offlineUsers < 0) offlineUsers = 0;
      });
    }).subscribe();
  }

  @override
  void dispose() {
    _presenceChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(_isLoading) return const Center(child: CircularProgressIndicator(color: adminPurple));
    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: adminPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Overview Analytics", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            GridView(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.1, crossAxisSpacing: 16, mainAxisSpacing: 16),
              children: [
                _buildStatCard("Total Members", totalUsers.toString(), Icons.people, Colors.blue),
                _buildStatCard("Premium Members", premiumUsers.toString(), Icons.workspace_premium, Colors.amber),
                _buildStatCard("Daily Active Users", dailyActiveUsers.toString(), Icons.local_fire_department, Colors.orange),
                _buildStatCard("Live Now", liveUsers.toString(), Icons.sensors, Colors.green, isLive: true),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard("Free Users", freeUsers.toString(), Icons.person_outline, Colors.grey, fullWidth: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard("Offline Now", offlineUsers.toString(), Icons.cloud_off, Colors.redAccent, fullWidth: true)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, {bool fullWidth = false, bool isLive = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
              if(isLive) const Icon(Icons.circle, color: Colors.green, size: 12)
            ],
          ),
          const Spacer(),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.white70, fontSize: fullWidth ? 13 : 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ==========================================
// 2. MANAGE PAYMENTS
// ==========================================
class ManagePaymentsScreen extends StatefulWidget {
  const ManagePaymentsScreen({super.key});
  @override
  State<ManagePaymentsScreen> createState() => _ManagePaymentsScreenState();
}

class _ManagePaymentsScreenState extends State<ManagePaymentsScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetchRequests(); }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client.from('payment_requests').select().order('created_at', ascending: false);
      setState(() => _requests = data);
    } catch (e) {} finally { setState(() => _isLoading = false); }
  }

  Future<void> _updateStatus(dynamic id, String newStatus) async {
    try {
      await Supabase.instance.client.from('payment_requests').update({'status': newStatus}).eq('id', id.toString());
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment $newStatus"), backgroundColor: Colors.green));
      _fetchRequests();
    } catch(e) { }
  }

  Future<void> _deleteRequest(dynamic id) async {
    try {
      await Supabase.instance.client.from('payment_requests').delete().eq('id', id.toString());
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record Deleted"), backgroundColor: Colors.red));
      _fetchRequests();
    } catch(e) { }
  }

  Future<void> _editPlanDialog(dynamic id, String currentPlan) async {
    TextEditingController planController = TextEditingController(text: currentPlan);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        title: const Text("Edit User's Plan/Price", style: TextStyle(color: Colors.white)),
        content: TextField(controller: planController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(filled: true, fillColor: bgDark)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client.from('payment_requests').update({'plan': planController.text}).eq('id', id.toString());
                if(mounted) Navigator.pop(context);
                _fetchRequests();
              } catch(e) {}
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  void _showProofDialog(String imageUrl, String utr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("UTR: $utr", style: const TextStyle(color: adminPurple, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            imageUrl.startsWith('http') ? Image.network(imageUrl, height: 300, fit: BoxFit.contain) : const Text("No Image", style: TextStyle(color: Colors.white54)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: adminPurple)))],
      ),
    );
  }

  String _formatDateGroup(String? isoString) {
    if (isoString == null) return "Unknown Time";
    DateTime date = DateTime.parse(isoString).toLocal();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    DateTime checkDate = DateTime(date.year, date.month, date.day);

    String ampm = date.hour >= 12 ? 'PM' : 'AM';
    int hr = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    String timeStr = "$hr:${date.minute.toString().padLeft(2, '0')} $ampm";

    if (checkDate == today) return "Today at $timeStr";
    if (checkDate == yesterday) return "Yesterday at $timeStr";
    return "${date.day}/${date.month}/${date.year} at $timeStr";
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator(color: adminPurple))
      : _requests.isEmpty ? const Center(child: Text("No payments found.", style: TextStyle(color: Colors.white54)))
      : ListView.builder(
          padding: const EdgeInsets.all(12), itemCount: _requests.length,
          itemBuilder: (context, index) {
            final req = _requests[index];
            String displayTime = _formatDateGroup(req['created_at']);
            
            return Card(
              color: cardDark, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text("${req['email']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: req['status'] == 'Approved' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(req['status'], style: TextStyle(color: req['status'] == 'Approved' ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)))
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(displayTime, style: TextStyle(color: displayTime.contains("Today") ? Colors.greenAccent : Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text("Plan: ${req['plan']}", style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
                        GestureDetector(onTap: () => _editPlanDialog(req['id'], req['plan']), child: const Icon(Icons.edit, color: Colors.blueAccent, size: 18))
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("UTR: ${req['transaction_id']}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), icon: const Icon(Icons.image, size: 16, color: Colors.white), label: const Text("Proof", style: TextStyle(color: Colors.white)), onPressed: () => _showProofDialog(req['image_path'], req['transaction_id'])),
                        IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _updateStatus(req['id'], 'Approved')),
                        IconButton(icon: const Icon(Icons.cancel, color: Colors.orange), onPressed: () => _updateStatus(req['id'], 'Rejected')),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteRequest(req['id'])),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }
}

// ==========================================
// 3. MANAGE ANIME 
// ==========================================
class ManageAnimeScreen extends StatefulWidget {
  const ManageAnimeScreen({super.key});
  @override
  State<ManageAnimeScreen> createState() => _ManageAnimeScreenState();
}

class _ManageAnimeScreenState extends State<ManageAnimeScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _imageController = TextEditingController();
  final _mainCategoryController = TextEditingController(); 
  final _subCategoryController = TextEditingController(); 
  String _selectedDub = 'DUB';
  String _selectedRating = 'PG-13';
  List<dynamic> _animeList = [];
  bool _isLoading = false;

  @override
  void initState() { super.initState(); _fetchAnime(); }

  Future<void> _fetchAnime() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client.from('anime_list').select().order('created_at', ascending: false);
      setState(() => _animeList = data);
    } catch (e) {} finally { setState(() => _isLoading = false); }
  }

  Future<void> _addAnime() async {
    if(_titleController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('anime_list').insert({
        'title': _titleController.text, 'description': _descController.text, 'image_url': _imageController.text,
        'category': _mainCategoryController.text, 'sub_category': _subCategoryController.text, 'dub_status': _selectedDub, 'rating': _selectedRating,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anime Added"), backgroundColor: Colors.green));
      _titleController.clear(); _descController.clear(); _imageController.clear(); _mainCategoryController.clear(); _subCategoryController.clear();
      _fetchAnime();
    } catch (e) {}
  }

  Future<void> _deleteAnime(dynamic id) async {
    await Supabase.instance.client.from('anime_list').delete().eq('id', id.toString());
    _fetchAnime();
  }

  Future<void> _editAnime(Map<String, dynamic> anime) async {
    _titleController.text = anime['title'] ?? '';
    _descController.text = anime['description'] ?? '';
    _imageController.text = anime['image_url'] ?? '';
    _mainCategoryController.text = anime['category'] ?? '';
    _subCategoryController.text = anime['sub_category'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        title: const Text("Edit Anime", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Title")),
              const SizedBox(height: 8),
              TextField(controller: _imageController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Image URL")),
              const SizedBox(height: 8),
              TextField(controller: _mainCategoryController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Main Category")),
              const SizedBox(height: 8),
              TextField(controller: _subCategoryController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Sub Category")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.from('anime_list').update({
                'title': _titleController.text,
                'image_url': _imageController.text,
                'category': _mainCategoryController.text,
                'sub_category': _subCategoryController.text,
              }).eq('id', anime['id'].toString());
              if(mounted) Navigator.pop(context);
              _titleController.clear(); _imageController.clear(); _mainCategoryController.clear(); _subCategoryController.clear();
              _fetchAnime();
            },
            child: const Text("Update"),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Upload Anime Profile/Poster", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
          TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Anime Name")), const SizedBox(height: 12),
          TextField(controller: _descController, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Description")), const SizedBox(height: 12),
          TextField(controller: _imageController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Poster Image URL")), const SizedBox(height: 12),
          TextField(controller: _mainCategoryController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Main Category (e.g. Action)")), const SizedBox(height: 12),
          TextField(controller: _subCategoryController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Sub Category (e.g. Romance, Thriller)")), const SizedBox(height: 16),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(dropdownColor: cardDark, value: _selectedDub, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Dub Status"), items: ['DUB', 'ORIGINAL', 'MIX O/D'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _selectedDub = v!))),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(dropdownColor: cardDark, value: _selectedRating, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Rating"), items: ['PG-13', 'R-17+', 'All Ages'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _selectedRating = v!))),
          ]),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(icon: const Icon(Icons.upload, color: Colors.white), label: const Text("Upload Anime Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), onPressed: _isLoading ? null : _addAnime)),
          
          const SizedBox(height: 30),
          const Text("Uploaded Animes", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 10),
          if (_isLoading) const Center(child: CircularProgressIndicator(color: adminPurple))
          else ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _animeList.length, itemBuilder: (context, index) {
            final a = _animeList[index];
            return Card(color: cardDark, child: ListTile(leading: Image.network(a['image_url'], width: 40, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const Icon(Icons.error)), title: Text(a['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text("${a['category']} | ${a['dub_status']}", style: const TextStyle(color: Colors.white54)), trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editAnime(a)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteAnime(a['id'])),
              ],
            )));
          })
        ],
      ),
    );
  }
  InputDecoration _inputDeco(String hint) => InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 14), filled: true, fillColor: cardDark, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none));
}

// ==========================================
// 4. MANAGE EPISODES
// ==========================================
class ManageEpisodesScreen extends StatefulWidget {
  const ManageEpisodesScreen({super.key});
  @override
  State<ManageEpisodesScreen> createState() => _ManageEpisodesScreenState();
}

class _ManageEpisodesScreenState extends State<ManageEpisodesScreen> {
  List<dynamic> _animeList = [];
  List<dynamic> _episodeList = [];
  String? _selectedAnimeId;
  final _seasonController = TextEditingController();
  final _episodeTitleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _durationController = TextEditingController();
  final _videoUrlController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetchAnimeList(); }

  Future<void> _fetchAnimeList() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client.from('anime_list').select('id, title').order('created_at', ascending: false);
      setState(() { _animeList = data; if(data.isNotEmpty) { _selectedAnimeId = data[0]['id'].toString(); _fetchEpisodesForAnime(_selectedAnimeId!); } });
    } catch (e) {} finally { setState(() => _isLoading = false); }
  }

  Future<void> _fetchEpisodesForAnime(String animeId) async {
    try {
      final data = await Supabase.instance.client.from('anime_seasons').select('id, season_name, anime_episodes(id, episode_title, video_url)').eq('anime_id', animeId);
      List<dynamic> allEps = [];
      for (var season in data) { for (var ep in season['anime_episodes']) { ep['season_name'] = season['season_name']; allEps.add(ep); } }
      setState(() => _episodeList = allEps);
    } catch (e) {}
  }

  Future<void> _uploadEpisode() async {
    if (_selectedAnimeId == null || _seasonController.text.isEmpty || _videoUrlController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final seasonRes = await Supabase.instance.client.from('anime_seasons').select('id').eq('anime_id', _selectedAnimeId!).eq('season_name', _seasonController.text.trim()).maybeSingle();
      String seasonId;
      if (seasonRes == null) {
        final newSeason = await Supabase.instance.client.from('anime_seasons').insert({'anime_id': _selectedAnimeId, 'season_name': _seasonController.text.trim()}).select('id').single();
        seasonId = newSeason['id'].toString();
      } else { seasonId = seasonRes['id'].toString(); }
      await Supabase.instance.client.from('anime_episodes').insert({'season_id': seasonId, 'episode_title': _episodeTitleController.text.isEmpty ? "Episode" : _episodeTitleController.text, 'image_url': _imageUrlController.text, 'duration': _durationController.text.isEmpty ? "24m" : _durationController.text, 'video_url': _videoUrlController.text});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Episode Uploaded"), backgroundColor: Colors.green));
      _episodeTitleController.clear(); _imageUrlController.clear(); _durationController.clear(); _videoUrlController.clear();
      _fetchEpisodesForAnime(_selectedAnimeId!);
    } catch (e) {} finally { setState(() => _isLoading = false); }
  }

  Future<void> _deleteEpisode(dynamic id) async {
    await Supabase.instance.client.from('anime_episodes').delete().eq('id', id.toString());
    if(_selectedAnimeId != null) _fetchEpisodesForAnime(_selectedAnimeId!);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _animeList.isEmpty) return const Center(child: CircularProgressIndicator(color: adminPurple));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Upload New Episode", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
          DropdownButtonFormField<String>(dropdownColor: cardDark, value: _selectedAnimeId, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Select Anime"), items: _animeList.map((a) => DropdownMenuItem<String>(value: a['id'].toString(), child: Text(a['title'].toString()))).toList(), onChanged: (v) { setState(() => _selectedAnimeId = v); if(v != null) _fetchEpisodesForAnime(v); }), const SizedBox(height: 12),
          TextField(controller: _seasonController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Season Name (e.g. S1)")), const SizedBox(height: 12),
          TextField(controller: _episodeTitleController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Episode Title")), const SizedBox(height: 12),
          TextField(controller: _imageUrlController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Thumbnail URL (Optional)")), const SizedBox(height: 12),
          TextField(controller: _durationController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Duration (e.g. 24m)")), const SizedBox(height: 12),
          TextField(controller: _videoUrlController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Direct Video URL")), const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(icon: const Icon(Icons.cloud_upload, color: Colors.white), label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Upload Episode", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), onPressed: _isLoading ? null : _uploadEpisode)),
          
          const SizedBox(height: 30), const Text("Episodes for Selected Anime", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 10),
          ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _episodeList.length, itemBuilder: (context, index) {
            final ep = _episodeList[index];
            return Card(color: cardDark, child: ListTile(title: Text(ep['episode_title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text("${ep['season_name']} | Link: ${ep['video_url']}", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteEpisode(ep['id']))));
          })
        ],
      ),
    );
  }
  InputDecoration _inputDeco(String hint) => InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 14), filled: true, fillColor: cardDark, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none));
}

// ==========================================
// 5. MANAGE HERO SECTION 
// ==========================================
class ManageHeroScreen extends StatefulWidget {
  const ManageHeroScreen({super.key});
  @override
  State<ManageHeroScreen> createState() => _ManageHeroScreenState();
}

class _ManageHeroScreenState extends State<ManageHeroScreen> {
  final _titleController = TextEditingController();
  final _imageController = TextEditingController();
  final _tagController = TextEditingController();
  List<dynamic> _animeList = [];
  String? _selectedAnimeId; 
  bool _isCustom = false;
  String _selectedColor = "FF8A2BE2"; 
  List<dynamic> _heroItems = [];

  final Map<String, String> _colorOptions = {"Purple": "FF8A2BE2", "Red": "FFFF4D4D", "Blue": "FF4DA6FF", "Green": "FF00C853", "Orange": "FFFF9F43", "Pink": "FFFF4081"};

  @override
  void initState() { super.initState(); _fetchData(); }

  Future<void> _fetchData() async {
    try {
      final animes = await Supabase.instance.client.from('anime_list').select('id, title');
      final heroes = await Supabase.instance.client.from('hero_slider').select().order('created_at', ascending: false);
      setState(() { _animeList = animes; _heroItems = heroes; });
    } catch (e) {}
  }

  Future<void> _addHero() async {
    try {
      await Supabase.instance.client.from('hero_slider').insert({'title': _titleController.text, 'image_url': _imageController.text, 'anime_id': _isCustom ? null : _selectedAnimeId, 'is_custom': _isCustom, 'tag': _tagController.text.isEmpty ? "NEW" : _tagController.text, 'tag_color': _selectedColor});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hero Added!"), backgroundColor: Colors.green));
      _titleController.clear(); _imageController.clear(); _tagController.clear(); _fetchData();
    } catch (e) {}
  }

  Future<void> _deleteHero(dynamic id) async {
    await Supabase.instance.client.from('hero_slider').delete().eq('id', id.toString());
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Add Hero Banner", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text("Custom Banner (Not linked to Anime)", style: TextStyle(color: Colors.white)), activeColor: adminPurple, value: _isCustom, onChanged: (val) => setState(() => _isCustom = val)),
          if (!_isCustom) ...[
            DropdownButtonFormField<String>(dropdownColor: cardDark, value: _selectedAnimeId, hint: const Text("Link to Existing Anime", style: TextStyle(color: Colors.white54)), style: const TextStyle(color: Colors.white), decoration: _inputDeco("Select Anime"), items: _animeList.map((a) => DropdownMenuItem<String>(value: a['id'].toString(), child: Text(a['title'].toString()))).toList(), onChanged: (v) => setState(() => _selectedAnimeId = v)),
            const SizedBox(height: 12),
          ],
          TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Banner Name")), const SizedBox(height: 12),
          TextField(controller: _imageController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Banner Image URL (Landscape)")), const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _tagController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Tag (Trending, etc)"))), const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(dropdownColor: cardDark, value: _selectedColor, decoration: _inputDeco("Tag Color"), items: _colorOptions.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key, style: TextStyle(color: Color(int.parse(e.value, radix: 16)))))).toList(), onChanged: (v) => setState(() => _selectedColor = v!))),
          ]), const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(icon: const Icon(Icons.add_photo_alternate, color: Colors.white), label: const Text("Add to Hero Slider", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), onPressed: _addHero)),
          
          const SizedBox(height: 30), const Text("Current Hero Banners", style: TextStyle(color: adminPurple, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
          ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _heroItems.length, itemBuilder: (context, index) {
            final item = _heroItems[index];
            return Card(color: cardDark, child: ListTile(leading: Image.network(item['image_url'], width: 60, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const Icon(Icons.error)), title: Text(item['title'] ?? "No Title", style: const TextStyle(color: Colors.white)), subtitle: Text("Tag: ${item['tag']} | ${item['is_custom'] ? "Custom" : "Linked"}", style: const TextStyle(color: Colors.white54)), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteHero(item['id']))));
          })
        ],
      ),
    );
  }
  InputDecoration _inputDeco(String hint) => InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 14), filled: true, fillColor: cardDark, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none));
}

// ==========================================
// 6. REGISTERED USERS (PASSWORD RESET)
// ==========================================
class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});
  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetchUsers(); }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client.from('user_preferences').select('email').neq('email', '');
      Set<String> uniqueEmails = {};
      for (var row in data) { if (row['email'] != null) uniqueEmails.add(row['email']); }
      setState(() => _users = uniqueEmails.toList());
    } catch (e) {} finally { setState(() => _isLoading = false); }
  }

  Future<void> _sendResetLink(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reset Link sent to $email"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator(color: adminPurple))
      : _users.isEmpty 
        ? const Center(child: Text("No users found.", style: TextStyle(color: Colors.white54)))
        : Column(
            children: [
              Container(padding: const EdgeInsets.all(12), color: Colors.blueAccent.withOpacity(0.1), child: Row(children: const [Icon(Icons.info, color: Colors.blueAccent), SizedBox(width: 10), Expanded(child: Text("Passwords are encrypted. Click 'Send Link' to send a password reset email.", style: TextStyle(color: Colors.blueAccent, fontSize: 13)))])),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12), itemCount: _users.length,
                  itemBuilder: (context, index) {
                    String email = _users[index];
                    return Card(
                      color: cardDark, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [const CircleAvatar(backgroundColor: adminPurple, child: Icon(Icons.person, color: Colors.white)), const SizedBox(width: 12), Expanded(child: Text(email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))]),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Pass: [ Encrypted Hash ]", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic, fontSize: 12)),
                                ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), icon: const Icon(Icons.link, color: Colors.white, size: 16), label: const Text("Send Link", style: TextStyle(color: Colors.white, fontSize: 12)), onPressed: () => _sendResetLink(email))
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }
}

// ==========================================
// 7. APP SETTINGS (WEBSITE LINK & LOGO & SOCIALS & QR CODE)
// ==========================================
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});
  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _urlController = TextEditingController();
  final _logoController = TextEditingController();
  final _telegramController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _whatsappController = TextEditingController();

  final _qrUrlController = TextEditingController();
  final _upiIdController = TextEditingController();
  
  @override
  void initState() { super.initState(); _fetchSettings(); }

  Future<void> _fetchSettings() async {
    try {
      final res = await Supabase.instance.client.from('app_settings').select().eq('id', 1).maybeSingle();
      if(res != null) {
        setState(() {
          _urlController.text = res['website_url'] ?? "";
          _logoController.text = res['app_logo_url'] ?? "";
          _telegramController.text = res['telegram_url'] ?? "";
          _youtubeController.text = res['youtube_url'] ?? "";
          _whatsappController.text = res['whatsapp_url'] ?? "";
          _qrUrlController.text = res['payment_qr_url'] ?? "";
          _upiIdController.text = res['upi_id'] ?? "";
        });
      }
    } catch(e) {}
  }

  Future<void> _saveSettings() async {
    try {
      await Supabase.instance.client.from('app_settings').upsert({
        'id': 1, 
        'website_url': _urlController.text.trim(), 
        'app_logo_url': _logoController.text.trim(),
        'telegram_url': _telegramController.text.trim(),
        'youtube_url': _youtubeController.text.trim(),
        'whatsapp_url': _whatsappController.text.trim(),
        'payment_qr_url': _qrUrlController.text.trim(),
        'upi_id': _upiIdController.text.trim()
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings Updated Successfully!"), backgroundColor: Colors.green));
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving settings. Did you run the SQL query? Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("App Visuals & Links", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          const Text("Change user panel logo and website URL from here.", style: TextStyle(color: Colors.white54, fontSize: 13)), const SizedBox(height: 20),
          
          const Text("Website URL", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          TextField(controller: _urlController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "https://yourwebsite.com", filled: true, fillColor: cardDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 20),

          const Text("App Logo URL (PNG/WEBP)", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          TextField(controller: _logoController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "https://image-link.png", filled: true, fillColor: cardDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 30),

          const Divider(color: Colors.white12),
          const SizedBox(height: 20),

          const Text("Payment Settings (User Panel)", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
          
          const Text("Payment QR Code Image URL", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          TextField(controller: _qrUrlController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Enter QR Code Image Link", prefixIcon: const Icon(Icons.qr_code, color: Colors.amber), filled: true, fillColor: cardDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),

          const Text("UPI ID", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          TextField(controller: _upiIdController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "e.g. yourname@oksbi", prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.amber), filled: true, fillColor: cardDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 30),

          const Divider(color: Colors.white12),
          const SizedBox(height: 20),

          const Text("Social Media Integration", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
          
          const Text("Telegram Group Link", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          TextField(controller: _telegramController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "https://t.me/yourgroup", prefixIcon: const Icon(Icons.telegram, color: Colors.blueAccent), filled: true, fillColor: cardDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),

          const Text("YouTube Channel Link", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          TextField(controller: _youtubeController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "https://youtube.com/@yourchannel", prefixIcon: const Icon(Icons.play_circle_filled, color: Colors.redAccent), filled: true, fillColor: cardDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),

          const Text("WhatsApp Group/Contact Link", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          TextField(controller: _whatsappController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "https://wa.me/number OR group link", prefixIcon: const Icon(Icons.chat, color: Colors.greenAccent), filled: true, fillColor: cardDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 30),

          SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(icon: const Icon(Icons.save, color: Colors.white), label: const Text("Save All Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), onPressed: _saveSettings)),
        ],
      ),
    );
  }
}

// ==========================================
// 🔥 NEW: MANAGE APP PAGES (PRIVACY & GUIDE)
// ==========================================
class ManagePagesScreen extends StatefulWidget {
  const ManagePagesScreen({super.key});

  @override
  State<ManagePagesScreen> createState() => _ManagePagesScreenState();
}

class _ManagePagesScreenState extends State<ManagePagesScreen> {
  final _privacyPolicyController = TextEditingController();
  final _appGuideController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPages();
  }

  Future<void> _fetchPages() async {
    try {
      final res = await Supabase.instance.client.from('app_settings').select('privacy_policy, app_guide').eq('id', 1).maybeSingle();
      if(res != null) {
        setState(() {
          _privacyPolicyController.text = res['privacy_policy'] ?? "";
          _appGuideController.text = res['app_guide'] ?? "";
        });
      }
    } catch(e) { } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePages() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('app_settings').update({
        'privacy_policy': _privacyPolicyController.text.trim(),
        'app_guide': _appGuideController.text.trim()
      }).eq('id', 1);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pages Updated & Synced with User App!"), backgroundColor: Colors.green));
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving pages: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: adminPurple));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Manage User App Content", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          const Text("Changes made here will instantly reflect in the User App.", style: TextStyle(color: Colors.greenAccent, fontSize: 13)), const SizedBox(height: 20),

          const Text("Privacy Policy Content", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          TextField(
            controller: _privacyPolicyController, maxLines: 10, style: const TextStyle(color: Colors.white, height: 1.4),
            decoration: InputDecoration(hintText: "Enter complete Privacy Policy here...", filled: true, fillColor: cardDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))
          ),
          const SizedBox(height: 24),

          const Text("App Guide / How to Use", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          TextField(
            controller: _appGuideController, maxLines: 10, style: const TextStyle(color: Colors.white, height: 1.4),
            decoration: InputDecoration(hintText: "Enter full App Guide instructions here...", filled: true, fillColor: cardDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))
          ),
          const SizedBox(height: 30),

          SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(icon: const Icon(Icons.sync, color: Colors.white), label: const Text("Save & Sync to Users", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), onPressed: _savePages)),
        ],
      ),
    );
  }
}

// ==========================================
// 8. APP SOURCE CODE (OTA) UPDATE MANAGER
// ==========================================
class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key});
  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  final _versionController = TextEditingController();
  final _apkUrlController = TextEditingController();
  final _whatsNewController = TextEditingController();

  Future<void> _pushUpdate() async {
    if (_versionController.text.trim() == "1.0.0") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alert: Users pehle se 1.0.0 use kar rahe hain. 1.0.1 ya bada version daalein warna unhe popup nahi dikhega!"), backgroundColor: Colors.orange));
      return;
    }

    try {
      await Supabase.instance.client.from('app_updates').insert({
        'version': _versionController.text.trim(), 
        'apk_url': _apkUrlController.text.trim(), 
        'whats_new': _whatsNewController.text.trim()
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("App Update Alert Pushed Successfully!"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Push App Update (For Users)", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          const Text("Enter Version & Website Link. (Warning: Naya version purane se bada hona chahiye)", style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
          
          TextField(controller: _versionController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "New Version Number (e.g. 1.0.1)", hintStyle: const TextStyle(color: Colors.white38, fontSize: 14), filled: true, fillColor: cardDark, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), const SizedBox(height: 16),
          
          TextField(controller: _apkUrlController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Website/Download Link", hintStyle: const TextStyle(color: Colors.white38, fontSize: 14), filled: true, fillColor: cardDark, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), const SizedBox(height: 16),
          
          TextField(controller: _whatsNewController, maxLines: 4, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "What's New / Release Notes...", hintStyle: const TextStyle(color: Colors.white38, fontSize: 14), filled: true, fillColor: cardDark, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), const SizedBox(height: 24),
          
          SizedBox(height: 50, width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.send, color: Colors.white), label: const Text("Send Update Alert to Users", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), onPressed: _pushUpdate)),
        ],
      ),
    );
  }
}