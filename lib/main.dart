import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// GLOBAL CONFIG
// ==========================================
const Color adminPurple = Color(0xFF8A2BE2);
const Color bgDark = Color(0xFF0F0F13);
const Color cardDark = Color(0xFF1A1A24);

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
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: adminPurple,
        scaffoldBackgroundColor: bgDark,
        appBarTheme: const AppBarTheme(backgroundColor: bgDark, elevation: 0),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: adminPurple),
        ),
      ),
      home: const AdminAuthGate(),
    );
  }
}

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
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
// ADMIN LOGIN SCREEN
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

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: adminPurple.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings, size: 60, color: adminPurple),
                const SizedBox(height: 16),
                const Text("Admin Access", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: "Admin Email", filled: true, fillColor: bgDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: "Password", filled: true, fillColor: bgDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Login", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ADMIN DASHBOARD (3-LINE DRAWER MENU)
// ==========================================
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Widget _currentScreen = const ManagePaymentsScreen();
  String _currentTitle = "Payments";

  void _selectScreen(Widget screen, String title) {
    setState(() {
      _currentScreen = screen;
      _currentTitle = title;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle, style: const TextStyle(color: adminPurple, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: adminPurple), // 3 line hamburger icon color
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: cardDark,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: bgDark),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.admin_panel_settings, color: adminPurple, size: 40),
                    SizedBox(height: 10),
                    Text("Control Panel", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            _buildDrawerItem(Icons.payments, "Manage Payments", const ManagePaymentsScreen()),
            _buildDrawerItem(Icons.movie, "Upload Anime Poster", const ManageAnimeScreen()),
            _buildDrawerItem(Icons.video_library, "Manage Episodes", const ManageEpisodesScreen()),
            _buildDrawerItem(Icons.view_carousel, "Manage Hero Section", const ManageHeroScreen()),
            _buildDrawerItem(Icons.people, "Manage Users", const UsersListScreen()),
            _buildDrawerItem(Icons.system_update, "Push App Update", const AppUpdateScreen()),
          ],
        ),
      ),
      body: _currentScreen,
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () => _selectScreen(screen, title),
    );
  }
}

// ==========================================
// 1. MANAGE PAYMENTS (EDIT PRICE/PLAN, APPROVE, REJECT, DELETE)
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
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client.from('payment_requests').select().order('created_at', ascending: false);
      setState(() => _requests = data);
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    await Supabase.instance.client.from('payment_requests').update({'status': newStatus}).eq('id', id);
    _fetchRequests();
  }

  Future<void> _deleteRequest(String id) async {
    await Supabase.instance.client.from('payment_requests').delete().eq('id', id);
    _fetchRequests();
  }

  // Admin Price/Plan Edit function
  Future<void> _editPlanDialog(String id, String currentPlan) async {
    TextEditingController planController = TextEditingController(text: currentPlan);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        title: const Text("Edit User's Plan/Price", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: planController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter Correct Plan details",
            hintStyle: TextStyle(color: Colors.white38),
            filled: true,
            fillColor: bgDark,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.from('payment_requests').update({'plan': planController.text}).eq('id', id);
              if(mounted) Navigator.pop(context);
              _fetchRequests();
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  void _showProofDialog(String imageUrl, String email, String utr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        title: Text("Proof from \n$email", style: const TextStyle(color: Colors.white, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("UTR: $utr", style: const TextStyle(color: adminPurple, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            imageUrl.startsWith('http') 
                ? Image.network(imageUrl, height: 300, fit: BoxFit.contain)
                : const Text("No Valid Image Found", style: TextStyle(color: Colors.white54)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: adminPurple)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator(color: adminPurple))
      : _requests.isEmpty 
        ? const Center(child: Text("No payments found.", style: TextStyle(color: Colors.white54)))
        : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _requests.length,
          itemBuilder: (context, index) {
            final req = _requests[index];
            return Card(
              color: cardDark,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${req['email']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Plan: ${req['plan']}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        GestureDetector(
                          onTap: () => _editPlanDialog(req['id'], req['plan']),
                          child: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                        )
                      ],
                    ),
                    Text("UTR: ${req['transaction_id']}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text("Status: ${req['status']}", style: TextStyle(color: req['status'] == 'Approved' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                    const Divider(color: Colors.white12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(icon: const Icon(Icons.image, color: Colors.blue), onPressed: () => _showProofDialog(req['image_path'], req['email'], req['transaction_id'])),
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
// 2. MANAGE ANIME POSTERS & CATEGORIES
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

  Future<void> _addAnime() async {
    try {
      await Supabase.instance.client.from('anime_list').insert({
        'title': _titleController.text,
        'description': _descController.text,
        'image_url': _imageController.text,
        'category': _mainCategoryController.text,
        'sub_category': _subCategoryController.text,
        'dub_status': _selectedDub,
        'rating': _selectedRating,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anime Added Successfully!"), backgroundColor: Colors.green));
      _titleController.clear(); _descController.clear(); _imageController.clear(); _mainCategoryController.clear(); _subCategoryController.clear();
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
          const Text("Upload Anime Profile/Poster", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Anime Name (e.g. Naruto)")),
          const SizedBox(height: 12),
          TextField(controller: _descController, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Description")),
          const SizedBox(height: 12),
          TextField(controller: _imageController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Poster Image URL")),
          const SizedBox(height: 12),
          TextField(controller: _mainCategoryController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Main Category (e.g. Action)")),
          const SizedBox(height: 12),
          TextField(controller: _subCategoryController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Sub Category (e.g. Romance, Comedy, Thriller)")),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  dropdownColor: cardDark,
                  value: _selectedDub,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco("Dub Status"),
                  items: ['DUB', 'ORIGINAL', 'MIX O/D'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedDub = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  dropdownColor: cardDark,
                  value: _selectedRating,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco("Rating"),
                  items: ['PG-13', 'R-17+', 'All Ages'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedRating = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload, color: Colors.white),
              label: const Text("Upload Anime Profile", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _addAnime,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      filled: true,
      fillColor: cardDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple)),
    );
  }
}

// ==========================================
// 3. MANAGE EPISODES (NEW SECTION)
// ==========================================
class ManageEpisodesScreen extends StatefulWidget {
  const ManageEpisodesScreen({super.key});

  @override
  State<ManageEpisodesScreen> createState() => _ManageEpisodesScreenState();
}

class _ManageEpisodesScreenState extends State<ManageEpisodesScreen> {
  List<dynamic> _animeList = [];
  String? _selectedAnimeId;
  
  final _seasonController = TextEditingController();
  final _episodeTitleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _durationController = TextEditingController();
  final _videoUrlController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnimeList();
  }

  Future<void> _fetchAnimeList() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client.from('anime_list').select('id, title').order('created_at', ascending: false);
      setState(() {
        _animeList = data;
        if(data.isNotEmpty) _selectedAnimeId = data[0]['id'];
      });
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadEpisode() async {
    if (_selectedAnimeId == null || _seasonController.text.isEmpty || _videoUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anime, Season, and Video URL are required.")));
      return;
    }

    try {
      // 1. Check if Season exists for this Anime
      final seasonRes = await Supabase.instance.client.from('anime_seasons')
          .select('id')
          .eq('anime_id', _selectedAnimeId!)
          .eq('season_name', _seasonController.text.trim())
          .maybeSingle();

      String seasonId;
      if (seasonRes == null) {
        // Create new Season
        final newSeason = await Supabase.instance.client.from('anime_seasons').insert({
          'anime_id': _selectedAnimeId,
          'season_name': _seasonController.text.trim()
        }).select('id').single();
        seasonId = newSeason['id'];
      } else {
        seasonId = seasonRes['id'];
      }

      // 2. Insert Episode
      await Supabase.instance.client.from('anime_episodes').insert({
        'season_id': seasonId,
        'episode_title': _episodeTitleController.text.isEmpty ? "Episode" : _episodeTitleController.text,
        'image_url': _imageUrlController.text,
        'duration': _durationController.text.isEmpty ? "24m" : _durationController.text,
        'video_url': _videoUrlController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Episode Uploaded Successfully!"), backgroundColor: Colors.green));
      _episodeTitleController.clear(); _imageUrlController.clear(); _durationController.clear(); _videoUrlController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
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
          const Text("Upload New Episode", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            dropdownColor: cardDark,
            value: _selectedAnimeId,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDeco("Select Anime"),
            items: _animeList.map((a) => DropdownMenuItem<String>(value: a['id'].toString(), child: Text(a['title'].toString()))).toList(),
            onChanged: (v) => setState(() => _selectedAnimeId = v),
          ),
          const SizedBox(height: 12),
          TextField(controller: _seasonController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Season Name (e.g. Season 1, S1, Movie)")),
          const SizedBox(height: 12),
          TextField(controller: _episodeTitleController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Episode Title (e.g. Episode 1, The Beginning)")),
          const SizedBox(height: 12),
          TextField(controller: _imageUrlController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Episode Thumbnail URL")),
          const SizedBox(height: 12),
          TextField(controller: _durationController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Duration (e.g. 24m 10s)")),
          const SizedBox(height: 12),
          TextField(controller: _videoUrlController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Direct Video URL / Streaming Link")),
          const SizedBox(height: 24),
          
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload, color: Colors.white),
              label: const Text("Upload Episode", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _uploadEpisode,
            ),
          ),
          // Note: Full deletion and management lists can be expanded here
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      filled: true,
      fillColor: cardDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple)),
    );
  }
}

// ==========================================
// 4. MANAGE HERO SECTION (TOP SLIDER)
// ==========================================
class ManageHeroScreen extends StatefulWidget {
  const ManageHeroScreen({super.key});

  @override
  State<ManageHeroScreen> createState() => _ManageHeroScreenState();
}

class _ManageHeroScreenState extends State<ManageHeroScreen> {
  final _titleController = TextEditingController();
  final _imageController = TextEditingController();
  
  List<dynamic> _animeList = [];
  String? _selectedAnimeId; // Will be null if it's Custom
  bool _isCustom = false;
  
  List<dynamic> _heroItems = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final animes = await Supabase.instance.client.from('anime_list').select('id, title');
      final heroes = await Supabase.instance.client.from('hero_slider').select().order('created_at', ascending: false);
      setState(() {
        _animeList = animes;
        _heroItems = heroes;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _addHero() async {
    try {
      await Supabase.instance.client.from('hero_slider').insert({
        'title': _titleController.text,
        'image_url': _imageController.text,
        'anime_id': _isCustom ? null : _selectedAnimeId,
        'is_custom': _isCustom,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hero Added!"), backgroundColor: Colors.green));
      _titleController.clear(); _imageController.clear();
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteHero(String id) async {
    await Supabase.instance.client.from('hero_slider').delete().eq('id', id);
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Add Hero Banner", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text("Custom Banner (Not linked to Anime App Content)", style: TextStyle(color: Colors.white)),
            activeColor: adminPurple,
            value: _isCustom,
            onChanged: (val) => setState(() => _isCustom = val),
          ),
          
          if (!_isCustom) ...[
            DropdownButtonFormField<String>(
              dropdownColor: cardDark,
              value: _selectedAnimeId,
              hint: const Text("Link to Existing Anime", style: TextStyle(color: Colors.white54)),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco("Select Anime"),
              items: _animeList.map((a) => DropdownMenuItem<String>(value: a['id'].toString(), child: Text(a['title'].toString()))).toList(),
              onChanged: (v) => setState(() => _selectedAnimeId = v),
            ),
            const SizedBox(height: 12),
          ],
          
          TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Banner Title / Tag")),
          const SizedBox(height: 12),
          TextField(controller: _imageController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Banner Image URL (Landscape)")),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
              label: const Text("Add to Hero Slider", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _addHero,
            ),
          ),
          const SizedBox(height: 30),
          
          const Text("Current Hero Banners", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _heroItems.length,
            itemBuilder: (context, index) {
              final item = _heroItems[index];
              return Card(
                color: cardDark,
                child: ListTile(
                  leading: Image.network(item['image_url'], width: 60, fit: BoxFit.cover),
                  title: Text(item['title'] ?? "No Title", style: const TextStyle(color: Colors.white)),
                  subtitle: Text(item['is_custom'] ? "Custom Banner" : "Linked Anime", style: const TextStyle(color: adminPurple)),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteHero(item['id'])),
                ),
              );
            }
          )
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      filled: true,
      fillColor: cardDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple)),
    );
  }
}


// ==========================================
// 5. REGISTERED USERS SCREEN (WITH RESET PASS GUIDE)
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
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client.from('user_preferences').select('email').neq('email', '');
      Set<String> uniqueEmails = {};
      for (var row in data) {
        if (row['email'] != null) uniqueEmails.add(row['email']);
      }
      setState(() => _users = uniqueEmails.toList());
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPasswordInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        title: const Text("Security Alert", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          "Supabase security rules ki wajah se kisi bhi user ka password dekhna impossible hai kyunki wo Encrypted hota hai.\n\nAgar kisi user ko naya password chahiye, toh aapko apne Supabase Dashboard -> Authentication -> Users me jaakar uska password Reset/Override karna hoga.",
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Understood", style: TextStyle(color: adminPurple)))
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator(color: adminPurple))
      : _users.isEmpty 
        ? const Center(child: Text("No users found.", style: TextStyle(color: Colors.white54)))
        : Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.redAccent.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(child: const Text("Passwords are encrypted. You cannot view them.", style: TextStyle(color: Colors.redAccent, fontSize: 12))),
                    TextButton(onPressed: _showPasswordInfo, child: const Text("How to Reset?", style: TextStyle(color: Colors.white)))
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    String email = _users[index];
                    return Card(
                      color: cardDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const CircleAvatar(backgroundColor: adminPurple, child: Icon(Icons.person, color: Colors.white)),
                        title: Text(email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text("Status: Active User", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy, color: Colors.blueAccent),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: email));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email Copied!")));
                          },
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
// 6. APP SOURCE CODE (OTA) UPDATE MANAGER
// ==========================================
class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key});

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  final _mainDartController = TextEditingController();
  final _pubspecController = TextEditingController();
  final _versionController = TextEditingController();

  Future<void> _pushUpdate() async {
    try {
      await Supabase.instance.client.from('app_updates').insert({
        'version': _versionController.text,
        'main_dart_code': _mainDartController.text,
        'pubspec_code': _pubspecController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("App Code Pushed Successfully!"), backgroundColor: Colors.green));
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
          const Text("Push Remote App Update", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Save main.dart and pubspec.yaml configuration to Database.", style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 20),
          
          TextField(
            controller: _versionController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDeco("App Version (e.g. v2.1.0)"),
          ),
          const SizedBox(height: 16),
          
          const Text("main.dart Source Code", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _mainDartController,
            maxLines: 10,
            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
            decoration: _inputDeco("Paste updated main.dart code here..."),
          ),
          const SizedBox(height: 16),

          const Text("pubspec.yaml Source Code", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _pubspecController,
            maxLines: 6,
            style: const TextStyle(color: Colors.amberAccent, fontFamily: 'monospace', fontSize: 12),
            decoration: _inputDeco("Paste updated pubspec.yaml here..."),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.system_update_alt, color: Colors.white),
              label: const Text("Push Update to Database", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _pushUpdate,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      filled: true,
      fillColor: cardDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple)),
    );
  }
}