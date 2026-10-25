import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../app_config_repository.dart';

class FeaturedVideoShowcase extends StatefulWidget {
  const FeaturedVideoShowcase({super.key});

  @override
  State<FeaturedVideoShowcase> createState() => _FeaturedVideoShowcaseState();
}

class _FeaturedVideoShowcaseState extends State<FeaturedVideoShowcase> {
  VideoPlayerController? _videoController;
  StreamSubscription? _configSub;

  bool _isInitialized = false;
  bool _isMuted = true;
  bool _isPlaying = true;
  String _currentVideoUrl = '';

  Map<String, dynamic> _config = {
    'enabled': true,
    'tag': 'HERITAGE IN MOTION',
    'title': 'Behind the Craft: Our Sun-Dried Tradition',
    'subtitle': 'Watch how our 40-year-old authentic recipes come to life.',
    'video_url': 'assets/images/ambhujakshi-all.mp4',
  };

  @override
  void initState() {
    super.initState();
    _listenToVideoConfig();
  }

  void _listenToVideoConfig() {
    _configSub = AppConfigRepository().getFeaturedVideoConfigStream().listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        setState(() => _config = data);
        final url = data['video_url']?.toString() ?? 'assets/images/ambhujakshi-all.mp4';
        if (url != _currentVideoUrl) {
          _initializeVideo(url);
        }
      }
    });
  }

  Future<void> _initializeVideo(String url) async {
    _currentVideoUrl = url;
    await _videoController?.dispose();

    try {
      if (url.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        String assetPath = url.startsWith('assets/') ? url : 'assets/images/$url';
        _videoController = VideoPlayerController.asset(assetPath);
      }

      await _videoController!.initialize();
      if (!mounted) return;

      _videoController!.setLooping(true);
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      _videoController!.play();

      setState(() {
        _isInitialized = true;
        _isPlaying = true;
      });
    } catch (e) {
      debugPrint("Featured video initialization error: $e");
      if (mounted) {
        setState(() => _isInitialized = false);
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController == null || !_isInitialized) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleMute() {
    if (_videoController == null || !_isInitialized) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  void dispose() {
    _configSub?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _config['enabled'] != false;
    if (!enabled) return const SizedBox.shrink();

    final tag = _config['tag']?.toString() ?? 'HERITAGE IN MOTION';
    final title = _config['title']?.toString() ?? 'Behind the Craft: Our Sun-Dried Tradition';
    final subtitle = _config['subtitle']?.toString() ?? 'Watch how our 40-year-old authentic recipes come to life.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF18453B),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),

          // Main Video Player Card
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video Content
                    if (_isInitialized && _videoController != null)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width > 0 ? _videoController!.value.size.width : 1600,
                          height: _videoController!.value.size.height > 0 ? _videoController!.value.size.height : 900,
                          child: VideoPlayer(_videoController!),
                        ),
                      )
                    else
                      Container(
                        color: const Color(0xFF18453B),
                        child: const Center(
                          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                        ),
                      ),

                    // Dark Gradient Overlay for Readability
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.black.withOpacity(0.75),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Play/Pause Center Indicator (When paused)
                    if (!_isPlaying)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white38, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),

                    // Bottom Overlay (Title, Subtitle & Mute Button)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.philosopher(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                    shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Mute / Unmute Button
                          GestureDetector(
                            onTap: _toggleMute,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white30, width: 1),
                              ),
                              child: Icon(
                                _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
