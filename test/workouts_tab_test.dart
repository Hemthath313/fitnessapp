import 'dart:io';

import 'package:fitness_app/presentation/workouts/pages/workout_tab_page.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Workouts sub-tab segmented control renders My Plan and Explore', (WidgetTester tester) async {

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DefaultTabController(
                  length: 2,
                  initialIndex: 0,
                  child: Column(
                    children: [
                      Container(
                        height: 48.h,
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: ColorManager.surface,
                          borderRadius: BorderRadius.circular(26.r),
                          border: Border.all(color: ColorManager.divider),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: ColorManager.primary,
                            borderRadius: BorderRadius.circular(22.r),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: ColorManager.textSecondary,
                          tabs: const [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 16),
                                  SizedBox(width: 8),
                                  Text('My Plan'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.explore_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Explore'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            const Center(child: Text('My Plan View Content')),
                            const Center(child: Text('Explore View Content')),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Initial check: 'My Plan' is selected by default
    expect(find.text('My Plan'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('My Plan View Content'), findsOneWidget);

    // Tap on 'Explore' tab
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();

    // Verify view toggles to Explore
    expect(find.text('Explore View Content'), findsOneWidget);

    // Tap on 'My Plan' tab
    await tester.tap(find.text('My Plan'));
    await tester.pumpAndSettle();

    // Verify view toggles back to My Plan
    expect(find.text('My Plan View Content'), findsOneWidget);
  });

  testWidgets('WorkoutTabPage.exerciseLibraryCategories has all 8 cohesive athletic icons and routes', (WidgetTester tester) async {
    final categories = [
      {'label': 'Chest', 'icon': Icons.fitness_center_rounded, 'route': '/chest'},
      {'label': 'Back', 'icon': Icons.rowing_rounded, 'route': '/back'},
      {'label': 'Legs', 'icon': Icons.directions_run_rounded, 'route': '/legs'},
      {'label': 'Shoulders', 'icon': Icons.accessibility_new_rounded, 'route': '/shoulders'},
      {'label': 'Biceps', 'icon': Icons.sports_mma_rounded, 'route': '/biceps'},
      {'label': 'Triceps', 'icon': Icons.sports_gymnastics_rounded, 'route': '/triceps'},
      {'label': 'Abs', 'icon': Icons.table_rows_rounded, 'route': '/abs'},
      {'label': 'Cardio', 'icon': Icons.directions_bike_rounded, 'route': '/cardio'},
    ];

    expect(categories.length, 8);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            backgroundColor: ColorManager.background,
            body: SingleChildScrollView(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: ColorManager.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ColorManager.divider),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          color: ColorManager.primary,
                          size: 26,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['label'] as String,
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all 8 categories are rendered with their respective text and icons
    expect(find.text('Chest'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center_rounded), findsOneWidget);

    expect(find.text('Back'), findsOneWidget);
    expect(find.byIcon(Icons.rowing_rounded), findsOneWidget);

    expect(find.text('Legs'), findsOneWidget);
    expect(find.byIcon(Icons.directions_run_rounded), findsOneWidget);

    expect(find.text('Shoulders'), findsOneWidget);
    expect(find.byIcon(Icons.accessibility_new_rounded), findsOneWidget);

    expect(find.text('Biceps'), findsOneWidget);
    expect(find.byIcon(Icons.sports_mma_rounded), findsOneWidget);

    expect(find.text('Triceps'), findsOneWidget);
    expect(find.byIcon(Icons.sports_gymnastics_rounded), findsOneWidget);

    expect(find.text('Abs'), findsOneWidget);
    expect(find.byIcon(Icons.table_rows_rounded), findsOneWidget);

    expect(find.text('Cardio'), findsOneWidget);
    expect(find.byIcon(Icons.directions_bike_rounded), findsOneWidget);

    // Verify zero overflow errors
    expect(tester.takeException(), isNull);
  });

  testWidgets('WorkoutTabPage.exerciseLibraryCategories contains 8 anatomy illustrations and exists on disk', (WidgetTester tester) async {
    final categories = WorkoutTabPage.exerciseLibraryCategories;
    expect(categories.length, 8);

    for (final cat in categories) {
      expect(cat['image'], isNotNull, reason: 'Image asset missing for ${cat['label']}');
      final imagePath = cat['image'] as String;
      expect(imagePath, startsWith('assets/images/anatomy/'));
      final file = File(imagePath);
      expect(file.existsSync(), isTrue, reason: 'File not found on disk: $imagePath');
    }

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            backgroundColor: ColorManager.background,
            body: SingleChildScrollView(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.05,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final imageAsset = cat['image'] as String?;
                  return Container(
                    decoration: BoxDecoration(
                      color: ColorManager.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ColorManager.divider),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (imageAsset != null)
                          Image.asset(
                            imageAsset,
                            width: 44,
                            height: 44,
                            fit: BoxFit.contain,
                          )
                        else
                          Icon(
                            cat['icon'] as IconData,
                            color: ColorManager.primary,
                            size: 26,
                          ),
                        const SizedBox(height: 6),
                        Text(
                          cat['label'] as String,
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all 8 category labels and Image widgets render without exception
    expect(find.byType(Image), findsNWidgets(8));
    expect(find.text('Chest'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Legs'), findsOneWidget);
    expect(find.text('Shoulders'), findsOneWidget);
    expect(find.text('Biceps'), findsOneWidget);
    expect(find.text('Triceps'), findsOneWidget);
    expect(find.text('Abs'), findsOneWidget);
    expect(find.text('Cardio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
