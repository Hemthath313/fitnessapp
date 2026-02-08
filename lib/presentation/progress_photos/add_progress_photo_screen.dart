import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/presentation/progress_photos/providers/progress_photo_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProgressPhotoScreen extends StatefulWidget {
  const AddProgressPhotoScreen({super.key});

  @override
  State<AddProgressPhotoScreen> createState() => _AddProgressPhotoScreenState();
}

class _AddProgressPhotoScreenState extends State<AddProgressPhotoScreen> {
  File? _selectedImage;
  String _selectedCategory = 'front';
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserWeight();
  }

  Future<void> _loadUserWeight() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final weight = doc.data()?['weight'];
        if (weight != null && mounted) {
          _weightController.text = weight.toString();
        }
      }
    } catch (e) {
      // Silently fail - weight is optional
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorManager.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeManager.s16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Photo Source',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: ColorManager.primary),
                title: const Text('Camera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: ColorManager.primary),
                title: const Text('Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo first')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final provider = Provider.of<ProgressPhotoProvider>(context, listen: false);
      
      await provider.uploadPhoto(
        imageFile: _selectedImage!,
        category: _selectedCategory,
        weight: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: const Text('Add Progress Photo', style: TextStyle(color: Colors.white)),
        backgroundColor: ColorManager.background,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeManager.s16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 300.h,
                decoration: BoxDecoration(
                  color: ColorManager.surface,
                  borderRadius: BorderRadius.circular(SizeManager.s16.r),
                  border: Border.all(color: ColorManager.primary, width: 2),
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 60.sp, color: ColorManager.primary),
                          SizedBox(height: 12.h),
                          Text(
                            'Tap to select photo',
                            style: TextStyle(color: ColorManager.textSecondary, fontSize: 16.sp),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(SizeManager.s16.r),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
              ),
            ),

            SizedBox(height: 24.h),

            // Category selector
            Text(
              'Photo Category',
              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                _buildCategoryChip('front', 'Front', Icons.person),
                SizedBox(width: 8.w),
                _buildCategoryChip('side', 'Side', Icons.accessibility_new),
                SizedBox(width: 8.w),
                _buildCategoryChip('back', 'Back', Icons.person_outline),
              ],
            ),

            SizedBox(height: 24.h),

            // Weight input
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Current Weight (kg)',
                labelStyle: TextStyle(color: ColorManager.textSecondary),
                hintText: 'Optional',
                hintStyle: TextStyle(color: ColorManager.textTertiary),
                filled: true,
                fillColor: ColorManager.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.monitor_weight, color: ColorManager.primary),
              ),
            ),

            SizedBox(height: 16.h),

            // Notes input
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Notes',
                labelStyle: TextStyle(color: ColorManager.textSecondary),
                hintText: 'How are you feeling? Any changes?',
                hintStyle: TextStyle(color: ColorManager.textTertiary),
                filled: true,
                fillColor: ColorManager.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.notes, color: ColorManager.primary),
              ),
            ),

            SizedBox(height: 32.h),

            // Upload button
            SizedBox(
              height: 50.h,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadPhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 5,
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        'Upload Photo',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label, IconData icon) {
    final isSelected = _selectedCategory == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? ColorManager.primary : ColorManager.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? ColorManager.primary : ColorManager.surfaceLight,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.black : Colors.white,
                size: 24.sp,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
