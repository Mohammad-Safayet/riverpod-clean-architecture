import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:riverpod_clean_architecture/core/base/base_screen.dart';
import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';
import 'package:riverpod_clean_architecture/core/theme/app_values.dart';
import 'package:riverpod_clean_architecture/core/utils/validators.dart';
import 'package:riverpod_clean_architecture/features/auth/presentation/notifiers/login_notifier.dart';

class LoginScreen extends BaseStatefulScreen {
  const LoginScreen({super.key});

  @override
  BaseScreenState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends BaseScreenState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _username = TextEditingController(text: buildConfig.isDev ? 'emilys' : '');
  late final _password = TextEditingController(text: buildConfig.isDev ? 'emilyspass' : '');

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref.read(loginProvider.notifier).login(username: _username.text, password: _password.text);
  }

  @override
  Widget body(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(loginProvider);
    final required = context.validators.required();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppValues.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.loginTitle, style: context.textStyles.headline),
              const SizedBox(height: AppValues.paddingLarge),
              TextFormField(
                controller: _username,
                decoration: InputDecoration(labelText: l10n.loginUsername),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                validator: required,
              ),
              const SizedBox(height: AppValues.padding),
              TextFormField(
                controller: _password,
                obscureText: state.obscurePassword,
                decoration: InputDecoration(
                  labelText: l10n.loginPassword,
                  suffixIcon: IconButton(
                    icon: Icon(state.obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: ref.read(loginProvider.notifier).togglePasswordVisibility,
                  ),
                ),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                validator: required,
              ),
              const SizedBox(height: AppValues.paddingLarge),
              ElevatedButton(onPressed: _submit, child: Text(l10n.loginButton)),
            ],
          ),
        ),
      ),
    );
  }
}
