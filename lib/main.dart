import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- STEP 1: Yeh zaroori hai!

void main() {
  // <--- STEP 2: System UI Settings
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white, 
    systemNavigationBarIconBrightness: Brightness.dark, 
    statusBarColor: Colors.white, 
    statusBarIconBrightness: Brightness.dark,
  ));
  
  runApp(const AnimeMX());
}

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.purple, scaffoldBackgroundColor: Colors.white),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AnimeMX", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0),
      body: ListView(
        children: [
          _buildHorizontalList("Top Picks For You"),
          _buildHorizontalList("Trending Now"),
          _buildHorizontalList("Most Viewed"),
        ],
      ),
    );
  }

  // <--- STEP 3: Horizontal Scroll Wala Code
  Widget _buildHorizontalList(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.all(15), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black))),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal, // YAHI HAI HORIZONTAL SCROLL!
            itemCount: 5,
            itemBuilder: (ctx, i) => Container(
              width: 110,
              margin: const EdgeInsets.only(left: 15),
              child: Column(
                children: [
                  Container(
                    height: 130,
                    decoration: BoxDecoration(color: Colors.purple[100], borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.movie, color: Colors.purple),
                  ),
                  const Text("Anime Name", style: TextStyle(color: Colors.black, fontSize: 12), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}