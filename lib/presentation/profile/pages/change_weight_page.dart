import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/profile/providers/profile_provider.dart';
import 'package:fitness_app/presentation/progress/progress_data.dart';
import 'package:fitness_app/presentation/settings/widgets/change_password_app_bar.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/widgets/lime_green_rounded_button.dart';
import 'package:fitness_app/utils/widgets/text_field_widget.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ChangeWeightPage extends StatefulWidget {
  const ChangeWeightPage({super.key});

  @override
  State<ChangeWeightPage> createState() => _ChangeWeightPageState();
}

class _ChangeWeightPageState extends State<ChangeWeightPage> {
  final TextEditingController _weightController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  bool _saving = false;
  DateTime _date = DateTime.now();

  bool get _isToday =>
      ProgressData.dayKey(_date) == ProgressData.dayKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    _weightController.text = ProgressData.prefill(homeProvider.userData['weight']);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Provider.of<ProfileProvider>(context, listen: false)
            .fetchAndSetFlSpots();
      } catch (e) {
        debugPrint('Error loading weigh-ins: $e');
      }
    });
  }

  TimedValue? _entryOn(DateTime day) {
    final entries =
        Provider.of<ProfileProvider>(context, listen: false).weightEntries;
    final key = ProgressData.dayKey(day);
    for (final e in entries.reversed) {
      if (ProgressData.dayKey(e.date) == key) return e;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: 'Date of weigh-in',
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
    // Logging a day that already has a reading edits it - show its value.
    final existing = _entryOn(picked);
    if (existing != null) {
      _weightController.text = ProgressData.prefill(existing.value);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> changeWeight() async {
    final error = ProgressData.validateWeight(_weightController.text);
    if (error != null) {
      _toast(error);
      return;
    }
    final weight = ProgressData.parseNumber(_weightController.text)!;
    final existing = _entryOn(_date);
    await _persist(
      weight,
      ProgressData.entryTimestamp(_date, DateTime.now()),
      entryId: existing?.id,
      closePage: true,
    );
  }

  /// Saves one weigh-in (new, same-day correction or an edit of [entryId]).
  Future<void> _persist(
    double weight,
    DateTime when, {
    String? entryId,
    required bool closePage,
  }) async {
    if (_saving) return;

    final messenger = ScaffoldMessenger.of(context);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);

    _saving = true;
    LoadingOverlay.show(context, message: 'Updating weight...');
    try {
      await homeProvider.getUsersBMI(
        height: homeProvider.userData['height'],
        weight: weight,
      );
      await homeProvider.getUsersBMR(
        gender: homeProvider.userData['gender'],
        weight: weight,
        height: homeProvider.userData['height'],
        age: homeProvider.userData['age'],
        activity: homeProvider.userData['activity'],
        goal: homeProvider.userData['goal'],
      );
      if (!mounted) return;
      await profileProvider.changeUsersWeight(
        bmi: homeProvider.usersBMI,
        bmr: homeProvider.userBMRwithGoal,
        weight: weight,
        weightDateTime: when.month,
        context: context,
        date: when,
        entryId: entryId,
      );
      await homeProvider.fetchUserData();

      if (mounted) {
        LoadingOverlay.hide(context);
        if (closePage) Navigator.of(context).pop();
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Weight logged: ${weight.toStringAsFixed(1)} kg')),
        );
    } catch (e) {
      debugPrint('Error saving weight: $e');
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Couldn't save your weight. Check your connection and try again."),
          ),
        );
    } finally {
      _saving = false;
    }
  }

  Future<void> _editEntry(TimedValue entry) async {
    final result = await showDialog<(bool, double?)>(
      context: context,
      builder: (_) => _NumberDialog(
        title: 'Edit weigh-in · ${ProgressData.formatDay(entry.date)}',
        initialText: ProgressData.prefill(entry.value),
        validate: ProgressData.validateWeight,
      ),
    );
    final newValue = result?.$2;
    if (newValue == null || !mounted) return;
    await _persist(newValue, entry.date, entryId: entry.id, closePage: false);
  }

  Future<void> _deleteEntry(TimedValue entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this weigh-in?'),
        content: Text(
          '${entry.value.toStringAsFixed(1)} kg on ${ProgressData.formatDay(entry.date)} '
          'will be removed from your progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _saving) return;

    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    _saving = true;
    LoadingOverlay.show(context, message: 'Deleting weigh-in...');
    try {
      final newLatest = await profileProvider.deleteWeightEntry(entry);
      if (newLatest != null) {
        // The newest reading changed, so the current weight, BMI and calorie
        // target must follow it.
        await homeProvider.getUsersBMI(
          height: homeProvider.userData['height'],
          weight: newLatest.value,
        );
        await homeProvider.getUsersBMR(
          gender: homeProvider.userData['gender'],
          weight: newLatest.value,
          height: homeProvider.userData['height'],
          age: homeProvider.userData['age'],
          activity: homeProvider.userData['activity'],
          goal: homeProvider.userData['goal'],
        );
        await profileProvider.updateProfileWeight(
          weight: newLatest.value,
          bmi: homeProvider.usersBMI,
          bmr: homeProvider.userBMRwithGoal,
        );
        await homeProvider.fetchUserData();
      }
      if (mounted) {
        LoadingOverlay.hide(context);
        _toast('Weigh-in deleted');
      }
    } catch (e) {
      debugPrint('Error deleting weigh-in: $e');
      if (mounted) {
        LoadingOverlay.hide(context);
        _toast("Couldn't delete that weigh-in. Please try again.");
      }
    } finally {
      _saving = false;
    }
  }

  double? get _goalWeight {
    final v = Provider.of<HomeProvider>(context, listen: false)
        .userData['goalWeight'];
    return v is num && v > 0 ? v.toDouble() : null;
  }

  Future<void> _editGoal() async {
    final current = _goalWeight;
    final result = await showDialog<(bool, double?)>(
      context: context,
      builder: (_) => _NumberDialog(
        title: 'Goal weight',
        initialText: ProgressData.prefill(current),
        validate: ProgressData.validateGoalWeight,
        allowRemove: current != null,
      ),
    );
    if (result == null || !mounted) return;

    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    try {
      await profileProvider.updateGoalWeight(result.$1 ? null : result.$2);
      await homeProvider.fetchUserData();
      if (mounted) {
        setState(() {});
        _toast(result.$1 ? 'Goal weight removed' : 'Goal weight saved');
      }
    } catch (e) {
      debugPrint('Error saving goal weight: $e');
      if (mounted) _toast("Couldn't save your goal weight. Please try again.");
    }
  }

  Widget _buildGoalChip() {
    final goal = _goalWeight;
    return InkWell(
      onTap: _editGoal,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(AppRadius.tile.r),
          border: Border.all(color: ColorManager.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_rounded, color: ColorManager.primaryText, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              goal == null
                  ? 'Set a goal weight'
                  : 'Goal · ${goal.toStringAsFixed(1)} kg',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(Icons.edit_outlined, color: ColorManager.textSecondary, size: 16.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(AppRadius.tile.r),
          border: Border.all(color: ColorManager.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded, color: ColorManager.primaryText, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              _isToday
                  ? 'Today · ${ProgressData.formatDay(_date)}'
                  : ProgressData.formatDay(_date),
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.arrow_drop_down_rounded, color: ColorManager.textSecondary, size: 22.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntries(List<TimedValue> entries) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final recent = entries.reversed.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 40.h),
        Text(
          'Recent weigh-ins',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Tap a reading to edit it.',
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
        ),
        SizedBox(height: 12.h),
        for (final e in recent)
          Container(
            margin: EdgeInsets.only(bottom: 8.h),
            decoration: BoxDecoration(
              color: ColorManager.surface,
              boxShadow: ColorManager.cardShadow,
              borderRadius: BorderRadius.circular(AppRadius.tile.r),
              border: Border.all(color: ColorManager.divider),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
              onTap: () => _editEntry(e),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              title: Text(
                '${e.value.toStringAsFixed(1)} kg',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: AppText.body,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                ProgressData.formatDay(e.date),
                style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
              ),
              trailing: IconButton(
                tooltip: 'Delete weigh-in',
                icon: Icon(Icons.delete_outline_rounded, color: ColorManager.textSecondary),
                onPressed: () => _deleteEntry(e),
              ),
            ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'Log Weight',
          style: TextStyle(
            color: ColorManager.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorManager.background,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.white),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 30.h),
              // Scale Icon in circle
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: ColorManager.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorManager.primary.withValues(alpha: 0.15), width: 2),
                ),
                child: Icon(
                  Icons.scale,
                  color: ColorManager.primaryText,
                  size: 56.sp,
                ),
              ),
              SizedBox(height: 32.h),
              
              // Helper text
              Text(
                'Enter your current weight:',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              
              // Custom interactive weight input
              Center(
                child: Container(
                  width: 160.w,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: ColorManager.surface,
                    boxShadow: ColorManager.cardShadow,
                    borderRadius: BorderRadius.circular(AppRadius.card.r),
                    border: Border.all(color: ColorManager.divider),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      IntrinsicWidth(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          style: TextStyle(
                            color: ColorManager.white,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'kg',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _buildDateChip(),
              SizedBox(height: 10.h),
              _buildGoalChip(),
              SizedBox(height: 24.h),

              // Detailed Tip Text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'Keeping your weight up to date ensures your calorie budgets, progress charts, and training intensity recommendations remain accurate.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 48.h),
              
              // Continue button
              LimeGreenRoundedButtonWidget(
                onTap: changeWeight,
                title: StringsManager.next,
              ),
              _buildRecentEntries(profileProvider.weightEntries),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
          duration: 500.ms,
        );
  }
}

/// Single-number entry dialog. It owns its [TextEditingController], so the
/// controller is disposed only after the dialog has fully left the tree.
/// (Disposing it right after `showDialog` returns, while the close animation
/// is still building the text field, throws "used after being disposed".)
///
/// Pops `(remove, value)`; null means the user cancelled.
class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    required this.initialText,
    required this.validate,
    this.allowRemove = false,
  });

  final String title;
  final String initialText;
  final String? Function(String?) validate;
  final bool allowRemove;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final error = widget.validate(_controller.text);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.of(context).pop((false, ProgressData.parseNumber(_controller.text)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        decoration: InputDecoration(suffixText: 'kg', errorText: _errorText),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (widget.allowRemove)
          TextButton(
            onPressed: () => Navigator.of(context).pop((true, null)),
            child: const Text('Remove'),
          ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
