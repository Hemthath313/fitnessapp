import 'package:fitness_app/presentation/auth/pages/add_data_page.dart';
import 'package:fitness_app/presentation/auth/pages/login_or_register_page.dart';
import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/presentation/email_verification/email_verify.dart';
import 'package:fitness_app/presentation/main/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          final hasAgeParameter = authProvider.hasAgeParameter;

          // New Condition: Check if email is verified
          var isEmailVerified = user?.emailVerified ?? false;
          var isRegisteredUser =
              user != null && hasAgeParameter == true && isEmailVerified;
          var isAddDataMode =
              user != null && hasAgeParameter == false && isEmailVerified;

          if (isRegisteredUser) {
            return const MainPage();
          } else if (isAddDataMode) {
            return const AddDataPage();
          } else if (user != null && !isEmailVerified) {
            return const VerifyEmailScreen(); // Route to verify email
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
