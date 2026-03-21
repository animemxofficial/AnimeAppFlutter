import 'package:flutter/material.dart';

void main() => runApp(const AnimeMX());

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(selectedItemColor: Colors.purple),
      ),
      home: const MainScreen(),
    );
  }
}

// 5 Tabs wala Structure
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final List<Widget> _pages = [
    const HomeScreen(), 
    const Center(child: Text("Dubbed Page")), 
    const Center(child: Text("Favourite Page")), 
    const Center(child: Text("Account Page")),
    const Center(child: Text("More")), // 5th Tab
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.headset), label: "Dubbed"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favourite"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }
}

// Home Screen with "Top Picks" Layout
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AnimeMX", style: TextStyle(color: Colors.purple)), backgroundColor: Colors.white, elevation: 0),
      body: ListView(
        children: [
          // 1. Top Picks Box (Tera design)
          Container(
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Top Picks for You", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("New episodes available now!", style: TextStyle(color: Colors.white70)),
                ]),
                ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white), child: const Text("Watch Now", style: TextStyle(color: Colors.black))),
              ],
            ),
          ),

          // 2. Trending Section
          const Padding(padding: EdgeInsets.all(15), child: Text("Trending Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          _buildHorizontalList(),
        ],
      ),
    );
  }

  Widget _buildHorizontalList() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (ctx, i) => Container(
          width: 110, margin: const EdgeInsets.only(left: 15),
          child: Column(children: [
            Container(height: 130, decoration: BoxDecoration(color: Colors.purple[100], borderRadius: BorderRadius.circular(10))),
            const Text("Anime Name", style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}