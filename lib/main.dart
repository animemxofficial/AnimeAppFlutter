import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// ==========================================
// 🔥 PREMIUM VIDEO PLAYER & DETAILS PAGE 🔥
// ==========================================

class VideoDetailsPage extends StatefulWidget {
  final Anime anime;
  const VideoDetailsPage({super.key, required this.anime});

  @override
  State<VideoDetailsPage> createState() => _VideoDetailsPageState();
}

class _VideoDetailsPageState extends State<VideoDetailsPage> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  int _currentEpisode = 1; // Default episode 2 (Index 1) jaisa screenshot me hai

  @override
  void initState() {
    super.initState();
    // TERA GOOGLE DRIVE LINK (Direct Stream Format)
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.anime.videoUrl),
    )..initialize().then((_) {
        setState(() {});
        _controller.play(); // Auto-play start
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // Screenshot wali theme
    const Color orangeAccent = Color(0xFFF47521);
    const Color darkBg = Color(0xFF0F0F0F);

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            // 1. VIDEO PLAYER SECTION (16:9 Aspect Ratio)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children:[
                  _controller.value.isInitialized
                      ? VideoPlayer(_controller)
                      : const Center(child: CircularProgressIndicator(color: orangeAccent)),
                  
                  // Video Controls Overlay
                  if (_showControls)
                    GestureDetector(
                      onTap: _toggleControls,
                      child: Container(
                        color: Colors.black54,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:[
                            // Top Bar (Back Button)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children:[
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Row(
                                  children:[
                                    IconButton(icon: const Icon(Icons.cast, color: Colors.white), onPressed: () {}),
                                    IconButton(icon: const Icon(Icons.fullscreen, color: Colors.white), onPressed: () {}),
                                  ],
                                )
                              ],
                            ),
                            // Center Play/Pause & Skip Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children:[
                                IconButton(
                                  icon: const Icon(Icons.replay_10, color: Colors.white, size: 40),
                                  onPressed: () {
                                    _controller.seekTo(_controller.value.position - const Duration(seconds: 10));
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _controller.value.isPlaying ? _controller.pause() : _controller.play();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.forward_10, color: Colors.white, size: 40),
                                  onPressed: () {
                                    _controller.seekTo(_controller.value.position + const Duration(seconds: 10));
                                  },
                                ),
                              ],
                            ),
                            // Bottom Progress Bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                children:[
                                  Text(
                                    _formatDuration(_controller.value.position),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  Expanded(
                                    child: VideoProgressIndicator(
                                      _controller,
                                      allowScrubbing: true,
                                      colors: const VideoProgressColors(
                                        playedColor: orangeAccent,
                                        bufferedColor: Colors.white24,
                                        backgroundColor: Colors.white12,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_controller.value.duration),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _toggleControls,
                      child: Container(color: Colors.transparent),
                    ),
                ],
              ),
            ),

            // 2. ANIME INFO SECTION
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    // Title
                    Text(
                      "E${_currentEpisode + 1} | ${widget.anime.title}",
                      style: const TextStyle(color: orangeAccent, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    
                    // Tags
                    Row(
                      children:[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                          child: const Text("U/A 16+", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "• Dub | Thriller, Mystery, Drama",
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Episodes Header & Season Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:[
                        const Text("Episodes", style: TextStyle(color: orangeAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            children:[
                              Text("Season 1", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              SizedBox(width: 5),
                              Icon(Icons.keyboard_arrow_down, color: orangeAccent, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. EPISODE LIST
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        bool isActive = index == _currentEpisode;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentEpisode = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isActive ? orangeAccent : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children:[
                                // Episode Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    widget.anime.image,
                                    width: 120,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Episode Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children:[
                                      Text(
                                        "Episode ${index + 1}",
                                        style: TextStyle(
                                          color: isActive ? Colors.white : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "24 min",
                                        style: TextStyle(
                                          color: isActive ? Colors.white70 : Colors.white54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Play/Pause Icon
                                Icon(
                                  isActive ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}