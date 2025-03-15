import 'dart:async'; // For Timer
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness_app/utils/router/router.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isCooldownActive = false;
  int _cooldownSeconds = 30; // 30-second cooldown
  Timer? _cooldownTimer;

  Future<void> _checkEmailVerification(BuildContext context) async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'email': user.email});
      context.push(Routes.addDataRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Email not verified yet. Please check again.'),
        ),
      );
    }
  }

  Future<void> _resendVerificationEmail(BuildContext context) async {
    if (_isCooldownActive) return; // Prevent spamming

    setState(() => _isCooldownActive = true);

    await FirebaseAuth.instance.currentUser?.sendEmailVerification();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ColorManager.limerGreen2,
        content: Text(
          'Verification email resent. Please check your inbox.',
          style: TextStyle(color: ColorManager.black),
        ),
      ),
    );

    // Start cooldown timer
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds == 0) {
        setState(() {
          _isCooldownActive = false;
          _cooldownSeconds = 30; // Reset countdown
        });
        _cooldownTimer?.cancel();
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.darkGrey,
      appBar: AppBar(
        backgroundColor: ColorManager.darkGrey,
        title: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: const Text(
            'Verify Your Email',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined,
                size: 80, color: ColorManager.limerGreen2),
            const SizedBox(height: 20),
            const Text(
              'Please check your email and verify your account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.black54,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => _checkEmailVerification(context),
              icon: const Icon(Icons.verified, color: Colors.white),
              label: const Text('I Verified My Email'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCooldownActive
                    ? ColorManager.black54
                    : ColorManager.black54,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isCooldownActive
                  ? null
                  : () => _resendVerificationEmail(context),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                _isCooldownActive
                    ? 'Resend in $_cooldownSeconds s'
                    : 'Resend Verification Email',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
