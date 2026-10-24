import 'package:fitness_app/data/workout_splits_data.dart';
import 'package:fitness_app/presentation/auth/pages/add_data_page.dart';
import 'package:fitness_app/presentation/auth/pages/auth_page.dart';
import 'package:fitness_app/presentation/auth/pages/forgot_password_page.dart';
import 'package:fitness_app/presentation/auth/pages/login_or_register_page.dart';
import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/presentation/boarding/pages/boarding_page.dart';
import 'package:fitness_app/presentation/chat_screen/chat_screen.dart';
import 'package:fitness_app/presentation/in_app_purchases/premimum_screen.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/presentation/body_parts/pages/abs.dart';
import 'package:fitness_app/presentation/body_parts/pages/biceps.dart';
import 'package:fitness_app/presentation/body_parts/pages/body_parts.dart';
import 'package:fitness_app/presentation/body_parts/pages/chest.dart';
import 'package:fitness_app/presentation/body_parts/pages/lats.dart';
import 'package:fitness_app/presentation/body_parts/pages/legs.dart';
import 'package:fitness_app/presentation/body_parts/pages/shoulder.dart';
import 'package:fitness_app/presentation/body_parts/pages/triceps.dart';
import 'package:fitness_app/presentation/cardio_workouts/cardio.dart';
import 'package:fitness_app/presentation/challenges/30_days_sixpack.dart';
import 'package:fitness_app/presentation/challenges/daily_challenge.dart';
import 'package:fitness_app/presentation/consumption/pages/drink_page.dart';
import 'package:fitness_app/presentation/consumption/pages/new_meal_page.dart';
import 'package:fitness_app/presentation/diet_nutrition/bulking_diet.dart';
import 'package:fitness_app/presentation/diet_nutrition/cutting_diet/cutting_diet.dart';
import 'package:fitness_app/presentation/diet_nutrition/diet_main.dart';
import 'package:fitness_app/presentation/diet_nutrition/maintain_diet/maintain_diet.dart';
import 'package:fitness_app/presentation/email_verification/email_verify.dart';
import 'package:fitness_app/presentation/main/pages/main_page.dart';
import 'package:fitness_app/presentation/notifications/pages/notifications_page.dart';
import 'package:fitness_app/presentation/post_workout/recovery.dart';
import 'package:fitness_app/presentation/profile/pages/change_measurements_page.dart';
import 'package:fitness_app/presentation/profile/pages/change_weight_page.dart';
import 'package:fitness_app/presentation/settings/pages/change_email_page.dart';
import 'package:fitness_app/presentation/settings/pages/change_password_page.dart';
import 'package:fitness_app/presentation/settings/pages/delete_account_page.dart';
import 'package:fitness_app/presentation/splash_screen/splashscreen.dart';
import 'package:fitness_app/presentation/workout_splits/splits/bro_splits.dart';
import 'package:fitness_app/presentation/workout_splits/splits/full_body_split.dart';
import 'package:fitness_app/presentation/workout_splits/splits/ppl_splits.dart';
import 'package:fitness_app/presentation/workout_splits/splits/upper_lower_splits.dart';
import 'package:fitness_app/presentation/workout_splits/workout_splits.dart';
import 'package:fitness_app/presentation/workouts/pages/new_exercise_page.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/workout_logs/workout_log_screen.dart';
import 'package:fitness_app/presentation/workout_logs/workout_history_screen.dart';
import 'package:fitness_app/presentation/workout_logs/workout_session_detail_page.dart';
import 'package:fitness_app/presentation/custom_workouts/workout_session_launcher_page.dart';
import 'package:fitness_app/presentation/workout_logs/exercise_tracker_page.dart';
import 'package:fitness_app/presentation/workout_logs/strength_analytics_page.dart';
import 'package:fitness_app/presentation/progress_photos/progress_photos_screen.dart';
import 'package:fitness_app/presentation/progress_photos/add_progress_photo_screen.dart';
import 'package:fitness_app/presentation/progress_photos/photo_comparison_screen.dart';
import 'package:fitness_app/presentation/profile/pages/monthly_comparison_page.dart';
import 'package:fitness_app/presentation/diet_nutrition/pages/protein_chart_page.dart';
import 'package:fitness_app/presentation/progress/muscle_analytics_page.dart';
import 'package:fitness_app/presentation/challenges/exercise_of_the_week.dart';
import 'package:fitness_app/presentation/ai_coach/workout_generator_screen.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/widgets/coming_soon.dart';
import 'package:fitness_app/utils/widgets/page_transition.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Routes {
  static const String splashScreen = '/';
  static const String boardingRoute = '/boardingRoute';
  static const String mainRoute = '/main';
  static const String loginRoute = '/login';
  static const String authRoute = '/auth';
  static const String cardioRoute = '/cardio';
  static const String bodypartsPage = '/bodypartsPage';
  static const String notificationsRoute = '/notifications';
  static const String forgotPasswordRoute = '/forgotPassword';
  static const String changePasswordRoute = '/changePassword';
  static const String changeEmailRoute = '/changeEmail';
  static const String deleteAccRoute = '/deleteAcc';
  static const String newMealRoute = '/newMeal';
  static const String addDataRoute = '/addData';
  static const String addWaterRoute = '/addWater';
  static const String addNewExerciseRoute = '/addExercise';
  static const String changeWeightRoute = '/changeWeight';
  static const String changeMeasurementsRoute = '/changeMeasurements';
  static const String chestExerciseRoute = '/chestExercises';
  static const String bicepsRoute = '/bicepsExercises';
  static const String tricepsRoute = '/tricepsExercises';
  static const String shouldersRoute = '/shouldersExercises';
  static const String legsRoute = '/legsExercises';
  static const String absRoute = '/absExercises';
  static const String backRoute = '/backRoutes';
  static const String dietRoute = '/diet';
  static const String bulkingDietRoute = '/bulkingDietRoute';
  static const String cuttingDietRoute = '/cuttingDietRoute';
  static const String maintainDietRoute = '/maintainDietRoute';
  static const String sixPackChallengeRoute = '/sixPackChallenge';
  static const String dailyExerciseRoute = '/dailyExerciseRoute';
  static const String premiumScreen = '/premiumScreen';
  static const String workoutSplitsRoute = '/workoutSplitsRoute';
  static const String emailVerify = 'emailVerify';
  static const String broSplit = '/broSplit';
  static const String pushPullLegsSplit = '/pushPullLegsSplit';
  static const String fullBodySplit = '/fullBodySplit';
  static const String upperLowerSplit = '/upperLowerSplit';
  static const String recoveryRoute = '/recovery';
  static const String comingSoon = '/comingSoon';
  static const String workoutLogRoute = '/workoutLog';
  static const String workoutHistoryRoute = '/workoutHistory';
  static const String progressPhotosRoute = '/progressPhotos';
  static const String addProgressPhotoRoute = '/addProgressPhoto';
  static const String photoComparisonRoute = '/photoComparison';
  static const String plateauAnalysisRoute = '/plateauAnalysis';
  static const String aiChatRoute = '/aiChat';
  static const String exerciseOfTheWeekRoute = '/exerciseOfTheWeek';
  static const String workoutGeneratorRoute = '/workoutGenerator';
  static const String monthlyComparisonRoute = '/monthlyComparison';
  static const String proteinChartRoute = '/proteinChart';
  static const String exerciseTracker = '/exerciseTracker';
  static const String strengthAnalyticsRoute = '/strengthAnalytics';
  static const String muscleAnalyticsRoute = '/muscleAnalytics';
  static const String workoutSessionDetailRoute = '/workoutSessionDetail';
  static const String dayWorkoutSessionRoute = '/dayWorkoutSession';
}

final GoRouter router = GoRouter(
  initialLocation: Routes.splashScreen,
  redirect: (BuildContext context, GoRouterState state) {
    // Don't redirect from splash screen - let it handle navigation
    if (state.uri.path == Routes.splashScreen) {
      return null;
    }

    // Try to get AuthProvider - if not available yet, allow navigation
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Wait for initial auth state to load
      if (authProvider.isLoading) {
        return Routes.splashScreen;
      }

      final user = authProvider.user;
      final hasAgeParameter = authProvider.hasAgeParameter;
      final emailIsVerified = user?.emailVerified ?? false;

      // If user is logged in and has completed profile, redirect away from auth/login pages
      if (user != null && hasAgeParameter == true && emailIsVerified) {
        if (state.uri.path == Routes.loginRoute ||
            state.uri.path == Routes.authRoute ||
            state.uri.path == Routes.boardingRoute) {
          return Routes.mainRoute;
        }
      }

      // If user is logged in but needs to add data
      if (user != null && hasAgeParameter == false && emailIsVerified) {
        if (state.uri.path == Routes.loginRoute ||
            state.uri.path == Routes.authRoute ||
            state.uri.path == Routes.boardingRoute) {
          return Routes.addDataRoute;
        }
      }

      // If user is not logged in, redirect away from protected routes
      if (user == null) {
        if (state.uri.path == Routes.mainRoute) {
          return Routes.boardingRoute;
        }
      }

      return null; // No redirect needed
    } catch (e) {
      // Provider not available yet, allow navigation
      return null;
    }
  },
  routes: [
    GoRoute(
        path: Routes.boardingRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, BoardingPage())),
    GoRoute(
        path: Routes.splashScreen,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, SplashScreen())),
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
        path: Routes.recoveryRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, PostWorkoutRecoveryPage())),
    GoRoute(
        path: Routes.emailVerify,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, VerifyEmailScreen())),
    GoRoute(
        path: Routes.cardioRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, CardioExercisesPage())),
    GoRoute(
      path: Routes.dailyExerciseRoute,
      pageBuilder: (context, state) {
        final day = int.tryParse(state.uri.queryParameters['day'] ?? '1') ?? 1;
        return PageTransitions.buildPageWithSlideTransition(
          state.pageKey,
          DailyExercisePage(
            day: day,
            onComplete: () {},
          ),
        );
      },
    ),
    GoRoute(
        path: Routes.bodypartsPage,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, BodyPartsScreen())),
    GoRoute(
        path: Routes.chestExerciseRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, ChestExercisesPage())),
    GoRoute(
        path: Routes.bicepsRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, BicepsExercisesPage())),
    GoRoute(
        path: Routes.tricepsRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, TricepsExercisesPage())),
    GoRoute(
        path: Routes.shouldersRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, ShoulderExercisesPage())),
    GoRoute(
        path: Routes.legsRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, LegExercisesPage())),
    GoRoute(
        path: Routes.absRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, AbsExercisesPage())),
    GoRoute(
        path: Routes.workoutSplitsRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(state.pageKey,
                WorkoutSplitListPage(workoutSplits: workoutSplits))),
    GoRoute(
        path: Routes.broSplit,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, BroSplitPage())),
    GoRoute(
        path: Routes.fullBodySplit,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, FullBodyPage())),
    GoRoute(
        path: Routes.pushPullLegsSplit,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, PPLPage())),
    GoRoute(
        path: Routes.upperLowerSplit,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, UpperLowerPage())),

    GoRoute(
        path: Routes.sixPackChallengeRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, const SixPackChallengeSelectionScreen())),
    GoRoute(
        path: Routes.backRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, LatExercisesPage())),
    GoRoute(
        path: Routes.dietRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, DietMain())),
    GoRoute(
        path: Routes.bulkingDietRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, BulkingDietScreen())),
    GoRoute(
        path: Routes.cuttingDietRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, CuttingDietScreen())),
    GoRoute(
        path: Routes.maintainDietRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, MaintainDietScreen())),
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
        path: Routes.comingSoon,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, ComingSoon())),

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
    GoRoute(
        path: Routes.premiumScreen,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, const PremiumScreen())),
    GoRoute(
        path: Routes.workoutLogRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, const WorkoutLogScreen())),
    GoRoute(
        path: Routes.workoutHistoryRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, const WorkoutHistoryScreen())),
    GoRoute(
        path: Routes.exerciseTracker,
        pageBuilder: (context, state) {
          final exerciseName = state.uri.queryParameters['exerciseName'] ?? 'Exercise';
          return PageTransitions.buildPageWithSlideTransition(
              state.pageKey, ExerciseTrackerPage(exerciseName: exerciseName));
        }),
    GoRoute(
        path: Routes.progressPhotosRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, const ProgressPhotosScreen())),
    GoRoute(
        path: Routes.addProgressPhotoRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, const AddProgressPhotoScreen())),
    GoRoute(
        path: Routes.photoComparisonRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, const PhotoComparisonScreen())),
    GoRoute(
        path: Routes.aiChatRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, const ChatScreen())),
    GoRoute(
        path: Routes.exerciseOfTheWeekRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, const ExerciseOfTheWeekScreen())),
    GoRoute(
        path: Routes.workoutGeneratorRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, const WorkoutGeneratorScreen())),
    GoRoute(
        path: Routes.monthlyComparisonRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, const MonthlyComparisonPage())),
    GoRoute(
        path: Routes.proteinChartRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, const ProteinChartPage())),
    GoRoute(
        path: Routes.strengthAnalyticsRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, const StrengthAnalyticsPage())),
    GoRoute(
        path: Routes.muscleAnalyticsRoute,
        pageBuilder: (context, state) =>
            PageTransitions.buildPageWithSlideTransition(
                state.pageKey, const MuscleAnalyticsPage())),
    GoRoute(
        path: Routes.workoutSessionDetailRoute,
        pageBuilder: (context, state) {
          final session = state.extra as WorkoutSession?;
          final sessionId = state.uri.queryParameters['sessionId'];
          return PageTransitions.buildPageWithSlideTransition(
              state.pageKey,
              WorkoutSessionDetailPage(
                session: session,
                sessionId: sessionId,
              ));
        }),
    GoRoute(
        path: Routes.dayWorkoutSessionRoute,
        pageBuilder: (context, state) {
          final extraMap = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : null;
          final extraDay = state.extra is String ? state.extra as String : null;
          final day = state.uri.queryParameters['day'] ??
              extraMap?['dayName']?.toString() ??
              extraDay ??
              'today';
          final workouts = extraMap?['workouts'] as List<dynamic>?;
          return PageTransitions.buildPageWithSlideTransition(
              state.pageKey,
              WorkoutSessionLauncherPage(
                dayName: day,
                initialWorkouts: workouts,
              ));
        }),
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
