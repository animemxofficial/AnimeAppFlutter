import 'package:flutter/material.dart';

void main() => runApp(const AnimeMX());

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepPurpleAccent,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final List<Widget> _pages = [
    const HomeScreen(),
    const Center(child: Text("Search Page")),
    const Center(child: Text("Categories Page")),
    const Center(child: Text("Favorites Page")),
    const Center(child: Text("Account Page")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: "Home"),
          NavigationDestination(icon: Icon(Icons.search), label: "Search"),
          NavigationDestination(icon: Icon(Icons.folder_open), label: "Categories"),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: "Favorites"),
          NavigationDestination(icon: Icon(Icons.person_outline), label: "Account"),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AnimeMX", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
        backgroundColor: Colors.black,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Featured Banner
          Container(
            height: 200,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.grey[900]),
            child: const Center(child: Text("Featured Banner")),
          ),
          const SizedBox(height: 24),
          // Section Title
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Trending Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () {}, child: const Text("See All")),
          ]),
          // Horizontal Cards
          SizedBox(height: 180, child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (ctx, i) => Container(
              width: 120, margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey[850]),
              child: const Center(child: Text("Poster")),
            ),
          )),
        ],
      ),
    );
  }
}