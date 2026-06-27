import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ExerciseVideoPlayer extends StatefulWidget {
  final String? videoPath;
  final String? gifUrl; // Fallback to GIF if video not available
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool autoPlay; // Only auto-play in detail views, not in lists
  final bool showThumbnailOnly; // Show thumbnail only (for list views)

  const ExerciseVideoPlayer({
    Key? key,
    this.videoPath,
    this.gifUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.autoPlay = false, // Default to false to save memory
    this.showThumbnailOnly = false, // Default to false
  }) : super(key: key);

  @override
  State<ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Initialize video if we have a video path
    // If autoPlay is false, we'll just show the first frame as thumbnail
    if (widget.videoPath != null && widget.videoPath!.isNotEmpty) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.videoPath == null || widget.videoPath!.isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    try {
      _controller = VideoPlayerController.asset(
        widget.videoPath!,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true, // Allow mixing with other audio
          allowBackgroundPlayback: false, // Don't play in background
        ),
      );
      
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
        // Auto-play the video in a loop only if autoPlay is true
        if (widget.autoPlay) {
          _controller!.setLooping(true);
          _controller!.play();
        } else {
          // Just seek to first frame for thumbnail (don't play)
          await _controller!.seekTo(Duration.zero);
          _controller!.pause();
        }
      }
    } catch (e) {
      print('Error initializing video: $e');
      print('Video path attempted: ${widget.videoPath}');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while initializing
    if (!_isInitialized && !_hasError && widget.videoPath != null && widget.videoPath!.isNotEmpty) {
      return _buildLoadingPlaceholder();
    }

    // If video is available and initialized, show video player
    if (_isInitialized && _controller != null && !_hasError) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: FittedBox(
            fit: widget.fit,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
      );
    }

    // Fallback to GIF or placeholder
    if (widget.gifUrl != null && !_hasError) {
      return Image.network(
        widget.gifUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder();
        },
      );
    }

    // Show placeholder if no video or GIF
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.fitness_center,
        color: Colors.grey[600],
        size: 40,
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: ColorManager.textPrimary,
        ),
      ),
    );
  }
}

