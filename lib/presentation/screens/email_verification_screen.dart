import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/auth_providers.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    final repository = ref.read(authRepositoryProvider);
    await repository.reloadUser();

    if (!repository.isEmailVerified && mounted) {
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('email_not_verified_yet'.tr())),
      );
      return;
    }


    ref.invalidate(authStateProvider);
    if (mounted) setState(() => _isChecking = false);
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    final repository = ref.read(authRepositoryProvider);
    await repository.sendEmailVerification();
    if (mounted) {
      setState(() => _isResending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('verification_email_resent'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(currentUserEmailProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'verify_email_title'.tr(),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${'verify_email_message'.tr()} $email',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isChecking ? null : _checkVerification,
                child: _isChecking
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : Text('ive_verified'.tr()),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isResending ? null : _resendEmail,
                child: Text('resend_email'.tr()),
              ),
              TextButton(
                onPressed: () {
                  ref.read(authRepositoryProvider).signOut();
                },
                child: Text('logout'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}