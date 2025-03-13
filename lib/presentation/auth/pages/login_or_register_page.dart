import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/presentation/auth/widgets/login_or_register_view.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/utils/widgets/custom_google_button.dart';
import 'package:fitness_app/utils/widgets/lime_green_rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_button/sign_in_button.dart';

enum AuthMode { signUp, signIn }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();

  AuthMode _authMode = AuthMode.signIn;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  bool get isRegisterView => _authMode == AuthMode.signUp;
  bool get isLoginView => _authMode == AuthMode.signIn;

  void _switchAuthMode() {
    setState(() {
      _authMode = isLoginView ? AuthMode.signUp : AuthMode.signIn;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  bool _validateFields() {
    if (_emailController.text.isEmpty) {
      _showSnackBar('Email cannot be empty');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      _showSnackBar('Please enter a valid email address');
      return false;
    }
    if (_passwordController.text.isEmpty) {
      _showSnackBar('Password cannot be empty');
      return false;
    }
    if (isRegisterView && _passwordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return false;
    }
    if (isRegisterView &&
        _passwordController.text != _repeatPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return false;
    }
    return true;
  }

  Future<void> _signUserIn(AuthProvider authProvider) async {
    try {
      await authProvider.signIn(
        email: _emailController.text,
        password: _passwordController.text,
        context: context,
      );
    } catch (e) {
      _handleAuthError(e.toString());
    }
  }

  Future<void> _signUserUp(AuthProvider authProvider) async {
    try {
      await authProvider.register(
        email: _emailController.text,
        password: _passwordController.text,
        context: context,
      );
    } catch (e) {
      _handleAuthError(e.toString());
    }
  }

  void _handleAuthError(String error) {
    if (error.contains('The supplied auth credential is incorrect')) {
      _showSnackBar(
          'The credentials are incorrect or no account exists for this email.');
    } else if (error.contains('wrong-password')) {
      _showSnackBar('Invalid password. Please try again.');
    } else if (error.contains('email-already-in-use')) {
      _showSnackBar('This email is already registered. Please sign in.');
    } else {
      _showSnackBar('Authentication failed: $error');
    }
  }

  void _handleAuthAction(AuthProvider authProvider) {
    if (!_validateFields()) return;

    if (isLoginView) {
      _signUserIn(authProvider);
    } else {
      _signUserUp(authProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: ColorManager.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: PaddingManager.p12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: PaddingManager.p8),
                  child: SizedBox(
                    width: SizeManager.s250.w,
                    height: SizeManager.s250.h,
                    // Add your logo here if needed
                    // child: Image.asset(ImageManager.logo),
                  ),
                ),
                LoginOrRegisterView(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isRegisterView: isRegisterView,
                  repeatPasswordController: _repeatPasswordController,
                ),
                if (isLoginView)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PaddingManager.p28,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          context.push(Routes.forgotPasswordRoute);
                        },
                        child: Text(
                          StringsManager.forgotPassword,
                          style: StyleManager.loginPageSubTextTextStyle,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: PaddingManager.p2),
                  child: LimeGreenRoundedButtonWidget(
                    onTap: () => _handleAuthAction(authProvider),
                    title: isLoginView
                        ? StringsManager.signIn
                        : StringsManager.signUp,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PaddingManager.p28,
                    vertical: PaddingManager.p18,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLoginView
                            ? StringsManager.dontHaveAcc
                            : StringsManager.haveAcc,
                        style: StyleManager.loginPageSubTextTextStyle,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: PaddingManager.p8),
                        child: GestureDetector(
                          onTap: _switchAuthMode,
                          child: Text(
                            isLoginView
                                ? StringsManager.signUp
                                : StringsManager.signIn,
                            style:
                                TextStyle(color: Colors.orangeAccent,fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: PaddingManager.p8),
                  child: CustomGoogleSignInButton(onTap: () async {
                    await authProvider.signInWithGoogle(context);
                  }),
                
                ),
              ],
            ).animate().fadeIn(duration: 500.ms),
          ),
        ),
      ),
    );
  }
}
