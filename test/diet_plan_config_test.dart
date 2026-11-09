import 'dart:convert';
import 'dart:io';

import 'package:fitness_app/presentation/diet_nutrition/diet_plan_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Bulking / Cutting / Maintain screens are one [DietPlanScreen] driven by
/// a [DietPlanConfig]. These guard the data each config points at.
void main() {
  const configs = {
    'bulking': DietPlanConfig.bulking,
    'cutting': DietPlanConfig.cutting,
    'maintain': DietPlanConfig.maintain,
  };

  configs.forEach((name, config) {
    group('DietPlanConfig.$name', () {
      test('has a title', () {
        expect(config.title, isNotEmpty);
      });

      test('points at a meal plan JSON with the expected shape', () {
        final file = File('assets/json/${config.assetFile}');
        expect(file.existsSync(), isTrue, reason: '${config.assetFile} exists');

        final data = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(data['meals'], isA<List>());
        expect((data['meals'] as List), isNotEmpty);
        expect(data['mealLibrary'], isA<List>());
        expect(data['dailySummary'], isA<Map>());

        for (final meal in data['meals'] as List) {
          final m = meal as Map<String, dynamic>;
          expect(m['name'], isA<String>());
          for (final key in ['calories', 'protein', 'carbs', 'fats']) {
            expect(m[key], isA<num>(), reason: '${m['name']} has numeric $key');
          }
        }
      });
    });
  });

  test('the three plans use different meal files and titles', () {
    expect(configs.values.map((c) => c.assetFile).toSet().length, 3);
    expect(configs.values.map((c) => c.title).toSet().length, 3);
  });
}
