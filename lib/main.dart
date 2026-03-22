import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Ab hum separate files banayenge

void main() => runApp(const AnimeMX());

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
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
    const Center(child: Text("Categories")),
    const Center(child: Text("Favorites")),
    const Center(child: Text("Account")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.search), label: "Search"),
          NavigationDestination(icon: Icon(Icons.category_outlined), label: "Categories"),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: "Favorites"),
          NavigationDestination(icon: Icon(Icons.person_outline), label: "Account"),
        ],
      ),
    );
  }
}