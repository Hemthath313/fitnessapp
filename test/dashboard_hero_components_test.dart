import 'dart:io';

import 'package:fitness_app/presentation/home/widgets/gradient_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(430, 932),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('Hero image assets', () {
    const keys = [
      'chest',
      'back',
      'shoulders',
      'biceps',
      'triceps',
      'legs',
      'abs',
      'cardio',
    ];

    test('every body-part image used by hero cards exists on disk', () {
      for (final k in keys) {
        expect(File(HeroImages.forKey(k)).existsSync(), isTrue,
            reason: '${HeroImages.forKey(k)} is missing');
      }
    });

    test('hero image folder is declared in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('assets/images/anatomy_mint/'), isTrue,
          reason: 'images would not be bundled, so cards would show no image');
    });
  });

  group('Person image convention', () {
    test('person path is derived from the illustration path', () {
      expect(HeroImages.personForIllustration(HeroImages.forKey('chest')),
          'assets/images/hero/chest.png');
      expect(HeroImages.personForIllustration('assets/other/x.png'), isNull);
    });

    test('hero image folder exists and is declared in pubspec.yaml', () {
      expect(Directory('assets/images/hero').existsSync(), isTrue);
      expect(File('pubspec.yaml').readAsStringSync().contains(
          'assets/images/hero/'), isTrue);
    });
  });

  group('HeroImages.keyForPlan', () {
    test('every programme maps to an existing illustration', () {
      for (final id in [
        'beginner_fitness_30',
        'weight_loss_60',
        'muscle_building_90',
        'strength_12_week',
        'unknown_plan',
      ]) {
        final key = HeroImages.keyForPlan(id);
        expect(File(HeroImages.forKey(key)).existsSync(), isTrue,
            reason: 'no image for $id ($key)');
      }
    });
  });

  group('HeroImages.forGoal', () {
    test('maps common goals to a matching image', () {
      expect(HeroImages.forGoal('Lose weight'), HeroImages.forKey('cardio'));
      expect(HeroImages.forGoal('Fat loss'), HeroImages.forKey('cardio'));
      expect(HeroImages.forGoal('Build strength'), HeroImages.forKey('back'));
      expect(HeroImages.forGoal('Tone up'), HeroImages.forKey('abs'));
    });

    test('falls back to chest for muscle goals, null and empty', () {
      expect(HeroImages.forGoal('Build muscle'), HeroImages.forKey('chest'));
      expect(HeroImages.forGoal(null), HeroImages.forKey('chest'));
      expect(HeroImages.forGoal(''), HeroImages.forKey('chest'));
    });
  });

  group('GradientHeroCard', () {
    testWidgets('renders its child and falls back to the illustration',
        (tester) async {
      await tester.pumpWidget(_wrap(
        GradientHeroCard(
          imageAsset: HeroImages.forKey('legs'),
          child: const Text('Leg day'),
        ),
      ));
      // Person photo is optional; when it is absent the illustration shows.
      await tester.pumpAndSettle();

      expect(find.text('Leg day'), findsOneWidget);

      final illustration = find.byWidgetPredicate((w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == HeroImages.forKey('legs'));
      expect(illustration, findsOneWidget);
    });

    testWidgets('uses a different gradient for each tone', (tester) async {
      Future<List<Color>> colorsFor(HeroTone tone) async {
        await tester.pumpWidget(_wrap(
          GradientHeroCard(
            tone: tone,
            imageAsset: HeroImages.forKey('chest'),
            child: const SizedBox(height: 40),
          ),
        ));
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GradientHeroCard),
            matching: find.byType(Container),
          ).first,
        );
        final gradient =
            (container.decoration as BoxDecoration).gradient as LinearGradient;
        return gradient.colors;
      }

      final teal = await colorsFor(HeroTone.teal);
      final coral = await colorsFor(HeroTone.coral);
      final green = await colorsFor(HeroTone.green);

      expect(teal, isNot(equals(coral)));
      expect(teal, isNot(equals(green)));
      expect(coral, isNot(equals(green)));
    });

    testWidgets('does not break the layout if the image is missing',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const GradientHeroCard(
          imageAsset: 'assets/images/does_not_exist.png',
          child: Text('Still visible'),
        ),
      ));
      await tester.pump();

      expect(find.text('Still visible'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('HeroBadge and HeroMetaChip', () {
    testWidgets('show their text', (tester) async {
      await tester.pumpWidget(_wrap(
        const Column(
          children: [
            HeroBadge(text: 'AI WORKOUT ROUTINE', icon: Icons.auto_awesome),
            HeroMetaChip(icon: Icons.timer_outlined, text: '~45 min'),
          ],
        ),
      ));

      expect(find.text('AI WORKOUT ROUTINE'), findsOneWidget);
      expect(find.text('~45 min'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });
  });

  test('six-pack and weekly technique cards use photos that exist on disk', () {
    expect(File(HeroImages.sixPackPhoto).existsSync(), isTrue);
    expect(File(HeroImages.weeklyTechniquePhoto).existsSync(), isTrue);
  });

  test('muscle building programme has a banner photo that exists on disk', () {
    final path = HeroImages.photoForPlan('muscle_building_90');
    expect(path, isNotNull);
    expect(File(path!).existsSync(), isTrue);
    final wl = HeroImages.photoForPlan('weight_loss_60');
    expect(wl, isNotNull);
    expect(File(wl!).existsSync(), isTrue);
    final strength = HeroImages.photoForPlan('strength_12_week');
    expect(strength, isNotNull);
    expect(File(strength!).existsSync(), isTrue);
    final beginner = HeroImages.photoForPlan('beginner_fitness_30');
    expect(beginner, isNotNull);
    expect(File(beginner!).existsSync(), isTrue);
    // Programmes without a photo fall back to the illustration.
    expect(HeroImages.photoForPlan('unknown_plan'), isNull);
  });

  test('every programme maps to a card colour', () {
    expect(HeroImages.toneForPlan('beginner_fitness_30'), HeroTone.green);
    expect(HeroImages.toneForPlan('weight_loss_60'), HeroTone.coral);
    expect(HeroImages.toneForPlan('muscle_building_90'), HeroTone.teal);
    expect(HeroImages.toneForPlan('strength_12_week'), HeroTone.purple);
  });
}
