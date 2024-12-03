import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/widgets/text_field_widget.dart';
import 'package:flutter/material.dart';

class LoginOrRegisterView extends StatelessWidget {
  const LoginOrRegisterView({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isRegisterView,
    required this.repeatPasswordController,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isRegisterView;
  final TextEditingController repeatPasswordController;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextFieldWidget(
          controller: emailController,
          labelHint: StringsManager.emailHint,
          obscureText: false,
          keyboardType: TextInputType.emailAddress,
        ),
        TextFieldWidget(
          controller: passwordController,
          labelHint: StringsManager.passwordHint,
          obscureText: true,
          keyboardType: TextInputType.emailAddress,
        ),
        isRegisterView
            ? TextFieldWidget(
                controller: repeatPasswordController,
                labelHint: StringsManager.repeatPasswordHint,
                obscureText: true,
                keyboardType: TextInputType.emailAddress,
              )
            : Container(),
      ],
    );
  }
}
