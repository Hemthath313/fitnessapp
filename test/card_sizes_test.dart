import 'package:fitness_app/presentation/body_parts/pages/body_parts.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
import 'package:fitness_app/utils/managers/card_size_manager.dart';
import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {double textScale = 1.0}) {
  return ScreenUtilInit(
    key: UniqueKey(),
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: c!,
      ),
      home: child,
    ),
  );
}

void main() {
  testWidgets('shelf height grows with text size but never shrinks below base',
      (tester) async {
    double? normal;
    double? large;
    double? small;

    await tester.pumpWidget(_app(Builder(builder: (context) {
      normal = AppCardSize.shelfHeight(context);
      return const SizedBox();
    })));
    await tester.pumpWidget(_app(Builder(builder: (context) {
      large = AppCardSize.shelfHeight(context);
      return const SizedBox();
    }), textScale: 1.3));
    await tester.pumpWidget(_app(Builder(builder: (context) {
      small = AppCardSize.shelfHeight(context);
      return const SizedBox();
    }), textScale: 0.8));

    expect(large!, greaterThan(normal!));
    expect(large! / normal!, closeTo(1.24, 0.01));
    expect(small, normal);
  });

  testWidgets('a challenge card is exactly the shelf height', (tester) async {
    await tester.pumpWidget(_app(
      Scaffold(
        body: Builder(
          builder: (context) => Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 300,
              child: CarouselHomeBox(
                title: 'Test challenge',
                subtitle: 'Short subtitle',
                actionText: 'Start',
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    final box = tester.getSize(find.byType(CarouselHomeBox));
    final context = tester.element(find.byType(CarouselHomeBox));
    expect(box.height, CarouselHomeBox.heightOf(context));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Body Focus grid uses the shared category tile proportions',
      (tester) async {
    await tester.pumpWidget(_app(const BodyPartsScreen()));
    await tester.pumpAndSettle();

    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(delegate.childAspectRatio, AppCardSize.gridAspectRatio);
    expect(find.text('Chest'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    // The page title follows the shared type scale.
    final title = tester.widget<Text>(find.text('Body Focus'));
    expect(title.style!.fontSize, AppText.pageTitle);
  });

  test('corner radius tokens step down from hero to small', () {
    expect(AppRadius.hero, greaterThan(AppRadius.card));
    expect(AppRadius.card, greaterThan(AppRadius.tile));
    expect(AppRadius.tile, greaterThan(AppRadius.button));
    expect(AppRadius.button, greaterThan(AppRadius.small));
  });

  testWidgets('type scale steps down from page title to caption', (tester) async {
    await tester.pumpWidget(_app(Builder(builder: (context) {
      expect(AppText.pageTitle, greaterThan(AppText.appBarTitle));
      expect(AppText.appBarTitle, greaterThan(AppText.sectionTitle));
      expect(AppText.sectionTitle, greaterThan(AppText.cardTitle));
      expect(AppText.cardTitle, greaterThan(AppText.body));
      expect(AppText.body, greaterThan(AppText.secondary));
      expect(AppText.secondary, greaterThan(AppText.caption));
      return const SizedBox();
    })));
    expect(AppSpacing.pageGutter, 20);
  });
}
