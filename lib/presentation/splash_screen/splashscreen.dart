import 'dart:async';
import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Ensure user data is loaded before proceeding
    await authProvider.loadUserData();

    final user = authProvider.user;
    final hasAgeParameter = authProvider.hasAgeParameter;
    final emailIsVerified = user?.emailVerified ?? false;

    if (user != null && hasAgeParameter == true) {
      if (mounted) context.go(Routes.mainRoute);
    } else if (user != null &&
        hasAgeParameter == false &&
        emailIsVerified == true) {
      if (mounted) context.go(Routes.addDataRoute);
    } else {
      if (mounted) context.go(Routes.boardingRoute);
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
      backgroundColor: Colors.black, // Pure black background
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
