import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitness_app/model/progress_photo.dart';
import 'package:fitness_app/presentation/progress_photos/providers/progress_photo_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PhotoComparisonScreen extends StatefulWidget {
  const PhotoComparisonScreen({super.key});

  @override
  State<PhotoComparisonScreen> createState() => _PhotoComparisonScreenState();
}

class _PhotoComparisonScreenState extends State<PhotoComparisonScreen> {
  ProgressPhoto? _beforePhoto;
  ProgressPhoto? _afterPhoto;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDefaultComparison();
  }

  Future<void> _loadDefaultComparison() async {
    final provider = Provider.of<ProgressPhotoProvider>(context, listen: false);
    final comparison = await provider.getComparisonPhotos();

    setState(() {
      _beforePhoto = comparison['oldest'];
      _afterPhoto = comparison['latest'];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressPhotoProvider>(context);
    final allPhotos = provider.allPhotos;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text('Compare Progress', style: TextStyle(color: ColorManager.textPrimary)),
        backgroundColor: ColorManager.background,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : allPhotos.length < 2
              ? _buildInsufficientPhotosMessage()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 16.h),
                      _buildPhotoSelectors(allPhotos),
                      SizedBox(height: 24.h),
                      _buildComparisonView(),
                      SizedBox(height: 24.h),
                      _buildStatsComparison(),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInsufficientPhotosMessage() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 80.sp, color: ColorManager.textTertiary),
            SizedBox(height: 16.h),
            Text(
              'Need More Photos',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'You need at least 2 progress photos to use the comparison feature.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSelectors(List<ProgressPhoto> photos) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeManager.s16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildPhotoSelector(
              label: 'Before',
              selectedPhoto: _beforePhoto,
              photos: photos,
              onSelect: (photo) => setState(() => _beforePhoto = photo),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _buildPhotoSelector(
              label: 'After',
              selectedPhoto: _afterPhoto,
              photos: photos,
              onSelect: (photo) => setState(() => _afterPhoto = photo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSelector({
    required String label,
    required ProgressPhoto? selectedPhoto,
    required List<ProgressPhoto> photos,
    required Function(ProgressPhoto) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ColorManager.textSecondary,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _showPhotoPickerDialog(photos, onSelect),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: ColorManager.surface,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: ColorManager.primary),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedPhoto != null
                        ? DateFormat('MMM dd, yyyy').format(selectedPhoto.date)
                        : 'Select Photo',
                    style: TextStyle(color: ColorManager.textPrimary, fontSize: 12.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: ColorManager.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPhotoPickerDialog(
      List<ProgressPhoto> photos, Function(ProgressPhoto) onSelect) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorManager.surface,
        title: Text('Select Photo', style: TextStyle(color: ColorManager.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: CachedNetworkImage(
                    imageUrl: photo.imageUrl,
                    width: 50.w,
                    height: 50.h,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  DateFormat('MMM dd, yyyy').format(photo.date),
                  style: TextStyle(color: ColorManager.textPrimary),
                ),
                subtitle: Text(
                  photo.categoryDisplay,
                  style: TextStyle(color: ColorManager.textSecondary),
                ),
                onTap: () {
                  onSelect(photo);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonView() {
    if (_beforePhoto == null || _afterPhoto == null) {
      return Padding(
        padding: EdgeInsets.all(32.w),
        child: Text(
          'Please select both before and after photos',
          textAlign: TextAlign.center,
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeManager.s16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildPhotoCard(_beforePhoto!, 'Before'),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _buildPhotoCard(_afterPhoto!, 'After'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(ProgressPhoto photo, String label) {
    return Column(
      children: [
        Container(
          height: 250.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: CachedNetworkImage(
              imageUrl: photo.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: ColorManager.surfaceLight,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: label == 'Before' ? Colors.orange : ColorManager.primary,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsComparison() {
    if (_beforePhoto == null || _afterPhoto == null) return const SizedBox();

    final isPremium = Provider.of<SubscriptionProvider>(context).isPremium;

    // Premium Locked View
    if (!isPremium) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: SizeManager.s16.w),
        padding: EdgeInsets.all(SizeManager.s16.w),
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress Summary',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.lock_outline, color: Colors.amber, size: 24.sp),
              ],
            ),
            SizedBox(height: 24.h),
            Text(
              'Unlock Detailed Analysis',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'See exactly how much weight you\'ve lost and the time between photos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.push(Routes.premiumScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: const Text('Get Pro Access'),
            ),
          ],
        ),
      );
    }

    // Premium Features Unlocked
    final daysDiff = _afterPhoto!.date.difference(_beforePhoto!.date).inDays;
    final weightDiff = (_afterPhoto!.weight != null && _beforePhoto!.weight != null)
        ? _afterPhoto!.weight! - _beforePhoto!.weight!
        : null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: SizeManager.s16.w),
      padding: EdgeInsets.all(SizeManager.s16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Progress Summary',
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          _buildStatRow(
            icon: Icons.calendar_today,
            label: 'Time Period',
            value: '$daysDiff days',
          ),
          if (weightDiff != null) ...[
            SizedBox(height: 12.h),
            _buildStatRow(
              icon: Icons.trending_down,
              label: 'Weight Change',
              value: '${weightDiff > 0 ? '+' : ''}${weightDiff.toStringAsFixed(1)} kg',
              valueColor: weightDiff < 0 ? Colors.green : Colors.orange,
            ),
          ],
          SizedBox(height: 12.h),
          _buildStatRow(
            icon: Icons.photo_camera,
            label: 'Total Photos',
            value: Provider.of<ProgressPhotoProvider>(context).allPhotos.length.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: ColorManager.primary, size: 20.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
