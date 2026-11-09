import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/consumption/widgets/quick_water_add_button.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/widgets/fitness_data_widget.dart';
import 'package:fitness_app/utils/managers/app_font.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/widgets/lime_green_rounded_button.dart';
import 'package:fitness_app/utils/widgets/text_field_widget.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class DrinkPage extends StatefulWidget {
  const DrinkPage({super.key});

  @override
  State<DrinkPage> createState() => _DrinkPageState();
}

class _DrinkPageState extends State<DrinkPage> {
  final TextEditingController _drinkController = TextEditingController();

  @override
  void dispose() {
    _drinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consumptionProvider =
        Provider.of<ConsumptionProvider>(context, listen: false);
    // Water is stored in liters. Validates, saves, and always reports a
    // failure to the user instead of throwing out of a button handler.
    Future<void> addWaterAmount(double? amount) async {
      if (amount == null || amount < 0.05 || amount > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter an amount between 0.05 and 5 liters.'),
          ),
        );
        return;
      }
      final userData =
          Provider.of<HomeProvider?>(context, listen: false)?.userData ??
              const <String, dynamic>{};
      final goalLiters = FitnessDataWidget.resolveWaterGoal(
        context: context,
        consumptionProvider: consumptionProvider,
        userData: userData,
      );
      LoadingOverlay.show(context, message: 'Adding water...');
      try {
        await consumptionProvider.addWater(
          amount: amount,
          dateTime: DateTime.now(),
          goalLiters: goalLiters,
        );
        if (context.mounted) {
          LoadingOverlay.hide(context);
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          LoadingOverlay.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not add water. Please try again.'),
            ),
          );
        }
      }
    }

    addCustomWater() =>
        addWaterAmount(double.tryParse(_drinkController.text.trim()));

    addFixedWater({required double amount}) => addWaterAmount(amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          StringsManager.drinkPageHeadLine,
          style: StyleManager.abTitleTextStyle,
        ),
        elevation: 0.0,
        backgroundColor: ColorManager.background,
        leading: Padding(
          padding: const EdgeInsets.only(left: PaddingManager.p12),
          child: Container(
            height: SizeManager.s40.h,
            width: SizeManager.s40.w,
            decoration: BoxDecoration(
              color: ColorManager.grey3,
              borderRadius: BorderRadius.circular(
                RadiusManager.r40.r,
              ),
            ),
            child: IconButton(tooltip: 'Back', 
              splashColor: ColorManager.grey3,
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon:  Icon(
                Icons.arrow_back_ios_new,
                size: SizeManager.s26,
                color: ColorManager.white,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: ColorManager.background,
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: SizedBox(
                  height: SizeManager.s300.h,
                  child: Lottie.asset(
                    AnimationManager.water,
                  ),
                ),
              ),
              const _WaterSummary(),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: PaddingManager.p28,
                    bottom: PaddingManager.p12,
                  ),
                  child: Text(
                    StringsManager.quickAdd,
                    style: StyleManager.drinkPageSpacerTextStyle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: PaddingManager.p12,
                  right: PaddingManager.p12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    QuickWaterAddButton(
                      label: StringsManager.l02,
                      addWater: () {
                        addFixedWater(amount: 0.2);
                      },
                    ),
                    QuickWaterAddButton(
                      label: StringsManager.l05,
                      addWater: () {
                        addFixedWater(amount: 0.5);
                      },
                    ),
                    QuickWaterAddButton(
                      label: StringsManager.l1,
                      addWater: () {
                        addFixedWater(amount: 1.0);
                      },
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: PaddingManager.p28,
                    bottom: PaddingManager.p12,
                    top: PaddingManager.p28,
                  ),
                  child: Text(
                    StringsManager.customAdd,
                    style: StyleManager.drinkPageSpacerTextStyle,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                child: TextFieldWidget(
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  controller: _drinkController,
                  labelHint: StringsManager.waterHint,
                  obscureText: false,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              LimeGreenRoundedButtonWidget(
                onTap: addCustomWater,
                title: StringsManager.add,
              )
            ],
          ),
        ),
      ),
    );
  }
}


/// Today's water total, the daily goal (editable) and an undo for a mis-tap.
/// Water is stored and shown in liters.
class _WaterSummary extends StatelessWidget {
  const _WaterSummary();

  Future<void> _editGoal(
    BuildContext context,
    ConsumptionProvider provider,
    double current,
  ) async {
    final controller = TextEditingController(text: current.toStringAsFixed(1));
    final value = await showDialog<double>(
      context: context,
      builder: (c) {
        String? error;
        return StatefulBuilder(
          builder: (c, setState) => AlertDialog(
            backgroundColor: ColorManager.surface,
            title: Text('Daily water goal',
                style: TextStyle(color: ColorManager.textPrimary)),
            content: TextField(
              key: const Key('water_goal_field'),
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: TextStyle(color: ColorManager.textPrimary),
              decoration: InputDecoration(
                suffixText: 'liters',
                errorText: error,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Cancel'),
              ),
              TextButton(
                key: const Key('water_goal_save'),
                onPressed: () {
                  final v = double.tryParse(controller.text.trim());
                  if (v == null || v < 0.5 || v > 10) {
                    setState(() => error = 'Enter 0.5 to 10 liters');
                    return;
                  }
                  Navigator.pop(c, v);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (value == null || !context.mounted) return;
    try {
      await provider.saveWaterGoal(value);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your goal. Please try again.')),
      );
    }
  }

  Future<void> _undo(
    BuildContext context,
    ConsumptionProvider provider,
    double goal,
  ) async {
    try {
      final removed = await provider.undoLastWater(goalLiters: goal);
      if (!context.mounted || removed == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${removed.toStringAsFixed(2)} L')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not undo. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ConsumptionProvider>(context);
    final userData =
        Provider.of<HomeProvider?>(context, listen: false)?.userData ??
            const <String, dynamic>{};
    final goal = FitnessDataWidget.resolveWaterGoal(
      context: context,
      consumptionProvider: provider,
      userData: userData,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today',
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: AppType.caption,
                  ),
                ),
                Text(
                  '${provider.waterADay.toStringAsFixed(2)} / ${goal.toStringAsFixed(1)} L',
                  key: const Key('water_summary_text'),
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: AppType.title,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('water_undo_button'),
            onPressed: provider.water.isEmpty
                ? null
                : () => _undo(context, provider, goal),
            child: const Text('Undo last'),
          ),
          IconButton(
            key: const Key('water_goal_edit'),
            tooltip: 'Edit daily goal',
            onPressed: () => _editGoal(context, provider, goal),
            icon: Icon(Icons.edit_outlined, color: ColorManager.primaryText),
          ),
        ],
      ),
    );
  }
}
