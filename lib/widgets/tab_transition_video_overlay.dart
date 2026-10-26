import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../app_config_repository.dart';

class TabTransitionVideoOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onTransitionComplete;

  const TabTransitionVideoOverlay({
    super.key,
    required this.isVisible,
    this.onTransitionComplete,
  });

  @override
  State<TabTransitionVideoOverlay> createState() => _TabTransitionVideoOverlayState();
}

class _TabTransitionVideoOverlayState extends State<TabTransitionVideoOverlay> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  StreamSubscription? _configSub;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isInitialized = false;
  String _currentUrl = '';

  Map<String, dynamic> _config = {
    'enabled': true,
    'duration_ms': 1200,
    'video_url': 'assets/images/ambhujakshi_loading_screen.mp4',
    'caption': 'Swapping Heritage Kitchens...',
    'show_spinner': true,
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _listenToConfig();

    if (widget.isVisible) {
      _fadeController.forward();
    }
  }

  @override
  void didUpdateWidget(TabTransitionVideoOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _fadeController.forward();
      _playVideoAndScheduleFade();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _fadeController.reverse();
    }
  }

  void _listenToConfig() {
    _configSub = AppConfigRepository().getTabTransitionConfigStream().listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        setState(() => _config = data);
        final url = data['video_url']?.toString() ?? 'assets/images/ambhujakshi_loading_screen.mp4';
        if (url != _currentUrl) {
          _initializeVideo(url);
        }
      }
    });
  }

  Future<void> _initializeVideo(String url) async {
    _currentUrl = url;
    await _controller?.dispose();
    _controller = null;

    if (url.toLowerCase().contains('.gif')) {
      if (mounted) setState(() => _isInitialized = true);
      return;
    }

    try {
      if (url.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        String assetPath = url.startsWith('assets/') ? url : 'assets/images/$url';
        _controller = VideoPlayerController.asset(assetPath);
      }

      await _controller!.initialize();
      if (!mounted) return;

      _controller!.setLooping(true);
      _controller!.setVolume(0.0); // Muted transition video
      _controller!.play();

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint("Tab transition video init error: $e");
      if (mounted) {
        setState(() => _isInitialized = false);
      }
    }
  }

  void _playVideoAndScheduleFade() {
    if (_controller != null && _isInitialized) {
      _controller!.play();
    }
    final durationMs = (_config['duration_ms'] is num) ? (_config['duration_ms'] as num).toInt() : 1200;
    
    Future.delayed(Duration(milliseconds: durationMs), () {
      if (mounted && widget.isVisible) {
        widget.onTransitionComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _configSub?.cancel();
    _controller?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _config['enabled'] != false;
    if (!enabled && !widget.isVisible) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: !widget.isVisible,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: const Color(0xFFF6F6F6), // Prevent any white flashing before video/GIF loads
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Full-screen GIF Support (Network or Asset)
              if (_currentUrl.toLowerCase().contains('.gif'))
                _currentUrl.startsWith('http')
                  ? Image.network(
                      _currentUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/ambhujakshi_loading_fullscreen.gif',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : Image.asset(
                      _currentUrl.startsWith('assets/') ? _currentUrl : 'assets/images/$_currentUrl',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/ambhujakshi_loading_fullscreen.gif',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
              // 2. Video Player with BoxFit.cover fill screen (1080 x 2340 aspect)
              else if (_isInitialized && _controller != null)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width > 0 ? _controller!.value.size.width : 1080,
                      height: _controller!.value.size.height > 0 ? _controller!.value.size.height : 2340,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                )
              else
                // 3. Full-screen GIF Fallback
                Image.asset(
                  'assets/images/ambhujakshi_loading_fullscreen.gif',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF18453B),
                      strokeWidth: 3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
