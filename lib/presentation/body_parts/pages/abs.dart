import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/presentation/widgets/interactive_exercise_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef AbsExercise = Exercise;

class AbsExercisesPage extends StatefulWidget {
  const AbsExercisesPage({super.key});

  @override
  _AbsExercisesPageState createState() => _AbsExercisesPageState();
}

class _AbsExercisesPageState extends State<AbsExercisesPage> {
  // Centralized abs/core exercise catalog
  final List<AbsExercise> absExercises = ExerciseData.abs;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _appliedDifficulty = 'All';
  String _appliedEquipment = 'All';

  List<AbsExercise> get _filteredExercises => ExerciseData.filterExercises(
        absExercises,
        query: _searchQuery,
        difficulty: _appliedDifficulty,
        equipment: _appliedEquipment,
      );

  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _appliedDifficulty != 'All' ||
      _appliedEquipment != 'All';

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _appliedDifficulty = 'All';
      _appliedEquipment = 'All';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = _filteredExercises;
    return Scaffold(
      backgroundColor: ColorManager.background,
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar with gradient
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: ColorManager.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Abs Workouts',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorManager.black,
                      ColorManager.darkGrey,
                      ColorManager.black,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: ColorManager.limerGreen2.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            iconTheme: IconThemeData(color: ColorManager.textPrimary),
          ),

          // Header Section + Search & Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build a Strong Core',
                    style: TextStyle(
                      color: ColorManager.limerGreen2,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Premium video workouts',
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSearchAndFilters(filteredExercises.length),
                ],
              ),
            ),
          ),

          // Exercises List or Empty State
          if (filteredExercises.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final exercise = filteredExercises[index];
                  return _buildExerciseCard(exercise, index);
                },
                childCount: filteredExercises.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(int resultCount) {
    final bool hasFilterSelected =
        _appliedDifficulty != 'All' || _appliedEquipment != 'All';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('exercise_search_field'),
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(color: ColorManager.textPrimary, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'Search exercises by name...',
                  hintStyle: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 14.sp,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: ColorManager.primary,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(tooltip: 'Close', 
                          key: const Key('clear_exercise_search_button'),
                          icon: Icon(
                            Icons.close_rounded,
                            color: ColorManager.textSecondary,
                            size: 18,
                          ),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
                    borderSide: BorderSide(
                      color: ColorManager.primary,
                      width: 1.5,
                    ),
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
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Showing $resultCount of ${absExercises.length} exercises',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_hasActiveFilters)
              TextButton(
                key: const Key('clear_all_filters_button'),
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
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    // Initialise draft from currently applied filters
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
          builder: (context, setModalState) {
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
                            color: isSelected
                                ? ColorManager.primary
                                : ColorManager.textSecondary,
                            fontSize: 12.sp,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? ColorManager.primary
                                : ColorManager.divider,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                            color: isSelected
                                ? ColorManager.primary
                                : ColorManager.textSecondary,
                            fontSize: 12.sp,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? ColorManager.primary
                                : ColorManager.divider,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
      key: const Key('exercise_empty_state'),
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
            key: const Key('reset_exercise_filters_button'),
            onPressed: _resetFilters,
            icon: Icon(Icons.refresh_rounded, color: ColorManager.limerGreen2, size: 18),
            label: Text(
              'Reset Filters',
              style: TextStyle(
                color: ColorManager.limerGreen2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(AbsExercise exercise, int index) {
    final hasEquipment = exercise.equipment.trim().isNotEmpty;
    return Container(
      key: ValueKey('exercise_card_${exercise.name}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorManager.limerGreen2.withValues(alpha: 0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showExerciseDetails(context, exercise),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video/Thumbnail preview
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
                // Exercise details
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


  void _showExerciseDetails(BuildContext context, AbsExercise exercise) {
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
        category: 'Abs',
      ),
    );
  }

}
