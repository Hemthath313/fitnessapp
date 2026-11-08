import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef VideoControllerFactory = VideoPlayerController Function(
  String assetPath,
  VideoPlayerOptions options,
);

typedef VideoViewBuilder = Widget Function(VideoPlayerController controller);

class ExerciseVideoPlayer extends StatefulWidget {
  final String? videoPath;
  final String? gifUrl; // Fallback to GIF if video not available
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool autoPlay; // Only auto-play in detail views, not in lists
  final bool showThumbnailOnly; // Show static thumbnail preview only (for list views)
  final ValueChanged<bool>? onErrorChanged;
  final VideoControllerFactory? controllerFactory;
  final VideoViewBuilder? videoViewBuilder;

  const ExerciseVideoPlayer({
    super.key,
    this.videoPath,
    this.gifUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.autoPlay = false, // Default to false to avoid list decoder overhead
    this.showThumbnailOnly = false, // Default to false
    this.onErrorChanged,
    this.controllerFactory,
    this.videoViewBuilder,
  });

  @override
  State<ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _hasError = false;
  String? _initializedPath;
  int _initGeneration = 0;

  bool get _hasValidVideoPath =>
      widget.videoPath != null && widget.videoPath!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasValidVideoPath) {
      _initializeVideo();
    } else {
      _setErrorState(true);
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool pathChanged = oldWidget.videoPath != widget.videoPath;
    final bool modeChanged = (oldWidget.autoPlay != widget.autoPlay) ||
        (oldWidget.showThumbnailOnly != widget.showThumbnailOnly);

    if (!_hasValidVideoPath) {
      if (_controller != null) {
        _disposeCurrentController();
        setState(() {
          _isInitialized = false;
          _isInitializing = false;
          _hasError = false;
        });
      }
      return;
    }

    if (pathChanged) {
      // Video source changed — always reinitialize.
      _disposeCurrentController();
      _initializeVideo();
    } else if (_controller == null && !_hasError && !_isInitializing) {
      // Controller was cleared for an unexpected reason (not an error, not
      // already initializing) — reinitialize to avoid a blank state.
      _initializeVideo();
    } else if (modeChanged && _isInitialized && _controller != null) {
      if (widget.autoPlay && !widget.showThumbnailOnly) {
        _controller!.setLooping(true);
        _controller!.play();
      } else {
        _controller!.pause();
        _controller!.seekTo(Duration.zero);
      }
    }
  }

  void _setErrorState(bool hasError) {
    final changed = _hasError != hasError;
    _hasError = hasError;
    if (changed && widget.onErrorChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onErrorChanged!(_hasError);
        }
      });
    }
  }

  void _disposeCurrentController() {
    _initGeneration++;
    final oldController = _controller;
    _controller = null;
    _initializedPath = null;
    _isInitializing = false;
    if (oldController != null) {
      oldController.pause();
      oldController.dispose();
    }
  }

  Future<void> _initializeVideo() async {
    final path = widget.videoPath?.trim();
    if (path == null || path.isEmpty) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _isInitializing = false;
          _setErrorState(true);
        });
      }
      return;
    }

    // Prevent duplicate initialization for the exact same active video source
    if (_isInitializing && _initializedPath == path && _controller != null) {
      return;
    }

    final int generation = ++_initGeneration;
    final previousController = _controller;
    _controller = null;
    if (previousController != null) {
      previousController.pause();
      previousController.dispose();
    }

    if (mounted) {
      setState(() {
        _isInitialized = false;
        _isInitializing = true;
        _setErrorState(false);
      });
    }

    final options = VideoPlayerOptions(
      mixWithOthers: true, // Allow mixing with background workout music
      allowBackgroundPlayback: false,
    );

    VideoPlayerController? candidate;
    try {
      candidate = widget.controllerFactory != null
          ? widget.controllerFactory!(path, options)
          : VideoPlayerController.asset(path, videoPlayerOptions: options);
      _controller = candidate;
      _initializedPath = path;

      await candidate.initialize();

      // Verify widget is still mounted and no newer initialization superseded this one
      if (!mounted || generation != _initGeneration || _controller != candidate) {
        await candidate.dispose();
        return;
      }

      await candidate.setVolume(0.0);
      if (widget.autoPlay && !widget.showThumbnailOnly) {
        await candidate.setLooping(true);
        await candidate.play();
      } else {
        await candidate.seekTo(Duration.zero);
        await candidate.pause();
      }

      if (!mounted || generation != _initGeneration || _controller != candidate) {
        await candidate.dispose();
        return;
      }

      setState(() {
        _isInitialized = true;
        _isInitializing = false;
        _setErrorState(false);
      });
    } catch (e) {
      if (candidate != null) {
        if (_controller == candidate) {
          _controller = null;
          _initializedPath = null;
        }
        try {
          await candidate.dispose();
        } catch (_) {}
      }
      if (mounted && generation == _initGeneration) {
        setState(() {
          _isInitialized = false;
          _isInitializing = false;
          _setErrorState(true);
        });
      }
    }
  }

  void _retryInitialization() {
    if (!_hasValidVideoPath) return;
    _initializeVideo();
  }

  @override
  void dispose() {
    _disposeCurrentController();
    super.dispose();
  }

  static String _resolveCategoryThumbnailAsset(String? videoPath) {
    final normalized = (videoPath ?? '').toLowerCase();
    if (normalized.contains('/chest/')) return ImageManager.chestWorkout;
    if (normalized.contains('/legs/')) return ImageManager.legWorkout;
    if (normalized.contains('/back/')) return ImageManager.backWorkout;
    if (normalized.contains('/shoulder/')) return ImageManager.shoulderWorkout;
    if (normalized.contains('/biceps/')) return ImageManager.bicepsWorkout;
    if (normalized.contains('/triceps/')) return ImageManager.tricepsWorkout;
    if (normalized.contains('/abs/')) return ImageManager.absWorkout;
    if (normalized.contains('/cardio/')) return ImageManager.cardioWorkout;
    return ImageManager.strengthWorkout;
  }

  Widget _buildVideoSurface(VideoPlayerController controller) {
    if (widget.videoViewBuilder != null) {
      return widget.videoViewBuilder!(controller);
    }
    return VideoPlayer(controller);
  }

  @override
  Widget build(BuildContext context) {
    // If no video path provided, show static preview or placeholder
    if (!_hasValidVideoPath) {
      if (widget.showThumbnailOnly) {
        return _buildStaticThumbnailPreview();
      }
      return _buildErrorOrFallbackPlaceholder();
    }

    // Show loading state while initializing active video
    if (!_isInitialized && !_hasError) {
      return _buildLoadingPlaceholder();
    }

    // If video is available and initialized, show video player (with play overlay if thumbnail only)
    if (_isInitialized && _controller != null && !_hasError) {
      final videoSize = _controller!.value.size;
      final hasValidSize = videoSize.width > 0 && videoSize.height > 0;
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              hasValidSize
                  ? FittedBox(
                      fit: widget.fit,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: videoSize.width,
                        height: videoSize.height,
                        child: _buildVideoSurface(_controller!),
                      ),
                    )
                  : Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio > 0
                            ? _controller!.value.aspectRatio
                            : 16 / 9,
                        child: _buildVideoSurface(_controller!),
                      ),
                    ),
              if (widget.showThumbnailOnly)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ColorManager.limerGreen2.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: ColorManager.limerGreen2,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Fallback to GIF if provided and no error
    if (widget.gifUrl != null && !_hasError) {
      return Image.network(
        widget.gifUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorOrFallbackPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder();
        },
      );
    }

    // On error in list preview, show static thumbnail preview
    if (widget.showThumbnailOnly) {
      return _buildStaticThumbnailPreview();
    }

    return _buildErrorOrFallbackPlaceholder();
  }

  Widget _buildStaticThumbnailPreview() {
    final hasVideoPath =
        widget.videoPath != null && widget.videoPath!.trim().isNotEmpty;
    final thumbnailAsset = _resolveCategoryThumbnailAsset(widget.videoPath);

    return Container(
      key: const Key('exercise_video_static_preview'),
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              thumbnailAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: ColorManager.surfaceDark,
                  child: Icon(
                    Icons.fitness_center,
                    color: Colors.grey[600],
                    size: 28,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorManager.limerGreen2.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  hasVideoPath
                      ? Icons.play_arrow_rounded
                      : Icons.fitness_center_rounded,
                  color: ColorManager.limerGreen2,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOrFallbackPlaceholder() {
    final isCompact = (widget.height ?? 180) < 110;
    return Container(
      key: const Key('exercise_video_error_state'),
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: isCompact
          ? Center(
              child: IconButton(
                key: const Key('exercise_video_retry_button'),
                icon: Icon(
                  Icons.refresh_rounded,
                  color: ColorManager.textSecondary,
                ),
                tooltip: 'Retry video',
                onPressed: _retryInitialization,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_off_outlined,
                  color: Colors.grey[500],
                  size: 32,
                ),
                const SizedBox(height: 6),
                Text(
                  'Video guide unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.videoPath != null &&
                    widget.videoPath!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    key: const Key('exercise_video_retry_button'),
                    onPressed: _retryInitialization,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: ColorManager.primary,
                    ),
                    label: Text(
                      'Retry',
                      style: TextStyle(
                        color: ColorManager.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    if (widget.showThumbnailOnly) {
      return Container(
        key: const Key('exercise_video_loading_state'),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: ColorManager.surfaceDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(
            Icons.fitness_center_rounded,
            color: Colors.grey[700],
            size: 24,
          ),
        ),
      );
    }
    return Container(
      key: const Key('exercise_video_loading_state'),
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: ColorManager.textPrimary,
          ),
        ),
      ),
    );
  }
}


