import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/auth_providers.dart';
import 'auth_screen.dart';
import 'email_verification_screen.dart';
import 'home_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (userId) {
        if (userId == null) {
          return const AuthScreen();
        }

        final repository = ref.read(authRepositoryProvider);
        if (!repository.isEmailVerified) {
          return const EmailVerificationScreen();
        }

        return const HomeScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('error_occurred'.tr())),
      ),
    );
  }
}