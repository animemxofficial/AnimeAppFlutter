import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// GLOBAL CONFIG
// ==========================================
const Color adminPurple = Color(0xFF8A2BE2);
const Color bgDark = Color(0xFF0F0F13);
const Color cardDark = Color(0xFF1A1A24);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Apne Supabase credentials yahan daalein
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
      title: 'AnimeMX Admin',
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
          // Add extra logic here if you only want specific emails to access admin
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
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
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
              const Text("AnimeMX Admin Panel", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
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
                decoration: InputDecoration(hintText: "Admin Password", filled: true, fillColor: bgDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Access Control Panel", style: TextStyle(fontWeight: FontWeight.bold)),
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
// ADMIN DASHBOARD (NAVIGATION)
// ==========================================
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ManagePaymentsScreen(),
    const ManageAnimeScreen(),
    const UsersListScreen(),
    const AppUpdateScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mera Anime MX - Admin Control", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          )
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: cardDark,
            child: ListView(
              children: [
                _buildNavItem(0, Icons.payments, "Payment Approvals"),
                _buildNavItem(1, Icons.movie, "Manage Anime Content"),
                _buildNavItem(2, Icons.people, "Registered Users"),
                _buildNavItem(3, Icons.system_update, "App Source Code Update"),
              ],
            ),
          ),
          // Main Content
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? adminPurple : Colors.white54),
      title: Text(title, style: TextStyle(color: isSelected ? adminPurple : Colors.white54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }
}

// ==========================================
// 1. MANAGE PAYMENTS (APPROVE/REJECT/DELETE)
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

  void _showProofDialog(String imageUrl, String email, String utr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        title: Text("Proof from $email", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("UTR: $utr", style: const TextStyle(color: adminPurple, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            imageUrl.startsWith('http') 
                ? Image.network(imageUrl, height: 400, fit: BoxFit.contain)
                : const Text("No Valid Image Found", style: TextStyle(color: Colors.white54)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator(color: adminPurple))
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _requests.length,
          itemBuilder: (context, index) {
            final req = _requests[index];
            return Card(
              color: cardDark,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text("${req['email']} - ${req['plan']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("UTR: ${req['transaction_id']} | Status: ${req['status']}", style: TextStyle(color: req['status'] == 'Approved' ? Colors.green : Colors.orange)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.image, color: Colors.blue), onPressed: () => _showProofDialog(req['image_path'], req['email'], req['transaction_id'])),
                    IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _updateStatus(req['id'], 'Approved')),
                    IconButton(icon: const Icon(Icons.cancel, color: Colors.orange), onPressed: () => _updateStatus(req['id'], 'Rejected')),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteRequest(req['id'])),
                  ],
                ),
              ),
            );
          },
        );
  }
}

// ==========================================
// 2. MANAGE ANIME CONTENT (ADD & EDIT)
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
  final _categoryController = TextEditingController(); // e.g Action, Romance, Trending Now
  
  String _selectedDub = 'DUB';
  String _selectedRating = 'PG-13';
  bool _isHeroSlider = false;

  Future<void> _addAnime() async {
    try {
      await Supabase.instance.client.from('anime_list').insert({
        'title': _titleController.text,
        'description': _descController.text,
        'image_url': _imageController.text,
        'category': _categoryController.text,
        'dub_status': _selectedDub,
        'rating': _selectedRating,
        'is_hero_slider': _isHeroSlider,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anime Added Successfully!"), backgroundColor: Colors.green));
      _titleController.clear(); _descController.clear(); _imageController.clear(); _categoryController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Upload New Anime", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Anime Title (e.g. Naruto)")),
          const SizedBox(height: 12),
          TextField(controller: _descController, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Description")),
          const SizedBox(height: 12),
          TextField(controller: _imageController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Poster Image URL")),
          const SizedBox(height: 12),
          TextField(controller: _categoryController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Category (e.g. Action, Romance, Thriller, Trending Now)")),
          const SizedBox(height: 20),
          
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
              const SizedBox(width: 16),
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
          const SizedBox(height: 20),

          CheckboxListTile(
            title: const Text("Show in Hero Section (Top Slider)?", style: TextStyle(color: Colors.white)),
            value: _isHeroSlider,
            activeColor: adminPurple,
            onChanged: (val) => setState(() => _isHeroSlider = val!),
          ),

          const SizedBox(height: 30),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload, color: Colors.white),
              label: const Text("Upload Anime to Database", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _addAnime,
            ),
          ),

          const SizedBox(height: 40),
          const Text("Note: Automatically Popular Anime", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text("Jo anime app me zyada views gain karega, wo automatically 'Popular Section' me show hoga (based on 'episode_views' table). Aapko manually set karne ki zaroorat nahi hai.", style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: cardDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple)),
    );
  }
}

// ==========================================
// 3. REGISTERED USERS SCREEN
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
      // Note: Direct auth.users fetch requires Service Role Key. 
      // We fetch from user_preferences table which acts as user profiles.
      final data = await Supabase.instance.client.from('user_preferences').select('email').neq('email', '');
      
      // Make unique list of emails
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

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator(color: adminPurple))
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            String email = _users[index];
            return Card(
              color: cardDark,
              child: ListTile(
                leading: const Icon(Icons.person, color: adminPurple),
                title: Text(email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("Password: [ Encrypted Hash for Security ]", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
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
        );
  }
}

// ==========================================
// 4. APP SOURCE CODE (OTA) UPDATE MANAGER
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Push Remote App Update", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Save main.dart and pubspec.yaml configuration to Database.", style: TextStyle(color: Colors.white54)),
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
            maxLines: 15,
            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
            decoration: _inputDeco("Paste updated main.dart code here..."),
          ),
          const SizedBox(height: 16),

          const Text("pubspec.yaml Source Code", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _pubspecController,
            maxLines: 8,
            style: const TextStyle(color: Colors.amberAccent, fontFamily: 'monospace', fontSize: 12),
            decoration: _inputDeco("Paste updated pubspec.yaml here..."),
          ),
          const SizedBox(height: 30),

          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.system_update_alt, color: Colors.white),
              label: const Text("Push Update to Database", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _pushUpdate,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: cardDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple)),
    );
  }
}