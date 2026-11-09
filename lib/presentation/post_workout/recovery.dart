import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'dart:async';
import 'package:fitness_app/data/pain_relief_data.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vibration/vibration.dart';

class PostWorkoutRecoveryPage extends StatelessWidget {
  const PostWorkoutRecoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
        title: Text('Pain Relief & Mobility',
            style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Where does it hurt?',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final zone = PainReliefData.painZones[index];
                  return _PainZoneCard(
                    title: zone['title'],
                    subtitle: zone['subtitle'],
                    icon: zone['icon'],
                    color: zone['color'],
                    routines: zone['routines'],
                  );
                },
                childCount: PainReliefData.painZones.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
        ],
      ),
    );
  }
}

class _PainZoneCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<dynamic> routines;

  const _PainZoneCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.routines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: ColorManager.divider),
      ),
      // Transparent Material so the tile's ink paints above the card colour.
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          leading: Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp),
          ),
          children: routines.map((item) {
            return _StretchTile(name: item['name'], duration: item['duration']);
          }).toList(),
        ),
        ),
      ),
    );
  }
}

class _StretchTile extends StatefulWidget {
  final String name;
  final int duration;

  const _StretchTile({required this.name, required this.duration});

  @override
  State<_StretchTile> createState() => _StretchTileState();
}

class _StretchTileState extends State<_StretchTile> {
  int? _remainingTime;
  Timer? _timer;
  bool _isRunning = false;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    if (_remainingTime == null || _remainingTime == 0) {
      setState(() => _remainingTime = widget.duration);
    }
    
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime! > 0) {
        setState(() => _remainingTime = _remainingTime! - 1);
      } else {
        timer.cancel();
        setState(() => _isRunning = false);
        _notifyCompletion();
      }
    });
  }

  void _notifyCompletion() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 500);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.name} completed!'),
          backgroundColor: ColorManager.limerGreen2,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingTime != null
        ? (_remainingTime! / widget.duration)
        : 1.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.small.r),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50.w,
            height: 50.w,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  color: ColorManager.limerGreen2,
                  backgroundColor: Colors.white24,
                  strokeWidth: 4,
                ),
                Center(
                  child: Text(
                    _remainingTime != null ? '${_remainingTime}s' : '${widget.duration}s',
                    style: TextStyle(
                      color: ColorManager.textPrimary, 
                      fontSize: 12.sp, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  'Duration: ${widget.duration}s',
                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          IconButton(tooltip: _isRunning ? 'Pause' : 'Start', 
            onPressed: _toggleTimer,
            icon: Icon(
              _isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: ColorManager.limerGreen2,
              size: 32.sp,
            ),
          ),
        ],
      ),
    );
  }
}
