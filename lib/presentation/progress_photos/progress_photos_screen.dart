import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitness_app/model/progress_photo.dart';
import 'package:fitness_app/presentation/progress_photos/providers/progress_photo_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProgressPhotosScreen extends StatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProgressPhotoProvider>(context, listen: false)
          .listenToPhotos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressPhotoProvider>(context);

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text('Progress Photos',
            style: TextStyle(color: ColorManager.textPrimary)),
        backgroundColor: ColorManager.background,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
        actions: [
          if (provider.allPhotos.length >= 2)
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              tooltip: 'Compare Photos',
              onPressed: () => context.push(Routes.photoComparisonRoute),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.addProgressPhotoRoute),
        backgroundColor: ColorManager.primary,
        child: const Icon(Icons.add_a_photo, color: ColorManager.onMint),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(provider),
          Expanded(
            child: provider.isLoading && provider.photos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.photos.isEmpty
                    ? _buildEmptyState()
                    : _buildPhotoGrid(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(ProgressPhotoProvider provider) {
    final categories = [
      {'value': 'all', 'label': 'All', 'icon': Icons.grid_view},
      {'value': 'front', 'label': 'Front', 'icon': Icons.person},
      {'value': 'side', 'label': 'Side', 'icon': Icons.accessibility_new},
      {'value': 'back', 'label': 'Back', 'icon': Icons.person_outline},
    ];

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeManager.s16.w, vertical: SizeManager.s12.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final isSelected = provider.selectedCategory == cat['value'];
            return Padding(
              padding: EdgeInsets.only(right: SizeManager.s8.w),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat['icon'] as IconData,
                        size: 16.sp,
                        color: isSelected ? ColorManager.onMint : ColorManager.textPrimary),
                    SizedBox(width: 4.w),
                    Text(cat['label'] as String),
                  ],
                ),
                onSelected: (_) => provider.setCategory(cat['value'] as String),
                backgroundColor: ColorManager.surface,
                selectedColor: ColorManager.primary,
                labelStyle: TextStyle(
                  color: isSelected ? ColorManager.onMint : ColorManager.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(ProgressPhotoProvider provider) {
    return GridView.builder(
      padding: EdgeInsets.all(SizeManager.s16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: SizeManager.s12.w,
        mainAxisSpacing: SizeManager.s12.h,
        childAspectRatio: 0.75,
      ),
      itemCount: provider.photos.length,
      itemBuilder: (context, index) {
        final photo = provider.photos[index];
        return _buildPhotoCard(photo, provider);
      },
    );
  }

  Widget _buildPhotoCard(ProgressPhoto photo, ProgressPhotoProvider provider) {
    return GestureDetector(
      onTap: () => _showPhotoDetail(photo, provider),
      onLongPress: () => _showDeleteDialog(photo, provider),
      child: Container(
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(AppRadius.small.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(SizeManager.s12.r)),
                child: CachedNetworkImage(
                  imageUrl: photo.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: ColorManager.surfaceLight,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: ColorManager.surfaceLight,
                    child: const Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(SizeManager.s8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy').format(photo.date),
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (photo.weight != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      '${photo.weight!.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                  SizedBox(height: 2.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      photo.categoryDisplay,
                      style: TextStyle(
                        color: ColorManager.primary,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera, size: 80.sp, color: ColorManager.textTertiary),
          SizedBox(height: 16.h),
          Text(
            'No Progress Photos Yet',
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap the + button to add your first photo',
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoDetail(ProgressPhoto photo, ProgressPhotoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: CachedNetworkImage(
                imageUrl: photo.imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ColorManager.surface,
                boxShadow: ColorManager.cardShadow,
                borderRadius: BorderRadius.circular(AppRadius.small.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM dd, yyyy').format(photo.date),
                    style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold),
                  ),
                  if (photo.weight != null) ...[
                    SizedBox(height: 8.h),
                    Text('Weight: ${photo.weight!.toStringAsFixed(1)} kg',
                        style: TextStyle(
                            color: ColorManager.textSecondary, fontSize: 14.sp)),
                  ],
                  if (photo.notes != null && photo.notes!.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text('Notes: ${photo.notes}',
                        style: TextStyle(
                            color: ColorManager.textSecondary, fontSize: 14.sp)),
                  ],
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteDialog(photo, provider);
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: ColorManager.textPrimary),
                        label: Text('Close',
                            style: TextStyle(color: ColorManager.textPrimary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(ProgressPhoto photo, ProgressPhotoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorManager.surface,
        title: Text('Delete Photo?',
            style: TextStyle(color: ColorManager.textPrimary)),
        content: Text(
            'This action cannot be undone. The photo will be permanently deleted.',
            style: TextStyle(color: ColorManager.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: ColorManager.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.deletePhoto(photo);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Photo deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting photo: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: ColorManager.textPrimary)),
          ),
        ],
      ),
    );
  }
}
