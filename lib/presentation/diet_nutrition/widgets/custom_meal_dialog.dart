import 'package:fitness_app/utils/managers/app_font.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A validated custom meal entered by the user (whole numbers).
class CustomMealInput {
  const CustomMealInput({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
}

/// Shows the "Add Custom Meal" dialog. Returns null when cancelled.
Future<CustomMealInput?> showCustomMealDialog(BuildContext context) {
  return showDialog<CustomMealInput>(
    context: context,
    builder: (_) => const _CustomMealDialog(),
  );
}

/// Validation helpers, public so they can be unit tested.
class CustomMealValidation {
  const CustomMealValidation._();

  static const int maxCalories = 5000;
  static const int maxMacroGrams = 500;

  static String? name(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Give the meal a name';
    if (t.length > 40) return 'Keep the name under 40 characters';
    return null;
  }

  static String? calories(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null) return 'Enter the calories';
    if (n <= 0) return 'Must be more than 0';
    if (n > maxCalories) return 'Must be $maxCalories or less';
    return null;
  }

  /// Macros are optional; decimals such as 12.5 are accepted.
  static String? macro(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = double.tryParse(t);
    if (n == null) return 'Invalid number';
    if (n < 0 || n > maxMacroGrams) return '0 to $maxMacroGrams g';
    return null;
  }

  /// Parses an optional macro field to whole grams (12.5 -> 13, empty -> 0).
  static int grams(String? v) => (double.tryParse(v?.trim() ?? '') ?? 0).round();
}

class _CustomMealDialog extends StatefulWidget {
  const _CustomMealDialog();

  @override
  State<_CustomMealDialog> createState() => _CustomMealDialogState();
}

class _CustomMealDialogState extends State<_CustomMealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fats = TextEditingController();

  static final _decimal =
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}'));

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fats.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      CustomMealInput(
        name: _name.text.trim(),
        calories: int.parse(_calories.text.trim()),
        protein: CustomMealValidation.grams(_protein.text),
        carbs: CustomMealValidation.grams(_carbs.text),
        fats: CustomMealValidation.grams(_fats.text),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    required String? Function(String?) validator,
    bool numeric = false,
    bool decimal = false,
    String? suffix,
    TextInputAction action = TextInputAction.next,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        key: Key('custom_meal_${label.toLowerCase().split(' ').first}'),
        controller: c,
        validator: validator,
        textInputAction: action,
        keyboardType: numeric
            ? TextInputType.numberWithOptions(decimal: decimal)
            : TextInputType.text,
        textCapitalization:
            numeric ? TextCapitalization.none : TextCapitalization.sentences,
        inputFormatters: numeric
            ? [decimal ? _decimal : FilteringTextInputFormatter.digitsOnly]
            : null,
        style: TextStyle(color: ColorManager.textPrimary),
        decoration: InputDecoration(labelText: label, suffixText: suffix),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorManager.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Text(
        'Add Custom Meal',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppType.headline,
          fontWeight: FontWeight.bold,
          color: ColorManager.primaryText,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_name, 'Meal Name', validator: CustomMealValidation.name),
              _field(_calories, 'Calories',
                  validator: CustomMealValidation.calories,
                  numeric: true,
                  suffix: 'kcal'),
              _field(_protein, 'Protein (g)',
                  validator: CustomMealValidation.macro,
                  numeric: true,
                  decimal: true),
              _field(_carbs, 'Carbs (g)',
                  validator: CustomMealValidation.macro,
                  numeric: true,
                  decimal: true),
              _field(_fats, 'Fats (g)',
                  validator: CustomMealValidation.macro,
                  numeric: true,
                  decimal: true,
                  action: TextInputAction.done),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: ColorManager.textSecondary),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('custom_meal_add_button'),
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorManager.primary,
            foregroundColor: ColorManager.onMint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
