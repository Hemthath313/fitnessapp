import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PlateCalculatorSheet extends StatefulWidget {
  final double initialWeight;
  final bool initialIsKg;
  final ValueChanged<double>? onWeightApplied;

  const PlateCalculatorSheet({
    super.key,
    this.initialWeight = 60.0,
    this.initialIsKg = true,
    this.onWeightApplied,
  });

  static Future<void> show(
    BuildContext context, {
    double initialWeight = 60.0,
    bool initialIsKg = true,
    ValueChanged<double>? onWeightApplied,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PlateCalculatorSheet(
        initialWeight: initialWeight,
        initialIsKg: initialIsKg,
        onWeightApplied: onWeightApplied,
      ),
    );
  }

  /// Evaluates whether an exercise uses a barbell where plate math is meaningful.
  /// Safely excludes bodyweight, dumbbell, machine, cable, and cardio movements.
  static bool isBarbellExercise({
    required String name,
    String? equipment,
  }) {
    final cleanName = name.trim().toLowerCase();
    final cleanEquip = (equipment ?? '').trim().toLowerCase();

    // 1. Explicit Exclusions: Non-barbell modalities
    if (cleanName.contains('dumbbell') ||
        cleanEquip.contains('dumbbell') ||
        cleanName.contains('kettlebell') ||
        cleanEquip.contains('kettlebell') ||
        cleanName.contains('bodyweight') ||
        cleanEquip.contains('bodyweight') ||
        cleanName.contains('cable') ||
        cleanEquip.contains('cable') ||
        cleanName.contains('machine') ||
        cleanEquip.contains('machine') ||
        cleanName.contains('band') ||
        cleanEquip.contains('band') ||
        cleanName.contains('running') ||
        cleanName.contains('walk') ||
        cleanName.contains('cycling') ||
        cleanName.contains('jump') ||
        cleanName.contains('push-up') ||
        cleanName.contains('push up') ||
        cleanName.contains('pull-up') ||
        cleanName.contains('pull up') ||
        cleanName.contains('chin-up') ||
        cleanName.contains('chin up') ||
        cleanName.contains('dip') ||
        cleanName.contains('crunch') ||
        cleanName.contains('plank')) {
      return false;
    }

    // 2. Equipment check
    if (cleanEquip.contains('barbell') ||
        cleanEquip.contains('ez bar') ||
        cleanEquip.contains('olympic bar')) {
      return true;
    }

    // 3. Name check for explicit "barbell" or "ez bar"
    if (cleanName.contains('barbell') ||
        cleanName.contains('ez bar') ||
        cleanName.contains('olympic bar')) {
      return true;
    }

    // 4. Recognized standard barbell lifts
    final standardBarbellLifts = [
      'deadlift',
      'bench press',
      'overhead press',
      'military press',
      'back squat',
      'front squat',
      'clean and jerk',
      'power clean',
      'power snatch',
      'snatch',
      'pendlay row',
      'hip thrust',
      'good morning',
      'zercher squat',
    ];

    for (final lift in standardBarbellLifts) {
      if (cleanName.contains(lift)) {
        return true;
      }
    }

    return false;
  }

  /// Calculates the Olympic/standard plates required per side.
  static Map<double, int> calculatePlatesPerSide({
    required double targetWeight,
    required double barWeight,
    required bool isKg,
  }) {
    final Map<double, int> plateCounts = {};
    if (targetWeight <= barWeight) return plateCounts;

    double remainingWeightPerSide = (targetWeight - barWeight) / 2.0;
    final plates = isKg ? _kgPlates : _lbPlates;

    for (final plate in plates) {
      if (remainingWeightPerSide >= plate) {
        final count = (remainingWeightPerSide / plate).floor();
        if (count > 0) {
          plateCounts[plate] = count;
          remainingWeightPerSide -= count * plate;
          // Clean up floating precision
          remainingWeightPerSide =
              double.parse(remainingWeightPerSide.toStringAsFixed(3));
        }
      }
    }
    return plateCounts;
  }

  // Standard Olympic Plates in kg
  static const List<double> _kgPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
  // Standard Olympic Plates in lbs
  static const List<double> _lbPlates = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5];

  @override
  State<PlateCalculatorSheet> createState() => _PlateCalculatorSheetState();
}

class _PlateCalculatorSheetState extends State<PlateCalculatorSheet> {
  late double _targetWeight;
  late double _barWeight;
  late bool _isKg;

  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _isKg = widget.initialIsKg;
    _barWeight = _isKg ? 20.0 : 45.0;
    _targetWeight = widget.initialWeight > 0
        ? widget.initialWeight
        : (_isKg ? 60.0 : 135.0);
    if (_targetWeight < _barWeight) _targetWeight = _barWeight;
    _weightController = TextEditingController(text: _formatWeight(_targetWeight));
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  String _formatWeight(double w) {
    return w % 1 == 0 ? w.toInt().toString() : w.toStringAsFixed(1);
  }

  void _updateWeight(double newWeight) {
    if (newWeight < _barWeight) newWeight = _barWeight;
    setState(() {
      _targetWeight = newWeight;
      _weightController.text = _formatWeight(_targetWeight);
    });
  }

  // Calculate plates required per side
  Map<double, int> _calculatePlatesPerSide() {
    return PlateCalculatorSheet.calculatePlatesPerSide(
      targetWeight: _targetWeight,
      barWeight: _barWeight,
      isKg: _isKg,
    );
  }

  Color _getPlateColor(double plate) {
    if (_isKg) {
      switch (plate.toString()) {
        case '25.0':
          return const Color(0xFFE53935); // Red
        case '20.0':
          return const Color(0xFF1E88E5); // Blue
        case '15.0':
          return const Color(0xFFFDD835); // Yellow
        case '10.0':
          return const Color(0xFF43A047); // Green
        case '5.0':
          return const Color(0xFFECEFF1); // White
        case '2.5':
          return const Color(0xFF424242); // Black
        case '1.25':
          return const Color(0xFF90A4AE); // Silver
        default:
          return ColorManager.primary;
      }
    } else {
      switch (plate.toString()) {
        case '45.0':
          return const Color(0xFF1E88E5); // Blue
        case '35.0':
          return const Color(0xFFFDD835); // Yellow
        case '25.0':
          return const Color(0xFF43A047); // Green
        case '10.0':
          return const Color(0xFF424242); // Black
        case '5.0':
          return const Color(0xFFECEFF1); // White
        case '2.5':
          return const Color(0xFF90A4AE); // Silver
        default:
          return ColorManager.primary;
      }
    }
  }

  double _getPlateHeight(double plate) {
    if (_isKg) {
      if (plate >= 20) return 96.h;
      if (plate == 15) return 86.h;
      if (plate == 10) return 74.h;
      if (plate == 5) return 60.h;
      if (plate == 2.5) return 50.h;
      return 42.h;
    } else {
      if (plate >= 45) return 96.h;
      if (plate == 35) return 86.h;
      if (plate == 25) return 74.h;
      if (plate == 10) return 60.h;
      return 46.h;
    }
  }

  double _getPlateWidth(double plate) {
    if (plate >= 20 || plate >= 45) return 22.w;
    if (plate >= 15 || plate >= 35) return 18.w;
    if (plate >= 10 || plate >= 25) return 16.w;
    return 13.w;
  }

  @override
  Widget build(BuildContext context) {
    final platesPerSide = _calculatePlatesPerSide();
    final weightPerSide = (_targetWeight - _barWeight) / 2.0;

    return Container(
      decoration: BoxDecoration(
        color: ColorManager.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 16.h,
        left: 20.w,
        right: 20.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 44.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: ColorManager.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.fitness_center_rounded, color: ColorManager.primary, size: 20.sp),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Barbell Plate Math',
                              style: TextStyle(
                                color: ColorManager.textPrimary,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Visual Olympic plate calculator per side',
                              style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(tooltip: 'Close', 
                  key: const Key('plate_calculator_close_button'),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // 2D Visual Barbell Display
            _buildVisualBarbell(platesPerSide),
            SizedBox(height: 16.h),

            // Breakdown Summary Card
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: ColorManager.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: ColorManager.divider.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _buildStatItem('Total Weight', '${_formatWeight(_targetWeight)} ${_isKg ? 'kg' : 'lbs'}', ColorManager.primary)),
                  Container(height: 30.h, width: 1, color: Colors.white12),
                  Expanded(child: _buildStatItem('Bar Weight', '${_formatWeight(_barWeight)} ${_isKg ? 'kg' : 'lbs'}', Colors.white70)),
                  Container(height: 30.h, width: 1, color: Colors.white12),
                  Expanded(child: _buildStatItem('Per Side', '${_formatWeight(weightPerSide > 0 ? weightPerSide : 0)} ${_isKg ? 'kg' : 'lbs'}', Colors.amberAccent)),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Plate count breakdown pills
            if (platesPerSide.isNotEmpty) ...[
              Text(
                'Plates Per Side (Inside → Outside):',
                style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: platesPerSide.entries.map((entry) {
                  final color = _getPlateColor(entry.key);
                  final isLightColor = entry.key == 5.0 && _isKg;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: color, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${entry.value} × ${_formatWeight(entry.key)} ${_isKg ? 'kg' : 'lb'}',
                          style: TextStyle(
                            color: isLightColor ? Colors.white : color,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.h),
            ],

            // Target Weight Input & Controls
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColorManager.textPrimary, fontSize: 24.sp, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Total Target Weight',
                      labelStyle: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
                      suffixText: _isKg ? 'kg' : 'lbs',
                      suffixStyle: TextStyle(color: ColorManager.primary, fontWeight: FontWeight.bold, fontSize: 16.sp),
                      filled: true,
                      fillColor: ColorManager.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: ColorManager.primary, width: 2)),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed >= _barWeight) {
                        setState(() {
                          _targetWeight = parsed;
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                // kg / lbs toggle
                Container(
                  decoration: BoxDecoration(
                    color: ColorManager.surface,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: ColorManager.divider.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      _buildUnitToggle(true, 'KG'),
                      _buildUnitToggle(false, 'LBS'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Quick Weight Modifier Buttons (-10, -2.5, +2.5, +5, +10)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickDeltaButton(-10, '-10'),
                _buildQuickDeltaButton(-2.5, '-2.5'),
                _buildQuickDeltaButton(2.5, '+2.5'),
                _buildQuickDeltaButton(5, '+5'),
                _buildQuickDeltaButton(10, '+10'),
              ],
            ),
            SizedBox(height: 16.h),

            // Bar selection chips
            Row(
              children: [
                Text('Bar:', style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                SizedBox(width: 8.w),
                _buildBarOption(_isKg ? 20.0 : 45.0, _isKg ? 'Olympic (20kg)' : 'Standard (45lb)'),
                SizedBox(width: 6.w),
                _buildBarOption(_isKg ? 15.0 : 35.0, _isKg ? 'Women (15kg)' : 'Women (35lb)'),
                SizedBox(width: 6.w),
                _buildBarOption(_isKg ? 10.0 : 25.0, _isKg ? 'EZ Bar (10kg)' : 'EZ Bar (25lb)'),
              ],
            ),
            SizedBox(height: 20.h),

            // Action Buttons
            if (widget.onWeightApplied != null)
              ElevatedButton.icon(
                key: const Key('plate_calculator_apply_button'),
                onPressed: () {
                  widget.onWeightApplied!(_targetWeight);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: Text('Apply ${_formatWeight(_targetWeight)} ${_isKg ? 'kg' : 'lbs'} to Set', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  elevation: 4,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualBarbell(Map<double, int> platesPerSide) {
    // Generate list of plates from inside to outside
    final List<double> platesList = [];
    platesPerSide.forEach((plate, count) {
      for (int i = 0; i < count; i++) {
        platesList.add(plate);
      }
    });

    return Container(
      height: 130.h,
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 20.w),
              // Bar Shaft (Left Center)
              Container(
                width: 60.w,
                height: 12.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF757575), Color(0xFFE0E0E0), Color(0xFF616161)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(4.r)),
                ),
              ),
              // Inside Collar / Flange
              Container(
                width: 14.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFBDBDBD),
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(color: Colors.white38, width: 1),
                ),
              ),

              // Stacked Plates (Loaded on the right of the collar)
              if (platesList.isEmpty)
                Container(
                  width: 140.w,
                  height: 22.h,
                  margin: EdgeInsets.only(left: 2.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF424242),
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(6.r)),
                  ),
                  child: Center(
                    child: Text(
                      'No Plates (Bar Only)',
                      style: TextStyle(color: Colors.white38, fontSize: 11.sp),
                    ),
                  ),
                )
              else
                ...platesList.map((plate) {
                  final color = _getPlateColor(plate);
                  final height = _getPlateHeight(plate);
                  final width = _getPlateWidth(plate);
                  final isLightColor = plate == 5.0 && _isKg;

                  return Container(
                    width: width,
                    height: height,
                    margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4.r),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          _formatWeight(plate),
                          style: TextStyle(
                            color: isLightColor ? Colors.black : Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

              // Bar Sleeve End
              Container(
                width: 24.w,
                height: 22.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9E9E9E), Color(0xFFE0E0E0), Color(0xFF757575)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(6.r)),
                ),
              ),
              SizedBox(width: 20.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, textAlign: TextAlign.center, style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp)),
        SizedBox(height: 4.h),
        Text(value, textAlign: TextAlign.center, style: TextStyle(color: valueColor, fontSize: 14.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildUnitToggle(bool isKg, String label) {
    final isSelected = _isKg == isKg;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_isKg != isKg) {
            _isKg = isKg;
            if (_isKg) {
              // Convert lbs to kg
              _barWeight = 20.0;
              _targetWeight = (_targetWeight / 2.20462).roundToDouble();
            } else {
              // Convert kg to lbs
              _barWeight = 45.0;
              _targetWeight = (_targetWeight * 2.20462).roundToDouble();
            }
            if (_targetWeight < _barWeight) _targetWeight = _barWeight;
            _weightController.text = _formatWeight(_targetWeight);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected ? ColorManager.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : ColorManager.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDeltaButton(double delta, String label) {
    return InkWell(
      onTap: () => _updateWeight(_targetWeight + delta),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: ColorManager.divider.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: delta > 0 ? ColorManager.primary : Colors.orangeAccent,
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildBarOption(double weight, String label) {
    final isSelected = _barWeight == weight;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _barWeight = weight;
            if (_targetWeight < _barWeight) {
              _targetWeight = _barWeight;
              _weightController.text = _formatWeight(_targetWeight);
            }
          });
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected ? ColorManager.primary.withValues(alpha: 0.2) : ColorManager.surface,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? ColorManager.primary : ColorManager.divider.withValues(alpha: 0.4),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? ColorManager.primary : ColorManager.textSecondary,
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
