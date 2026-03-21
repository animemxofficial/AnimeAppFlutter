import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const AnimeMX());

class Anime {
  final String title;
  final String image;
  final String videoUrl;
  final String description;
  Anime({required this.title, required this.image, required this.videoUrl, required this.description});
}

// Tera Anime Data
List<Anime> trendingList = [
  Anime(
    title: "Classroom of the Elite",
    image: "https://iili.io/qeQX3Ml.jpg",
    videoUrl: "https://archive.org/download/videoplayback_20260126_1040/videoplayback.mp4",
    description: "Kiyotaka Ayanokouji enters a prestigious school where only the superior students are treated well. He must survive in Class-D.",
  ),
];

class AnimeMX extends StatelessWidget {
  const AnimeMX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.purple, // Purple Theme
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
  final List<Widget> _pages = [const HomeScreen(), const Center(child: Text("Dubbed")), const Center(child: Text("Favourite")), const Center(child: Text("Account"))];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.grey,
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AnimeMX", style: TextStyle(color: Colors.purpleAccent))),
      body: ListView.builder(
        itemCount: trendingList.length,
        itemBuilder: (ctx, i) => ListTile(
          leading: Image.network(trendingList[i].image, width: 60, fit: BoxFit.cover),
          title: Text(trendingList[i].title),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: trendingList[i]))),
        ),
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  final Anime anime;
  const DetailsPage({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(anime.title)),
      body: Column(
        children: [
          Image.network(anime.image, height: 250, width: double.infinity, fit: BoxFit.cover),
          Padding(padding: const EdgeInsets.all(16), child: Text(anime.description)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(url: anime.videoUrl))),
            child: const Text("Watch Now"),
          ),
        ],
      ),
    );
  }
}

// Video Player Page
class VideoPlayerPage extends StatefulWidget {
  final String url;
  const VideoPlayerPage({super.key, required this.url});
  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))..initialize().then((_) => setState(() {}));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller.value.isInitialized ? VideoPlayer(_controller) : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()), child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow)),
    );
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}