import 'package:fitness_app/presentation/auth/pages/add_data_page.dart';
import 'package:fitness_app/presentation/auth/pages/auth_page.dart';
import 'package:fitness_app/presentation/auth/pages/forgot_password_page.dart';
import 'package:fitness_app/presentation/auth/pages/login_or_register_page.dart';
import 'package:fitness_app/presentation/boarding/pages/boarding_page.dart';
import 'package:fitness_app/presentation/consumption/pages/drink_page.dart';
import 'package:fitness_app/presentation/consumption/pages/new_meal_page.dart';
import 'package:fitness_app/presentation/main/pages/main_page.dart';
import 'package:fitness_app/presentation/notifications/pages/notifications_page.dart';
import 'package:fitness_app/presentation/profile/pages/change_measurements_page.dart';
import 'package:fitness_app/presentation/profile/pages/change_weight_page.dart';
import 'package:fitness_app/presentation/settings/pages/change_email_page.dart';
import 'package:fitness_app/presentation/settings/pages/change_password_page.dart';
import 'package:fitness_app/presentation/settings/pages/delete_account_page.dart';
import 'package:fitness_app/presentation/workouts/pages/new_exercise_page.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/widgets/page_transition.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Routes {
  static const String boardingRoute = '/';
  static const String mainRoute = '/main';
  static const String loginRoute = '/login';
  static const String authRoute = '/auth';
  static const String notificationsRoute = '/notifications';
  static const String forgotPasswordRoute = '/forgotPassword';
  static const String changePasswordRoute = '/changePassword';
  static const String changeEmailRoute = '/changeEmail';
  static const String deleteAccRoute = '/deleteAcc';
  static const String newMealRoute = 'newMeal';
  static const String addDataRoute = '/addData';
  static const String addWaterRoute = '/addWater';
  static const String addNewExerciseRoute = '/addExercise';
  static const String changeWeightRoute = '/changeWeight';
  static const String changeMeasurementsRoute = '/changeMeasurements';
}

final GoRouter router = GoRouter(
  initialLocation: Routes.boardingRoute,
  routes: [
    GoRoute(
        path: Routes.boardingRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, BoardingPage())),
    GoRoute(
        path: Routes.mainRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, MainPage())),
    GoRoute(
        path: Routes.loginRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, LoginPage())),
    GoRoute(
        path: Routes.authRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, AuthPage())),
    GoRoute(
        path: Routes.notificationsRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, NotificationsPage())),
    GoRoute(
        path: Routes.forgotPasswordRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, ForgotPasswordPage())),
    GoRoute(
        path: Routes.changePasswordRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, ChangePasswordPage())),
    GoRoute(
        path: Routes.changeEmailRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, ChangeEmailPage())),
    GoRoute(
        path: Routes.deleteAccRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, DeleteAccountPage())),
    GoRoute(
        path: Routes.newMealRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, NewMealPage())),
    GoRoute(
        path: Routes.addDataRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, AddDataPage())),
    GoRoute(
        path: Routes.addWaterRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, DrinkPage())),
    GoRoute(
        path: Routes.addNewExerciseRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, NewExercisePage())),
    GoRoute(
        path: Routes.changeWeightRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, ChangeWeightPage())),
    GoRoute(
        path: Routes.changeMeasurementsRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, ChangeMeasurementsPage())),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(StringsManager.noRouteFound),
      ),
      body: const Center(
        child: Text(StringsManager.noRouteFound),
      ),
    );
  },
);
