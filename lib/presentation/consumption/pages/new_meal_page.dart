import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/consumption/widgets/new_meal_app_bar.dart';
import 'package:fitness_app/presentation/diet_nutrition/widgets/pro_feature_gate.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class NewMealPage extends StatefulWidget {
  const NewMealPage({super.key});

  @override
  State<NewMealPage> createState() => _NewMealPageState();
}

class _NewMealPageState extends State<NewMealPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mealTitleController = TextEditingController();
  final TextEditingController _mealCalloriesController =
      TextEditingController();
  final TextEditingController _mealAmountController = TextEditingController();
  final TextEditingController _mealFatsController = TextEditingController();
  final TextEditingController _mealCarbsController = TextEditingController();
  final TextEditingController _mealProteinsController = TextEditingController();
  bool _saving = false;

  static final _decimal = FilteringTextInputFormatter.allow(
    RegExp(r'^\d*\.?\d{0,2}'),
  );

  @override
  void dispose() {
    _mealTitleController.dispose();
    _mealCalloriesController.dispose();
    _mealAmountController.dispose();
    _mealCarbsController.dispose();
    _mealFatsController.dispose();
    _mealProteinsController.dispose();
    super.dispose();
  }

  double _value(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  String? _requiredText(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Give the meal a name' : null;

  String? _requiredNumber(String? v, String label) {
    final t = v?.trim() ?? '';
    final n = double.tryParse(t);
    if (t.isEmpty) return 'Enter $label';
    if (n == null || n <= 0) return 'Must be more than 0';
    return null;
  }

  String? _optionalNumber(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    return double.tryParse(t) == null ? 'Invalid number' : null;
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final consumptionProvider =
        Provider.of<ConsumptionProvider>(context, listen: false);
    setState(() => _saving = true);
    LoadingOverlay.show(context, message: 'Adding meal...');
    try {
      await consumptionProvider.addNewMeal(
        title: _mealTitleController.text.trim(),
        amount: _value(_mealAmountController),
        calories: _value(_mealCalloriesController),
        fats: _value(_mealFatsController),
        carbs: _value(_mealCarbsController),
        proteins: _value(_mealProteinsController),
        dateTime: DateTime.now(),
      );
      if (!mounted) return;
      LoadingOverlay.hide(context);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      LoadingOverlay.hide(context);
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add the meal. Please try again.')),
      );
    }
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
      child: Text(
        text,
        style: TextStyle(
          color: ColorManager.textPrimary,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    // Logging meals is a Pro-only feature.
    return ProFeatureGate(
      child: Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(
          deviceWidth,
          SizeManager.s60.h,
        ),
        child: const NewMealPageAppBar(),
      ),
      backgroundColor: ColorManager.background,
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Meal'),
                _card(
                  children: [
                    _MealField(
                      controller: _mealTitleController,
                      label: StringsManager.mealNameHint,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      capitalization: TextCapitalization.sentences,
                      validator: _requiredText,
                    ),
                    SizedBox(height: 12.h),
                    _MealField(
                      controller: _mealAmountController,
                      label: StringsManager.mealAmountHint,
                      unit: 'g',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [_decimal],
                      validator: (v) => _requiredNumber(v, 'the amount'),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                _sectionLabel('Nutrition'),
                _card(
                  children: [
                    _MealField(
                      controller: _mealCalloriesController,
                      label: StringsManager.mealCaloriesHint,
                      unit: 'kcal',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => _requiredNumber(v, 'calories'),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _MealField(
                            controller: _mealProteinsController,
                            label: StringsManager.mealProteinsHint,
                            unit: 'g',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [_decimal],
                            validator: _optionalNumber,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _MealField(
                            controller: _mealCarbsController,
                            label: StringsManager.mealCarbsHint,
                            unit: 'g',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [_decimal],
                            validator: _optionalNumber,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _MealField(
                            controller: _mealFatsController,
                            label: StringsManager.mealFatsHint,
                            unit: 'g',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [_decimal],
                            textInputAction: TextInputAction.done,
                            validator: _optionalNumber,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        const Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(left: 4.w, top: 8.h),
                  child: Text(
                    'Protein, carbs and fats are optional.',
                    style: TextStyle(
                      color: ColorManager.textTertiary,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: ColorManager.onMint,
                      disabledBackgroundColor:
                          ColorManager.primary.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button.r),
                      ),
                    ),
                    child: Text(
                      'Add Meal',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: ColorManager.onMint,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// Labelled form field with an optional unit suffix and inline validation.
class _MealField extends StatelessWidget {
  const _MealField({
    required this.controller,
    required this.label,
    required this.keyboardType,
    this.unit,
    this.inputFormatters,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.capitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? unit;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final TextCapitalization capitalization;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textInputAction: textInputAction,
      textCapitalization: capitalization,
      autocorrect: false,
      cursorColor: ColorManager.primary,
      style: TextStyle(color: ColorManager.textPrimary, fontSize: 16.sp),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        suffixStyle: TextStyle(
          color: ColorManager.textSecondary,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: TextStyle(
          color: ColorManager.textSecondary,
          fontSize: 14.sp,
        ),
        floatingLabelStyle: TextStyle(
          color: ColorManager.primaryText,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: TextStyle(color: ColorManager.errorText, fontSize: 12.sp),
        filled: true,
        fillColor: ColorManager.background,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        enabledBorder: _border(Colors.transparent, 0),
        focusedBorder: _border(ColorManager.primary, 1.5),
        errorBorder: _border(ColorManager.error, 1),
        focusedErrorBorder: _border(ColorManager.error, 1.5),
      ),
    );
  }
}
