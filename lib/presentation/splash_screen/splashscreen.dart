import 'package:fitness_app/utils/managers/color_manager.dart';
import 'dart:async';
import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _gradientAnimation;
  bool _showFinalText = false; // Show final text after gradient animation

  @override
  void initState() {
    super.initState();

    // Request notification permission immediately on app launch
    try {
      NotificationService().initialize();
    } catch (e) {
      print('Error initializing notifications on launch: $e');
    }

    // Animation controller (Runs only once)
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..forward().whenComplete(() {
        setState(() {
          _showFinalText = true; // Show final text after animation completes
        });
      });

    // Bounce scale effect for logo
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.6, end: 1.2)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 70),
      TweenSequenceItem(
          tween: Tween(begin: 1.2, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
    ]).animate(_controller);

    // Fade-in effect (Runs once)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Gradient shift from left to right (Runs once)
    _gradientAnimation = Tween<double>(begin: -1.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Navigate to home screen after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      navigate();
    });
  }

  Future<void> navigate() async {
    print('SplashScreen: Starting navigation logic');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for initial auth state to load (with timeout)
    print('SplashScreen: Waiting for AuthProvider.isLoading (current: ${authProvider.isLoading})');
    int attempts = 0;
    while (authProvider.isLoading && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    print('SplashScreen: Out of wait loop. Attempts: $attempts, isLoading: ${authProvider.isLoading}');

    // Ensure user data is loaded before proceeding
    print('SplashScreen: Calling authProvider.loadUserData()');
    await authProvider.loadUserData();
    print('SplashScreen: loadUserData() completed');

    // Wait a bit more to ensure state is updated
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final user = authProvider.user;
    final hasAgeParameter = authProvider.hasAgeParameter;
    final emailIsVerified = user?.emailVerified ?? false;
    
    print('SplashScreen: Final state - user: ${user?.uid}, hasAge: $hasAgeParameter, verified: $emailIsVerified');

    if (user != null && hasAgeParameter == true && emailIsVerified) {
      context.go(Routes.mainRoute);
    } else if (user != null &&
        hasAgeParameter == false &&
        emailIsVerified == true) {
      context.go(Routes.addDataRoute);
    } else {
      context.go(Routes.boardingRoute);
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background, // Pure black background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with bounce & fade effect (happens only once)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value, // Bounce effect
                  child: Opacity(
                    opacity: _fadeAnimation.value, // Fade-in effect (one time)
                    child: Image.asset(
                      'assets/images/applogo.png', // Replace with your logo
                      width: 260, // Adjusted size for balance
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 35), // **Increased spacing between logo & text**
            // Show full text normally after animation completes
          ],
        ),
      ),
    );
  }
}
