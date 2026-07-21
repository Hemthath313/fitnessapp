import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/presentation/auth/widgets/login_or_register_view.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/widgets/custom_google_button.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

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
  void initState() {
    super.initState();
    // Ensure any lingering overlays are dismissed when login page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LoadingOverlay.hide(null);
      LoadingOverlay.forceHide();
    });
  }

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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: 14.sp),
        ),
        backgroundColor: ColorManager.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
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
      await authProvider.registerAndVerifyEmail(
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
    final isLoading = authProvider.isLoading;

    return Scaffold(
      backgroundColor: ColorManager.backgroundDark, // Matches the bottom gradient shade
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorManager.background,
              ColorManager.backgroundDark,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false, // Allows background to flow edge-to-edge
          top: true,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 40.h),
                  
                  // Logo/Header Section with attractive design
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ColorManager.primary.withOpacity(0.2),
                              ColorManager.secondary.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          size: 44.sp,
                          color: ColorManager.primary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        isLoginView ? 'Welcome Back!' : 'Create Account',
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        isLoginView
                            ? 'Sign in to continue your fitness journey'
                            : 'Start your fitness journey today',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 15.sp,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                
                SizedBox(height: 32.h),
                
                // Input Fields
                LoginOrRegisterView(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isRegisterView: isRegisterView,
                  repeatPasswordController: _repeatPasswordController,
                ),
                
                SizedBox(height: 20.h),
                
                // Sign In/Up Button with gradient
                Container(
                  height: 50.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorManager.primary,
                        ColorManager.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: ColorManager.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLoading ? null : () => _handleAuthAction(authProvider),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        alignment: Alignment.center,
                        child: isLoading
                            ? SizedBox(
                                height: 24.h,
                                width: 24.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                isLoginView
                                    ? StringsManager.signIn
                                    : StringsManager.signUp,
                                style: TextStyle(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // Divider with better styling
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              ColorManager.textTertiary.withOpacity(0.2),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: ColorManager.textTertiary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ColorManager.textTertiary.withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                // Google Sign In Button
                CustomGoogleSignInButton(
                  onTap: isLoading
                      ? () {}
                      : () async {
                          await authProvider.signInWithGoogle(context);
                        },
                ),
                
                SizedBox(height: 16.h),
                
                // Switch Auth Mode
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLoginView
                          ? StringsManager.dontHaveAcc
                          : StringsManager.haveAcc,
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    GestureDetector(
                      onTap: _switchAuthMode,
                      child: Text(
                        isLoginView
                            ? StringsManager.signUp
                            : StringsManager.signIn,
                        style: TextStyle(
                          color: ColorManager.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24.h),
              ],
            ).animate().fadeIn(duration: 500.ms),
          ),
        ),
        ),
      ),
    );
  }
}
