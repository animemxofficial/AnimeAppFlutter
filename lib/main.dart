import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui' as ui;

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

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: bgDark,
    statusBarColor: Colors.transparent,
  ));

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
        fontFamily: 'Roboto', // Modern standard font
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark, 
          elevation: 0, 
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: adminPurple, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: adminPurple))
          );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: $e"), backgroundColor: Colors.redAccent)
      );
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          Positioned(
            top: -100, left: -50, right: -50,
            child: Container(
              height: 500, 
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [adminPurple.withOpacity(0.2), Colors.transparent], 
                  radius: 0.8
                )
              )
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
                  color: cardDark, 
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: adminPurple.withOpacity(0.05), blurRadius: 30, spreadRadius: 5)],
                  border: Border.all(color: Colors.white10, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: adminPurple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_moon_outlined, size: 60, color: adminPurple),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(text: "SYNEX ", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 1)), 
                          TextSpan(text: "ADMIN", style: TextStyle(color: adminPurple, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 1))
                        ]
                      )
                    ),
                    const SizedBox(height: 8),
                    const Text("Master Control Center", style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1)),
                    const SizedBox(height: 36),
                    
                    TextField(
                      controller: _emailController, 
                      style: const TextStyle(color: Colors.white), 
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54), 
                        hintText: "Admin Email", 
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true, 
                        fillColor: bgDark, 
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple, width: 1.5)),
                      )
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController, 
                      obscureText: _obscureText, 
                      style: const TextStyle(color: Colors.white), 
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54), 
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white54), 
                          onPressed: ()=>setState(()=>_obscureText = !_obscureText)
                        ), 
                        hintText: "Password", 
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true, 
                        fillColor: bgDark, 
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple, width: 1.5)),
                      )
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity, 
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text("ENTER DASHBOARD", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15, letterSpacing: 1)),
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
  String _currentTitle = "Dashboard";
  int _bottomNavIndex = 0;

  void _selectScreen(Widget screen, String title, int navIndex) {
    setState(() { 
      _currentScreen = screen; 
      _currentTitle = title; 
      _bottomNavIndex = navIndex;
    });
  }

  void _onDrawerItemTap(Widget screen, String title, int navIndex) {
    _selectScreen(screen, title, navIndex);
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_currentTitle, style: const TextStyle(color: adminPurple, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white), 
            onPressed: () {}
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: bgDark,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: cardDark),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: adminPurple, shape: BoxShape.circle),
                    child: const Icon(Icons.security, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(text: "SYNEX ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), 
                            TextSpan(text: "ADMIN", style: TextStyle(color: adminPurple, fontSize: 18, fontWeight: FontWeight.w900))
                          ]
                        )
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Text("Master Access Enabled", style: TextStyle(color: Colors.white54, fontSize: 11)),
                          SizedBox(width: 4),
                          Icon(Icons.verified, color: Colors.amber, size: 12)
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  _buildDrawerItem(Icons.dashboard_rounded, "Dashboard", const AdminHomeScreen(), 0),
                  const SizedBox(height: 12),
                  _buildDrawerItem(Icons.payments_rounded, "Manage Payments", const ManagePaymentsScreen(), 1),
                  _buildDrawerItem(Icons.people_alt_rounded, "Manage Users", const UsersListScreen(), 1),
                  const SizedBox(height: 12),
                  _buildDrawerItem(Icons.movie_rounded, "Manage Anime", const ManageAnimeScreen(), 2),
                  _buildDrawerItem(Icons.play_circle_fill_rounded, "Manage Episodes", const ManageEpisodesScreen(), 3),
                  _buildDrawerItem(Icons.view_carousel_rounded, "Hero Section", const ManageHeroScreen(), 3),
                  const SizedBox(height: 12),
                  _buildDrawerItem(Icons.link_rounded, "Manage Links", const AppSettingsScreen(), 4),
                  _buildDrawerItem(Icons.policy_rounded, "Manage Pages", const ManagePagesScreen(), 4),
                  _buildDrawerItem(Icons.system_update_rounded, "Manage Update's", const AppUpdateScreen(), 4),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    onTap: () => Supabase.instance.client.auth.signOut(),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      body: _currentScreen,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardDark,
          border: const Border(top: BorderSide(color: Colors.white10, width: 1))
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home_rounded, "Dashboard", 0, () => _selectScreen(const AdminHomeScreen(), "Dashboard", 0)),
            _buildBottomNavItem(Icons.group_rounded, "Users", 1, () => _selectScreen(const UsersListScreen(), "Manage Users", 1)),
            
            // Center Floating Action Button replacement for navigation
            GestureDetector(
              onTap: () => _selectScreen(const ManageAnimeScreen(), "Manage Anime", 2),
              child: Container(
                height: 56, width: 56,
                decoration: BoxDecoration(
                  color: adminPurple,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: adminPurple.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)]
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ),
            
            _buildBottomNavItem(Icons.video_library_rounded, "Content", 3, () => _selectScreen(const ManageEpisodesScreen(), "Manage Episodes", 3)),
            _buildBottomNavItem(Icons.settings_rounded, "Settings", 4, () => _selectScreen(const AppSettingsScreen(), "Manage Links", 4)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Widget screen, int navIndex) {
    bool isSelected = _currentTitle == title;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? adminPurple.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12)
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: isSelected ? adminPurple : Colors.white70),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
        onTap: () => _onDrawerItemTap(screen, title, navIndex),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index, VoidCallback onTap) {
    bool isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? adminPurple : Colors.white54, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSelected ? adminPurple : Colors.white54, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))
        ],
      ),
    );
  }
}

// ==========================================
// 1. DASHBOARD HOME
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
  int offlineUsers = 0;
  int dailyActiveUsers = 0; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final userRes = await Supabase.instance.client.from('user_preferences').select('email');
      Set<String> uniqueEmails = {};
      for(var r in userRes) { 
        if(r['email'] != null) uniqueEmails.add(r['email']); 
      }
      totalUsers = uniqueEmails.length;

      final premiumRes = await Supabase.instance.client.from('payment_requests').select('email').eq('status', 'Approved');
      Set<String> premiumEmails = {};
      for(var r in premiumRes) { 
        if(r['email'] != null) premiumEmails.add(r['email']); 
      }
      premiumUsers = premiumEmails.length;

      freeUsers = totalUsers - premiumUsers;
      if(freeUsers < 0) freeUsers = 0;
      
      offlineUsers = totalUsers; // Simplified

      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day).toUtc().toIso8601String();
      try {
        final dailyRes = await Supabase.instance.client.from('user_views').select('user_id').gte('created_at', startOfToday);
        Set<String> uniqueDaily = {};
        for(var r in dailyRes) { 
          if(r['user_id'] != null) uniqueDaily.add(r['user_id'].toString()); 
        }
        dailyActiveUsers = uniqueDaily.length;
      } catch(e) { }
      
      setState(() => _isLoading = false);
    } catch(e) { 
      setState(() => _isLoading = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    if(_isLoading) return const Center(child: CircularProgressIndicator(color: adminPurple));
    
    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: adminPurple,
      backgroundColor: cardDark,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Overview Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2E1065), Color(0xFF1E1B4B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: adminPurple.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.insights, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Overview Analytics", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("Track your app performance and user engagement", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text("Analytics Overview", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            GridView(
              shrinkWrap: true, 
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio: 1.25, 
                crossAxisSpacing: 16, 
                mainAxisSpacing: 16
              ),
              children: [
                _buildStatCard("Total Members", totalUsers.toString(), Icons.people_alt, const Color(0xFF0284C7), "+100%"),
                _buildStatCard("Premium Members", premiumUsers.toString(), Icons.workspace_premium, const Color(0xFFD97706), "+100%"),
                _buildStatCard("Daily Active Users", dailyActiveUsers.toString(), Icons.local_fire_department, const Color(0xFFEA580C), "0%"),
                _buildStatCard("Free Users", freeUsers.toString(), Icons.person, adminPurple, "+100%"),
                _buildStatCard("Offline Now", offlineUsers.toString(), Icons.cloud_off, const Color(0xFFDC2626), "-100%"),
                
                // Logout Card
                GestureDetector(
                  onTap: () => Supabase.instance.client.auth.signOut(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardDark, 
                      borderRadius: BorderRadius.circular(16), 
                      border: Border.all(color: Colors.white10)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8), 
                          decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.15), borderRadius: BorderRadius.circular(8)), 
                          child: const Icon(Icons.logout_rounded, color: Color(0xFF10B981), size: 24)
                        ),
                        const Spacer(),
                        const Text("Log Out", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text("Sign out from admin", style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),

            // Custom User Growth Chart UI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.show_chart, color: adminPurple, size: 20),
                          SizedBox(width: 8),
                          Text("User Growth", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text("View Report", style: TextStyle(color: adminPurple, fontSize: 12, fontWeight: FontWeight.bold))
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: ChartPainter(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("May 5", style: TextStyle(color: Colors.white54, fontSize: 10)),
                      Text("May 10", style: TextStyle(color: Colors.white54, fontSize: 10)),
                      Text("May 15", style: TextStyle(color: Colors.white54, fontSize: 10)),
                      Text("May 20", style: TextStyle(color: Colors.white54, fontSize: 10)),
                      Text("May 25", style: TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, String trend) {
    bool isPositive = trend.contains("+");
    bool isZero = trend.contains("0%");
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.white10)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8), 
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), 
                child: Icon(icon, color: color, size: 24)
              ),
            ],
          ),
          const Spacer(),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isZero ? Icons.remove : (isPositive ? Icons.arrow_upward : Icons.arrow_downward), 
                color: isZero ? Colors.grey : (isPositive ? Colors.green : Colors.red), 
                size: 12
              ),
              const SizedBox(width: 4),
              Text("$trend vs last month", style: TextStyle(color: isZero ? Colors.grey : (isPositive ? Colors.green : Colors.red), fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }
}

// User Growth Line Chart Painter
class ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = adminPurple
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Mock data points
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.4, size.height * 0.6),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.4),
      Offset(size.width, size.height * 0.1),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Gradient Fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final gradientPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [adminPurple.withOpacity(0.3), Colors.transparent],
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, gradientPaint);
    canvas.drawPath(path, paint);

    // Draw Dots
    final dotPaint = Paint()
      ..color = adminPurple
      ..style = PaintingStyle.fill;
      
    for (var point in points) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    } finally { 
      setState(() => _isLoading = false); 
    }
  }

  Future<void> _updateStatus(dynamic id, String newStatus) async {
    try {
      await Supabase.instance.client.from('payment_requests').update({'status': newStatus}).eq('id', id.toString());
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment $newStatus"), backgroundColor: newStatus == 'Approved' ? Colors.green : Colors.orange));
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

  Future<void> _editPaymentDialog(Map<String, dynamic> req) async {
    TextEditingController planController = TextEditingController(text: req['plan'] ?? '');
    TextEditingController amountController = TextEditingController(text: req['amount']?.toString() ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
        title: const Text("Edit Payment Info", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: planController, 
              style: const TextStyle(color: Colors.white), 
              decoration: InputDecoration(labelText: "Plan Name", labelStyle: const TextStyle(color: adminPurple), filled: true, fillColor: bgDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController, 
              style: const TextStyle(color: Colors.white), 
              decoration: InputDecoration(labelText: "Amount (₹)", labelStyle: const TextStyle(color: adminPurple), filled: true, fillColor: bgDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client.from('payment_requests').update({
                  'plan': planController.text,
                  'amount': amountController.text
                }).eq('id', req['id'].toString());
                if(mounted) Navigator.pop(context);
                _fetchRequests();
              } catch(e) {}
            },
            child: const Text("Save")
          )
        ]
      )
    );
  }

  void _showProofDialog(String imageUrl, String utr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("UTR: $utr", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            imageUrl.startsWith('http') 
              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, height: 350, fit: BoxFit.cover)) 
              : const Text("No Proof Image", style: TextStyle(color: Colors.white54))
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: adminPurple)))
        ]
      )
    );
  }

  String _formatDateGroup(String? isoString) {
    if (isoString == null) return "Unknown Time";
    DateTime parsedDate = DateTime.parse(isoString);
    DateTime date = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, parsedDate.hour, parsedDate.minute);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    DateTime checkDate = DateTime(date.year, date.month, date.day);

    String ampm = date.hour >= 12 ? 'PM' : 'AM';
    int hr = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    String timeStr = "$hr:${date.minute.toString().padLeft(2, '0')} $ampm";

    if (checkDate == today) return "Today at $timeStr";
    if (checkDate == yesterday) return "Yesterday at $timeStr";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at $timeStr";
  }

  @override
  Widget build(BuildContext context) {
    int total = _requests.length;
    int approved = _requests.where((r) => r['status'] == 'Approved').length;
    int pending = _requests.where((r) => r['status'] == 'Pending').length;
    int rejected = _requests.where((r) => r['status'] == 'Rejected').length;

    return Column(
      children: [
        // STATS ROW
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(child: _buildTopStatCard("Total", total.toString(), adminPurple, Icons.attach_money)),
              const SizedBox(width: 8),
              Expanded(child: _buildTopStatCard("Approved", approved.toString(), const Color(0xFF10B981), Icons.check_circle)),
              const SizedBox(width: 8),
              Expanded(child: _buildTopStatCard("Pending", pending.toString(), const Color(0xFFF59E0B), Icons.access_time_filled)),
              const SizedBox(width: 8),
              Expanded(child: _buildTopStatCard("Rejected", rejected.toString(), const Color(0xFFEF4444), Icons.cancel)),
            ],
          ),
        ),
        
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: adminPurple)) 
            : _requests.isEmpty 
              ? const Center(child: Text("No payments found.", style: TextStyle(color: Colors.white54))) 
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16), 
                  itemCount: _requests.length, 
                  itemBuilder: (context, index) { 
                    final req = _requests[index]; 
                    String displayTime = _formatDateGroup(req['created_at']); 
                    String userName = req['name'] ?? "Unknown User"; // Fetch actual name
                    String uid = req['uid'] ?? req['transaction_id']?.substring(0, 8) ?? "N/A"; // Display UID
                    String amount = req['amount']?.toString() ?? "₹0.00";
                    
                    Color statusColor = req['status'] == 'Approved' ? const Color(0xFF10B981) : (req['status'] == 'Rejected' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: adminPurple.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.person, color: adminPurple),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 2),
                                      Text("UID $uid", style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                  child: Text(req['status'], style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Info Grid
                            Row(
                              children: [
                                Expanded(child: _buildInfoItem(Icons.auto_graph, "Plan", req['plan'] ?? 'Unknown')),
                                Expanded(child: _buildInfoItem(Icons.calendar_month, "Date & Time", displayTime, color: const Color(0xFFF59E0B))),
                                Expanded(child: _buildInfoItem(Icons.monetization_on_outlined, "Amount", "₹$amount")),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // UTR
                            Row(
                              children: [
                                const Text("UTR  ", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(req['transaction_id'] ?? 'N/A', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                const Spacer(),
                                const Icon(Icons.copy, color: adminPurple, size: 16)
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildActionButton(Icons.image, "Proof", const Color(0xFF3B82F6), () => _showProofDialog(req['image_path'], req['transaction_id'])),
                                _buildActionButton(Icons.check, "Approve", const Color(0xFF10B981), () => _updateStatus(req['id'], 'Approved')),
                                _buildActionButton(Icons.close, "Reject", const Color(0xFFF59E0B), () => _updateStatus(req['id'], 'Rejected')),
                                _buildActionButton(Icons.edit, "Edit", adminPurple, () => _editPaymentDialog(req)),
                                _buildActionButton(Icons.delete, "Delete", const Color(0xFFEF4444), () => _deleteRequest(req['id'])),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  }
                ),
        ),
      ],
    );
  }

  Widget _buildTopStatCard(String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 8),
          Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {Color color = adminPurple}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: label == "Date & Time" ? color : Colors.white, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
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
  List<dynamic> _animeList = []; 
  bool _isLoading = false;

  @override
  void initState() { 
    super.initState(); 
    _fetchAnime(); 
  }

  Future<void> _fetchAnime() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client.from('anime_list').select().order('created_at', ascending: false);
      setState(() => _animeList = data);
    } catch (e) {
    } finally { 
      setState(() => _isLoading = false); 
    }
  }

  Future<void> _addAnime() async {
    if(_titleController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('anime_list').insert({
        'title': _titleController.text, 
        'description': _descController.text, 
        'image_url': _imageController.text, 
        'category': _mainCategoryController.text, 
        'sub_category': _subCategoryController.text, 
        'dub_status': _selectedDub, 
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anime Added"), backgroundColor: Colors.green));
      _titleController.clear(); 
      _descController.clear(); 
      _imageController.clear(); 
      _mainCategoryController.clear(); 
      _subCategoryController.clear();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Anime", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Title", Icons.title)),
              const SizedBox(height: 8),
              TextField(controller: _imageController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Image URL", Icons.image)),
              const SizedBox(height: 8),
              TextField(controller: _mainCategoryController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Main Category", Icons.category)),
              const SizedBox(height: 8),
              TextField(controller: _subCategoryController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Sub Category", Icons.sell)),
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
              _titleController.clear(); 
              _imageController.clear(); 
              _mainCategoryController.clear(); 
              _subCategoryController.clear();
              _fetchAnime();
            },
            child: const Text("Update")
          )
        ]
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: adminPurple.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.upload, color: adminPurple),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Upload Anime Profile", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Add new anime to your platform", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Form
          TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Anime Name", Icons.text_fields)), 
          const SizedBox(height: 12),
          TextField(controller: _descController, maxLines: 4, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Description", Icons.description)), 
          const SizedBox(height: 12),
          TextField(controller: _imageController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Poster Image URL", Icons.image)), 
          const SizedBox(height: 12),
          TextField(controller: _mainCategoryController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Main Category (e.g. Action)", Icons.category)), 
          const SizedBox(height: 12),
          TextField(controller: _subCategoryController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Sub Category (e.g. Romance, Thriller)", Icons.sell)), 
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            dropdownColor: cardDark, 
            value: _selectedDub, 
            style: const TextStyle(color: Colors.white), 
            decoration: _inputDeco("Dub Status", Icons.mic), 
            items: ['DUB', 'ORIGINAL', 'MIX O/D'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), 
            onChanged: (v) => setState(() => _selectedDub = v!)
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity, 
            height: 52, 
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload, color: Colors.white), 
              label: const Text("Upload Anime Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), 
              onPressed: _isLoading ? null : _addAnime
            )
          ), 
          const SizedBox(height: 36), 
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Uploaded Animes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: adminPurple.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text("${_animeList.length} Total", style: const TextStyle(color: adminPurple, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),
          
          if (_isLoading) 
            const Center(child: CircularProgressIndicator(color: adminPurple)) 
          else 
            ListView.builder(
              shrinkWrap: true, 
              physics: const NeverScrollableScrollPhysics(), 
              itemCount: _animeList.length, 
              itemBuilder: (context, index) { 
                final a = _animeList[index]; 
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(a['image_url'], width: 50, height: 70, fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container(width: 50, color: bgDark, child: const Icon(Icons.error, color: Colors.white54))),
                    ),
                    title: Text(a['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), 
                    subtitle: Padding(
                      padding: const EdgeInsets.topOnly(top: 8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: adminPurple.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: Text(a['dub_status'], style: const TextStyle(color: adminPurple, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.15), shape: BoxShape.circle),
                          child: IconButton(icon: const Icon(Icons.edit, color: Color(0xFF3B82F6), size: 18), onPressed: () => _editAnime(a), constraints: const BoxConstraints()),
                        ),
                        Container(
                          decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.15), shape: BoxShape.circle),
                          child: IconButton(icon: const Icon(Icons.delete, color: Color(0xFFEF4444), size: 18), onPressed: () => _deleteAnime(a['id']), constraints: const BoxConstraints()),
                        )
                      ]
                    )
                  )
                ); 
              }
            )
        ]
      )
    ); 
  }
  
  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: adminPurple, size: 20),
      hintText: hint, 
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14), 
      filled: true, 
      fillColor: cardDark, 
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple, width: 1))
    );
  }
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
        if(data.isNotEmpty) { 
          _selectedAnimeId = data[0]['id'].toString(); 
          _fetchEpisodesForAnime(_selectedAnimeId!); 
        } 
      });
    } catch (e) {
    } finally { 
      setState(() => _isLoading = false); 
    }
  }

  Future<void> _fetchEpisodesForAnime(String animeId) async {
    try {
      final data = await Supabase.instance.client.from('anime_seasons').select('id, season_name, anime_episodes(id, episode_title, video_url, image_url, duration)').eq('anime_id', animeId);
      List<dynamic> allEps = [];
      for (var season in data) { 
        for (var ep in season['anime_episodes']) { 
          ep['season_name'] = season['season_name']; 
          allEps.add(ep); 
        } 
      }
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
        final newSeason = await Supabase.instance.client.from('anime_seasons').insert({
          'anime_id': _selectedAnimeId, 
          'season_name': _seasonController.text.trim()
        }).select('id').single();
        seasonId = newSeason['id'].toString();
      } else {
        seasonId = seasonRes['id'].toString();
      }
      
      await Supabase.instance.client.from('anime_episodes').insert({
        'season_id': seasonId, 
        'episode_title': _episodeTitleController.text.isEmpty ? "Episode" : _episodeTitleController.text, 
        'image_url': _imageUrlController.text, 
        'duration': _durationController.text.isEmpty ? "24m" : _durationController.text, 
        'video_url': _videoUrlController.text
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Episode Uploaded"), backgroundColor: Colors.green));
      _episodeTitleController.clear(); 
      _imageUrlController.clear(); 
      _durationController.clear(); 
      _videoUrlController.clear();
      _fetchEpisodesForAnime(_selectedAnimeId!);
    } catch (e) {
    } finally { 
      setState(() => _isLoading = false); 
    }
  }

  Future<void> _deleteEpisode(dynamic id) async {
    await Supabase.instance.client.from('anime_episodes').delete().eq('id', id.toString());
    if(_selectedAnimeId != null) _fetchEpisodesForAnime(_selectedAnimeId!);
  }

  Future<void> _editEpisodeDialog(Map<String, dynamic> ep) async {
    TextEditingController titleCtrl = TextEditingController(text: ep['episode_title']);
    TextEditingController urlCtrl = TextEditingController(text: ep['video_url']);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Episode", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Episode Title", Icons.title)),
            const SizedBox(height: 12),
            TextField(controller: urlCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Video URL", Icons.link)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.from('anime_episodes').update({
                'episode_title': titleCtrl.text,
                'video_url': urlCtrl.text
              }).eq('id', ep['id'].toString());
              if(mounted) Navigator.pop(context);
              if(_selectedAnimeId != null) _fetchEpisodesForAnime(_selectedAnimeId!);
            },
            child: const Text("Update")
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _animeList.isEmpty) return const Center(child: CircularProgressIndicator(color: adminPurple));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: adminPurple.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.cloud_upload, color: adminPurple),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Upload New Episode", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Add a new episode to your anime", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            dropdownColor: cardDark, 
            value: _selectedAnimeId, 
            style: const TextStyle(color: Colors.white), 
            decoration: _inputDeco("Select Anime", Icons.movie), 
            items: _animeList.map((a) => DropdownMenuItem<String>(value: a['id'].toString(), child: Text(a['title'].toString()))).toList(), 
            onChanged: (v) { 
              setState(() => _selectedAnimeId = v); 
              if(v != null) _fetchEpisodesForAnime(v); 
            }
          ), 
          const SizedBox(height: 12),
          TextField(controller: _seasonController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Season Name (e.g. S1)", Icons.calendar_today)), 
          const SizedBox(height: 12),
          TextField(controller: _episodeTitleController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Episode Title", Icons.title)), 
          const SizedBox(height: 12),
          TextField(controller: _imageUrlController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Thumbnail URL (Optional)", Icons.image)), 
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _durationController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Duration", Icons.access_time))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: TextField(controller: _videoUrlController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Video URL", Icons.link))),
            ],
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity, 
            height: 52, 
            child: ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload, color: Colors.white), 
              label: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Upload Episode", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), 
              onPressed: _isLoading ? null : _uploadEpisode
            )
          ), 
          const SizedBox(height: 36), 
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Episodes for Selected Anime", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: adminPurple.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text("${_episodeList.length} Episodes", style: const TextStyle(color: adminPurple, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),
          
          ListView.builder(
            shrinkWrap: true, 
            physics: const NeverScrollableScrollPhysics(), 
            itemCount: _episodeList.length, 
            itemBuilder: (context, index) {
              final ep = _episodeList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (ep['image_url'] != null && ep['image_url'].isNotEmpty)
                      ? Image.network(ep['image_url'], width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container(width: 60, color: bgDark, child: const Icon(Icons.movie, color: Colors.white54)))
                      : Container(width: 60, height: 60, decoration: BoxDecoration(color: bgDark, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.play_circle_fill, color: adminPurple)),
                  ),
                  title: Text(ep['episode_title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${ep['season_name']}", style: const TextStyle(color: adminPurple, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.link, size: 12, color: Colors.white54),
                            const SizedBox(width: 4),
                            Expanded(child: Text("${ep['video_url']}", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 11))),
                          ],
                        )
                      ],
                    ),
                  ), 
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.15), shape: BoxShape.circle),
                        child: IconButton(icon: const Icon(Icons.edit, color: Color(0xFF3B82F6), size: 18), onPressed: () => _editEpisodeDialog(ep), constraints: const BoxConstraints()),
                      ),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.15), shape: BoxShape.circle),
                        child: IconButton(icon: const Icon(Icons.delete, color: Color(0xFFEF4444), size: 18), onPressed: () => _deleteEpisode(ep['id']), constraints: const BoxConstraints()),
                      )
                    ],
                  )
                )
              );
            }
          )
        ]
      )
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: adminPurple, size: 20),
      hintText: hint, 
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14), 
      filled: true, 
      fillColor: cardDark, 
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple, width: 1))
    );
  }
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
  
  final Map<String, String> _colorOptions = {
    "Purple": "FF8A2BE2", 
    "Red": "FFFF4D4D", 
    "Blue": "FF4DA6FF", 
    "Green": "FF00C853", 
    "Orange": "FFFF9F43", 
    "Pink": "FFFF4081"
  };

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
    } catch (e) {}
  }

  Future<void> _addHero() async {
    try {
      await Supabase.instance.client.from('hero_slider').insert({
        'title': _titleController.text, 
        'image_url': _imageController.text, 
        'anime_id': _isCustom ? null : _selectedAnimeId, 
        'is_custom': _isCustom, 
        'tag': _tagController.text.isEmpty ? "NEW" : _tagController.text, 
        'tag_color': _selectedColor
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hero Added!"), backgroundColor: Colors.green));
      _titleController.clear(); 
      _imageController.clear(); 
      _tagController.clear(); 
      _fetchData();
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
          const Text("Add Hero Banner", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), 
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              title: const Text("Custom Banner (Not linked to Anime)", style: TextStyle(color: Colors.white)), 
              activeColor: adminPurple, 
              value: _isCustom, 
              onChanged: (val) => setState(() => _isCustom = val)
            ),
          ),
          const SizedBox(height: 16),
          if (!_isCustom) ...[
            DropdownButtonFormField<String>(
              dropdownColor: cardDark, 
              value: _selectedAnimeId, 
              hint: const Text("Link to Existing Anime", style: TextStyle(color: Colors.white54)), 
              style: const TextStyle(color: Colors.white), 
              decoration: _inputDeco("Select Anime"), 
              items: _animeList.map((a) => DropdownMenuItem<String>(value: a['id'].toString(), child: Text(a['title'].toString()))).toList(), 
              onChanged: (v) => setState(() => _selectedAnimeId = v)
            ),
            const SizedBox(height: 12),
          ],
          TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Banner Name")), 
          const SizedBox(height: 12),
          TextField(controller: _imageController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Banner Image URL (Landscape)")), 
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(controller: _tagController, style: const TextStyle(color: Colors.white), decoration: _inputDeco("Tag (Trending, etc)"))
              ), 
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  dropdownColor: cardDark, 
                  value: _selectedColor, 
                  decoration: _inputDeco("Tag Color"), 
                  items: _colorOptions.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key, style: TextStyle(color: Color(int.parse(e.value, radix: 16)))))).toList(), 
                  onChanged: (v) => setState(() => _selectedColor = v!)
                )
              )
            ]
          ), 
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, 
            height: 50, 
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_photo_alternate, color: Colors.white), 
              label: const Text("Add to Hero Slider", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
              onPressed: _addHero
            )
          ),
          const SizedBox(height: 36), 
          const Text("Current Hero Banners", style: TextStyle(color: adminPurple, fontSize: 16, fontWeight: FontWeight.bold)), 
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true, 
            physics: const NeverScrollableScrollPhysics(), 
            itemCount: _heroItems.length, 
            itemBuilder: (context, index) {
              final item = _heroItems[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(item['image_url'], width: 80, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container(width: 80, color: bgDark, child: const Icon(Icons.error, color: Colors.white54))),
                  ),
                  title: Text(item['title'] ?? "No Title", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
                  subtitle: Text("Tag: ${item['tag']} | ${item['is_custom'] ? "Custom" : "Linked"}", style: const TextStyle(color: Colors.white54, fontSize: 12)), 
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteHero(item['id']))
                )
              );
            }
          )
        ]
      )
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint, 
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14), 
      filled: true, 
      fillColor: cardDark, 
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple, width: 1))
    );
  }
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
    } finally { 
      setState(() => _isLoading = false); 
    }
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
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16), 
                decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFF3B82F6)), 
                    SizedBox(width: 12), 
                    Expanded(
                      child: Text("Passwords are encrypted. Click 'Send Link' to send a password reset email.", style: TextStyle(color: Color(0xFF3B82F6), fontSize: 13))
                    )
                  ]
                )
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16), 
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    String email = _users[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12), 
                      decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: adminPurple.withOpacity(0.2), shape: BoxShape.circle),
                                  child: const Icon(Icons.person, color: adminPurple)
                                ), 
                                const SizedBox(width: 12), 
                                Expanded(child: Text(email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)))
                              ]
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Pass: [ Encrypted Hash ]", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic, fontSize: 12)),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: adminPurple, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)), 
                                  icon: const Icon(Icons.link, color: Colors.white, size: 16), 
                                  label: const Text("Send Link", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)), 
                                  onPressed: () => _sendResetLink(email)
                                )
                              ]
                            )
                          ]
                        )
                      )
                    );
                  }
                )
              )
            ]
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
  void initState() { 
    super.initState(); 
    _fetchSettings(); 
  }

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Links Updated Successfully!"), backgroundColor: Colors.green));
    } catch(e) {
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
          const Text("App Visuals & Links", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), 
          const SizedBox(height: 8),
          const Text("Change user panel logo and website URL from here.", style: TextStyle(color: Colors.white54, fontSize: 13)), 
          const SizedBox(height: 24),
          
          _buildTextField("Website URL", "https://yourwebsite.com", _urlController, Icons.language, adminPurple),
          const SizedBox(height: 16),
          _buildTextField("App Logo URL (PNG/WEBP)", "https://image-link.png", _logoController, Icons.image, adminPurple),
          const SizedBox(height: 32),

          const Text("Payment Settings", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), 
          const SizedBox(height: 16),
          
          _buildTextField("Payment QR Code URL", "QR Code Image Link", _qrUrlController, Icons.qr_code, Colors.amber),
          const SizedBox(height: 16),
          _buildTextField("UPI ID", "yourname@oksbi", _upiIdController, Icons.account_balance_wallet, Colors.amber),
          const SizedBox(height: 32),

          const Text("Social Media Integration", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), 
          const SizedBox(height: 16),
          
          _buildTextField("Telegram Link", "https://t.me/yourgroup", _telegramController, Icons.telegram, Colors.blueAccent),
          const SizedBox(height: 16),
          _buildTextField("YouTube Link", "https://youtube.com/@channel", _youtubeController, Icons.play_circle_filled, Colors.redAccent),
          const SizedBox(height: 16),
          _buildTextField("WhatsApp Link", "https://wa.me/number", _whatsappController, Icons.chat, Colors.greenAccent),
          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity, 
            height: 52, 
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save, color: Colors.white), 
              label: const Text("Save All Links", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), 
              onPressed: _saveSettings
            )
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController ctrl, IconData icon, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 13)), 
        const SizedBox(height: 8),
        TextField(
          controller: ctrl, 
          style: const TextStyle(color: Colors.white), 
          decoration: InputDecoration(
            hintText: hint, 
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: Icon(icon, color: iconColor), 
            filled: true, 
            fillColor: cardDark, 
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: iconColor, width: 1))
          )
        ),
      ],
    );
  }
}

// ==========================================
// 8. MANAGE APP PAGES (PRIVACY & GUIDE)
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
    } catch(e) { 
    } finally {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pages Updated Successfully!"), backgroundColor: Colors.green));
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
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
          const Text("Manage User App Content", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), 
          const SizedBox(height: 8),
          const Text("Changes made here will instantly reflect in the User App.", style: TextStyle(color: Colors.white54, fontSize: 13)), 
          const SizedBox(height: 24),

          const Text("Privacy Policy Content", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold)), 
          const SizedBox(height: 8),
          TextField(
            controller: _privacyPolicyController, 
            maxLines: 8, 
            style: const TextStyle(color: Colors.white, height: 1.4),
            decoration: InputDecoration(
              hintText: "Enter complete Privacy Policy here...", 
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true, 
              fillColor: cardDark, 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple, width: 1))
            )
          ),
          const SizedBox(height: 24),

          const Text("App Guide / How to Use", style: TextStyle(color: adminPurple, fontWeight: FontWeight.bold)), 
          const SizedBox(height: 8),
          TextField(
            controller: _appGuideController, 
            maxLines: 8, 
            style: const TextStyle(color: Colors.white, height: 1.4),
            decoration: InputDecoration(
              hintText: "Enter full App Guide instructions here...", 
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true, 
              fillColor: cardDark, 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminPurple, width: 1))
            )
          ),
          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity, 
            height: 52, 
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sync, color: Colors.white), 
              label: const Text("Save & Sync to Users", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), 
              onPressed: _savePages
            )
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 9. APP SOURCE CODE (OTA) UPDATE MANAGER
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alert: Version should be greater than 1.0.0"), backgroundColor: Colors.orange));
      return;
    }

    try {
      await Supabase.instance.client.from('app_updates').insert({
        'version': _versionController.text.trim(), 
        'apk_url': _apkUrlController.text.trim(), 
        'whats_new': _whatsNewController.text.trim()
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("App Update Alert Pushed Successfully!"), backgroundColor: Colors.green));
      _versionController.clear();
      _apkUrlController.clear();
      _whatsNewController.clear();
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
          const Text("Push App Update", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), 
          const SizedBox(height: 8),
          const Text("Notify users about the latest app version.", style: TextStyle(color: Colors.white54, fontSize: 13)), 
          const SizedBox(height: 24),
          
          TextField(
            controller: _versionController, 
            style: const TextStyle(color: Colors.white), 
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.numbers, color: adminPurple),
              hintText: "New Version Number (e.g. 1.0.1)", 
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14), 
              filled: true, 
              fillColor: cardDark, 
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
            )
          ), 
          const SizedBox(height: 16),
          
          TextField(
            controller: _apkUrlController, 
            style: const TextStyle(color: Colors.white), 
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.link, color: adminPurple),
              hintText: "Website or APK Download Link", 
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14), 
              filled: true, 
              fillColor: cardDark, 
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
            )
          ), 
          const SizedBox(height: 16),
          
          TextField(
            controller: _whatsNewController, 
            maxLines: 5, 
            style: const TextStyle(color: Colors.white), 
            decoration: InputDecoration(
              hintText: "What's New / Release Notes...", 
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14), 
              filled: true, 
              fillColor: cardDark, 
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
            )
          ), 
          const SizedBox(height: 36),
          
          SizedBox(
            height: 52, 
            width: double.infinity, 
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send, color: Colors.white), 
              label: const Text("Push Update to Users", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)), 
              onPressed: _pushUpdate
            )
          ),
        ],
      ),
    );
  }
}