import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/presentation/body_parts/pages/abs.dart';
import 'package:fitness_app/presentation/body_parts/pages/biceps.dart';
import 'package:fitness_app/presentation/body_parts/pages/chest.dart';
import 'package:fitness_app/presentation/body_parts/pages/lats.dart';
import 'package:fitness_app/presentation/body_parts/pages/legs.dart';
import 'package:fitness_app/presentation/body_parts/pages/shoulder.dart';
import 'package:fitness_app/presentation/body_parts/pages/triceps.dart';
import 'package:fitness_app/presentation/widgets/interactive_exercise_detail.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BodyPartsScreen extends StatefulWidget {
  const BodyPartsScreen({super.key});

  @override
  State<BodyPartsScreen> createState() => _BodyPartsScreenState();
}

class _BodyPartsScreenState extends State<BodyPartsScreen> {
  final Map<String, String> bodyPartImages = {
    'Chest': ImageManager.anatomyChest,
    'Biceps': ImageManager.anatomyBiceps,
    'Triceps': ImageManager.anatomyTriceps,
    'Shoulders': ImageManager.anatomyShoulders,
    'Legs': ImageManager.anatomyLegs,
    'Back': ImageManager.anatomyBack,
    'Abs': ImageManager.anatomyAbs,
  };

  final Map<String, Widget Function()> bodyPartScreens = {
    'Chest': () => const ChestExercisesPage(),
    'Biceps': () => const BicepsExercisesPage(),
    'Triceps': () => const TricepsExercisesPage(),
    'Shoulders': () => const ShoulderExercisesPage(),
    'Legs': () => const LegExercisesPage(),
    'Back': () => const LatExercisesPage(),
    'Abs': () => const AbsExercisesPage(),
  };
  List<bool> isVisible = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _appliedDifficulty = 'All';
  String _appliedEquipment = 'All';

  bool get _hasFilterSelected =>
      _appliedDifficulty != 'All' || _appliedEquipment != 'All';

  List<Exercise> get _filteredStrengthExercises => ExerciseData.filterExercises(
        ExerciseData.strengthExercises,
        query: _searchQuery,
        difficulty: _appliedDifficulty,
        equipment: _appliedEquipment,
      );

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _appliedDifficulty = 'All';
      _appliedEquipment = 'All';
    });
  }

  @override
  void initState() {
    super.initState();
    isVisible = List.generate(bodyPartImages.length, (index) => false);
    _triggerAnimations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerAnimations() {
    for (int i = 0; i < isVisible.length; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () {
        if (mounted) {
          setState(() {
            isVisible[i] = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = _filteredStrengthExercises;
    final bool isSearching = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: ColorManager.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(tooltip: 'Back', 
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: ColorManager.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Bold header section + Search & Filter row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Body Focus',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select a muscle group to target and begin your training session',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 14.sp,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSearchAndFilters(filteredExercises.length),
                  ],
                ),
              ),
            ),

            if (isSearching)
              if (filteredExercises.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyState(),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exercise = filteredExercises[index];
                      return _buildExerciseCard(exercise);
                    },
                    childCount: filteredExercises.length,
                  ),
                )
            else
              // Category cards grid remains primary when not searching
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      String bodyPart = bodyPartImages.keys.elementAt(index);
                      String imagePath = bodyPartImages[bodyPart]!;

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 350),
                        opacity: isVisible[index] ? 1.0 : 0.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          transform: isVisible[index]
                              ? Matrix4.identity()
                              : Matrix4.translationValues(0, 20, 0),
                          curve: Curves.easeOutCubic,
                          child: GestureDetector(
                            onTap: () {
                              if (bodyPartScreens.containsKey(bodyPart)) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => bodyPartScreens[bodyPart]!(),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: ColorManager.surface,
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                  color: ColorManager.divider.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18.5),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Positioned.fill(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
                                        child: Image.asset(
                                          imagePath,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            ColorManager.surface.withValues(alpha: 0.95),
                                            ColorManager.surface.withValues(alpha: 0.6),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          stops: const [0.0, 0.38, 0.75],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            bodyPart,
                                            style:  TextStyle(
                                              color: Colors.white,
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                'View exercises',
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.7),
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: ColorManager.primary.withValues(alpha: 0.85),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.arrow_forward_ios_rounded,
                                                  color: Colors.white,
                                                  size: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: bodyPartImages.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(int resultCount) {
    final bool hasFilterSelected = _hasFilterSelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('body_parts_search_field'),
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(color: ColorManager.textPrimary, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'Search all strength exercises...',
                  hintStyle: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp),
                  prefixIcon: Icon(Icons.search_rounded, color: ColorManager.primary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(tooltip: 'Close', 
                          key: const Key('clear_body_parts_search_button'),
                          icon: Icon(Icons.close_rounded, color: ColorManager.textSecondary, size: 18),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: ColorManager.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: ColorManager.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: ColorManager.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: ColorManager.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: hasFilterSelected
                    ? ColorManager.primary.withValues(alpha: 0.15)
                    : ColorManager.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasFilterSelected
                      ? ColorManager.primary
                      : ColorManager.divider,
                  width: hasFilterSelected ? 1.5 : 1,
                ),
              ),
              child: IconButton(
                key: const Key('exercise_filter_button'),
                icon: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: hasFilterSelected
                          ? ColorManager.primary
                          : ColorManager.textSecondary,
                      size: 20,
                    ),
                    if (hasFilterSelected)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: ColorManager.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Filter exercises',
                onPressed: () => _showFilterBottomSheet(context),
              ),
            ),
          ],
        ),
        if (_searchQuery.trim().isNotEmpty || hasFilterSelected) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_searchQuery.trim().isNotEmpty)
                Flexible(
                  child: Text(
                    'Showing $resultCount of ${ExerciseData.strengthExercises.length} exercises',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                Flexible(
                  child: Text(
                    'Filters: $_appliedDifficulty${_appliedEquipment != 'All' ? ' • $_appliedEquipment' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ColorManager.limerGreen2,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              TextButton(
                key: const Key('clear_body_parts_filters_button'),
                onPressed: _resetFilters,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Clear filters',
                  style: TextStyle(
                    color: ColorManager.primary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    String draftDifficulty = _appliedDifficulty;
    String draftEquipment = _appliedEquipment;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ColorManager.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (_, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Exercises',
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          key: const Key('reset_sheet_filters_button'),
                          onPressed: () {
                            setModalState(() {
                              draftDifficulty = 'All';
                              draftEquipment = 'All';
                            });
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'DIFFICULTY',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ExerciseData.difficultyFilterOptions.map((option) {
                        final isSelected = draftDifficulty == option;
                        return ChoiceChip(
                          key: Key('difficulty_filter_$option'),
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (_) =>
                              setModalState(() => draftDifficulty = option),
                          selectedColor: ColorManager.primary.withValues(alpha: 0.2),
                          backgroundColor: ColorManager.surfaceDark,
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                            color: isSelected ? ColorManager.primary : ColorManager.textSecondary,
                            fontSize: 12.sp,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: isSelected ? ColorManager.primary : ColorManager.divider,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'EQUIPMENT',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ExerciseData.equipmentFilterOptions.map((option) {
                        final isSelected = draftEquipment == option;
                        return ChoiceChip(
                          key: Key('equipment_filter_$option'),
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (_) =>
                              setModalState(() => draftEquipment = option),
                          selectedColor: ColorManager.primary.withValues(alpha: 0.2),
                          backgroundColor: ColorManager.surfaceDark,
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                            color: isSelected ? ColorManager.primary : ColorManager.textSecondary,
                            fontSize: 12.sp,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: isSelected ? ColorManager.primary : ColorManager.divider,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key('apply_exercise_filters_button'),
                        onPressed: () {
                          setState(() {
                            _appliedDifficulty = draftDifficulty;
                            _appliedEquipment = draftEquipment;
                          });
                          Navigator.pop(bottomSheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: const Color(0xFF06201B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child:  Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      key: const Key('body_parts_empty_state'),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: ColorManager.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'No exercises match your search or filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            key: const Key('reset_body_parts_filters_button'),
            onPressed: _resetFilters,
            icon: Icon(Icons.refresh_rounded, color: ColorManager.primary, size: 18),
            label: Text(
              'Reset Filters',
              style: TextStyle(
                color: ColorManager.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    final hasEquipment = exercise.equipment.trim().isNotEmpty;
    final category = ExerciseData.categoryFor(exercise.name) ?? 'Strength';
    return Container(
      key: ValueKey('body_parts_exercise_card_${exercise.name}'),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorManager.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => InteractiveExerciseDetailWidget(
                name: exercise.name,
                videoPath: exercise.videoPath,
                description: exercise.description,
                target: exercise.target,
                equipment: exercise.equipment,
                instructions: exercise.instructions,
                difficulty: exercise.difficulty,
                setsReps: exercise.setsReps,
                category: category,
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 110,
                    height: 92,
                    child: ExerciseVideoPlayer(
                      videoPath: exercise.videoPath,
                      height: 92,
                      width: 110,
                      showThumbnailOnly: true,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        exercise.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exercise.setsReps,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ColorManager.limerGreen2,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasEquipment) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              size: 13,
                              color: ColorManager.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                exercise.equipment,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ColorManager.textPrimary.withValues(alpha: 0.85),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: ColorManager.limerGreen2.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                exercise.difficulty,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ColorManager.limerGreen2,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              exercise.target,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ColorManager.textSecondary,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
