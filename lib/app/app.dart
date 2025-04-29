import 'package:fitness_app/presentation/chat_screen/provider/chat_provider.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/profile/providers/profile_provider.dart';
import 'package:fitness_app/presentation/settings/providers/settings_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/router/router.dart'; // import the GoRouter setup
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../presentation/auth/providers/auth_provider.dart';

class MyApp extends StatefulWidget {
  MyApp._internal();
  int appState = 0;
  static final MyApp instance = MyApp._internal();

  factory MyApp() => instance;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: AuthProvider(),
        ),
        ChangeNotifierProvider.value(
          value: SettingsProvider(),
        ),
        ChangeNotifierProvider.value(
          value: HomeProvider(),
        ),
        ChangeNotifierProvider.value(
          value: WorkoutProvider(),
        ),
        ChangeNotifierProvider.value(
          value: ConsumptionProvider(),
        ),
        ChangeNotifierProvider.value(
          value: ProfileProvider(),
        ),
        ChangeNotifierProvider.value(
          value: ChatProvider(),
        ),
      ],
      child: ScreenUtilInit(
        builder: (context, child) => MaterialApp.router(
          theme: ThemeData(),
          debugShowCheckedModeBanner: false,
          routerConfig: router, // Pass the GoRouter instance here
        ),
        designSize: const Size(430, 810),
      ),
    );
  }
}
