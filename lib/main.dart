// main.dart file for Admin Panel App

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

// --- Global Variables (for Admin Settings) ---
// Note: These should ideally be read from Firestore in production app
bool hasPremiumPlan = true;
String planExpireDate = "Expire: 24 Dec 2024"; 
String userActivePlan = ""; 
List<String> globalRecentSearches = [];
List<String> adminEmails = ["animemx.admin@gmail.com", "your.second.admin@gmail.com"]; // Admin's email list

// --- Dummy Data Models (for demo purposes) ---
class OrderItem {
  final String planName;
  final String amount;
  final String status;
  final String date;
  OrderItem({required this.planName, required this.amount, required this.status, required this.date});
}
List<OrderItem> userOrders =[];

// --- Main App Entry Point ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase (This assumes manual configuration aage hogi)
  // await Firebase.initializeApp(); // Uncomment this line after Firebase connection steps

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
  runApp(const AnimeMXAdmin());
}

class AnimeMXAdmin extends StatelessWidget {
  const AnimeMXAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnimeMX Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: Colors.orange,
        useMaterial3: true,
      ),
      home: const AdminLoginScreen(), // Start with login screen
    );
  }
}

// ==========================================
// ADMIN LOGIN SCREEN (GOOGLE SIGN-IN)
// ==========================================

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  // Dummy Google Sign-in functionality (for demo without full Firebase setup)
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    // Replace this with real Google Sign-in logic after full Firebase setup
    // For now, simulate a successful login and check if it's an admin email
    
    // Simulating login process:
    await Future.delayed(const Duration(seconds: 1)); 

    String dummyLoggedInEmail = "animemx.admin@gmail.com"; // Change this for testing non-admin login

    // Check if the logged-in user is an admin
    if (adminEmails.contains(dummyLoggedInEmail)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Access Denied: You are not an Admin.")),
      );
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
            const Icon(Icons.security, color: Colors.orange, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Admin Access Required",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Sign in with your authorized Google account to continue.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _handleGoogleSignIn(context),
                icon: Image.network(
                  "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png",
                  height: 24,
                ),
                label: const Text(
                  "Sign in with Google",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ADMIN DASHBOARD & NAVIGATION
// ==========================================

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardOverview(),
    const PlanApprovalsPage(),
    const UploadContentPage(),
    const AppSettingsPage(),
    const NotificationsSuggestionsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR NAVIGATION FOR ADMIN
          Container(
            width: 250,
            color: Colors.black,
            child: Column(
              children: [
                const SizedBox(height: 50),
                const Text(
                  "AnimeMX",
                  style: TextStyle(color: Colors.orange, fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const Text(
                  "ADMIN PANEL",
                  style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2),
                ),
                const SizedBox(height: 40),
                _buildNavItem(Icons.dashboard, "Dashboard", 0),
                _buildNavItem(Icons.verified_user, "Plan Approvals", 1),
                _buildNavItem(Icons.cloud_upload, "Upload Content", 2),
                _buildNavItem(Icons.settings_applications, "App Settings (OTA)", 3),
                _buildNavItem(Icons.notifications_active, "Notify & Feedback", 4),
                const Spacer(),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin Logged Out")));
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminLoginScreen()));
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // MAIN CONTENT AREA
          Expanded(
            child: Container(
              color: const Color(0xFF0F0F0F),
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.orange : Colors.white70),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.orange : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. DASHBOARD OVERVIEW (LIVE STATS)
// ==========================================
class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Live Dashboard", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard("Total Users", "15,240", Icons.people, Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard("Active Now (Online)", "1,043", Icons.wifi_tethering, Colors.green),
              const SizedBox(width: 16),
              _buildStatCard("Daily Active (DAU)", "8,450", Icons.trending_up, Colors.orange),
              const SizedBox(width: 16),
              _buildStatCard("Pending Approvals", "24", Icons.pending_actions, Colors.redAccent),
            ],
          ),
          const SizedBox(height: 30),
          const Text("Currently Watching (Live Activity)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Demo pending requests
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("user${index + 120}@gmail.com", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text("Watching: Solo Leveling - Episode ${index + 3}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: const Text("Online", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border(bottom: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 16),
            Text(count, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. PREMIUM PLAN APPROVALS
// ==========================================
class PlanApprovalsPage extends StatefulWidget {
  const PlanApprovalsPage({super.key});

  @override
  State<PlanApprovalsPage> createState() => _PlanApprovalsPageState();
}

class _PlanApprovalsPageState extends State<PlanApprovalsPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Premium Approvals", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("Verify transaction IDs and approve user plans.", style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: 4, // Demo pending requests
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      // Dummy Screenshot (Replace with actual image from storage URL)
                      Container(
                        width: 80,
                        height: 120,
                        decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.image, color: Colors.white54, size: 30),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Email: user_test@gmail.com", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text("Phone: +91 9876543210", style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text("Plan Applied: ${["Ultra Plan", "Lite Plan", "Pro Plan", "Plus Plan"][index]}", style: const TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text("TXN ID: UTR83920183920", style: TextStyle(color: Colors.greenAccent, fontSize: 13)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plan Approved & Features Unlocked!")));
                              // TODO: Add Firestore logic here to update user plan status
                            },
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text("Approve", style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Rejected!")));
                              // TODO: Add Firestore logic here to update user plan status
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: const Text("Reject", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 3. UPLOAD CONTENT VIA LINKS
// ==========================================
class UploadContentPage extends StatelessWidget {
  const UploadContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Upload Anime (Via Links)", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("Add new anime or episodes directly using URLs.", style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField("Anime Title", "e.g. Naruto Shippuden"),
                    _buildInputField("Cover Image URL", "https://..."),
                    _buildInputField("Category / Genre", "e.g. Action, Romance"),
                    Row(
                      children: [
                        Expanded(child: _buildInputField("Season Name", "e.g. Season 1")),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInputField("Episode Title", "e.g. Episode 12")),
                      ],
                    ),
                    _buildInputField("Video Direct Link (MP4/M3U8)", "https://... video link"),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(value: true, onChanged: (v) {}, activeColor: Colors.orange),
                        const Text("Add to Automatic Home Slider?", style: TextStyle(color: Colors.white)),
                        const SizedBox(width: 20),
                        Checkbox(value: false, onChanged: (v) {}, activeColor: Colors.orange),
                        const Text("Is Premium Only? (Lock this content)", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading to Database... Success!")));
                          // TODO: Add Firestore logic here to save data to database
                        },
                        child: const Text("Publish Anime", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. APP SETTINGS (OTA UPDATE & SUPPORT)
// ==========================================
class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("App Settings & OTA Updates", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("Manage User Panel updates and support details.", style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // UPDATE APK SECTION
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Push App Update", style: TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          const Text("Provide the new APK link. When users open the app, they will be forced to update.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 16),
                          _buildInputField("New Version Code", "e.g. 1.0.5"),
                          _buildInputField("APK Download Link (Drive/Mediafire)", "https://..."),
                          _buildInputField("What's New (Release Notes)", "Added new video player..."),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size.fromHeight(50)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update notification sent to all users!")));
                              // TODO: Add Firestore logic here to update app settings for user app to check
                            },
                            icon: const Icon(Icons.system_update, color: Colors.white),
                            label: const Text("Push Update to Users", style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // SUPPORT SETTINGS
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Support Page Details", style: TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildInputField("Support Email", "animemx.official@gmail.com"),
                          _buildInputField("WhatsApp/Telegram Number", "+91 9876543210"),
                          _buildInputField("Website Link", "https://animemx.com"),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size.fromHeight(50)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Support Details Updated in User Panel!")));
                              // TODO: Add Firestore logic here to update support details
                            },
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text("Save Details", style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. NOTIFICATIONS & SUGGESTIONS
// ==========================================
class NotificationsSuggestionsPage extends StatelessWidget {
  const NotificationsSuggestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SEND NOTIFICATION
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Send Push Notification", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Title", style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 16),
                      const Text("Message", style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      TextField(
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size.fromHeight(50)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification Broadcasted to All Users!")));
                          // TODO: Add Firebase Messaging logic here
                        },
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text("Send to All Users", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // READ SUGGESTIONS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("User Suggestions", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: 3, // Demo suggestions
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("User: animelover${index}@gmail.com", style: const TextStyle(color: Colors.orange, fontSize: 12)),
                            const SizedBox(height: 8),
                            const Text("Please add Jujutsu Kaisen Season 2 dubbed version quickly! Love the app.", style: TextStyle(color: Colors.white, fontSize: 14)),
                            const SizedBox(height: 12),
                            TextField(
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: "Reply to user...",
                                hintStyle: const TextStyle(color: Colors.white24),
                                filled: true,
                                fillColor: Colors.black,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.send, color: Colors.green),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reply sent!")));
                                  },
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}