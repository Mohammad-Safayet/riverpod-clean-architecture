import 'package:flutter/material.dart';

import 'package:riverpod_clean_architecture/core/widgets/app_loading.dart';

/// Shown while the session is being restored at startup.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: AppLoading());
}
