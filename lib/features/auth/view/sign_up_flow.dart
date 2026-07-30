import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/secure_storage_service.dart';
import '../bloc/app_lock/app_lock_cubit.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/signup/signup_cubit.dart';
import '../data/auth_repository.dart';
import '../data/user_repository.dart';
import '../models/app_user.dart';
import 'signup_step1_account.dart';
import 'signup_step2_profile.dart';
import 'signup_step3_security.dart';

/// Hosts the 3-step sign-up wizard behind a single [SignUpCubit]. On success,
/// the [AuthBloc] auth stream flips to authenticated and the AuthGate swaps to
/// the app, so this flow simply pops itself.
///
/// The same wizard finishes a Google sign-in — see [SignUpFlow.onboarding].
/// Google gives us an identity and nothing else: no patient ID, no blood type,
/// no allergies, and no app-lock PIN. Reusing these steps is what stops a
/// Google account being a second-class one.
class SignUpFlow extends StatefulWidget {
  const SignUpFlow({super.key}) : existingUser = null;

  /// Completes onboarding for an already-authenticated user. The account step
  /// is dropped (the identity exists) and the medical + security steps run
  /// exactly as they do for a manual sign-up.
  const SignUpFlow.onboarding({super.key, required AppUser user})
      : existingUser = user;

  /// The signed-in user being onboarded, or null for a fresh sign-up.
  final AppUser? existingUser;

  bool get _isOnboarding => existingUser != null;

  @override
  State<SignUpFlow> createState() => _SignUpFlowState();
}

class _SignUpFlowState extends State<SignUpFlow> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() => _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

  void _back() {
    if (_controller.page?.round() != 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    // Onboarding is rendered by the AuthGate, not pushed over it, so there is
    // nothing to pop — and the user cannot go "back" to being signed out
    // without actually signing out.
    if (widget._isOnboarding) {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = widget.existingUser;
    return BlocProvider(
      create: (_) {
        final cubit = SignUpCubit(
          authRepository: context.read<AuthRepository>(),
          userRepository: context.read<UserRepository>(),
          secureStorage: context.read<SecureStorageService>(),
        );
        if (onboarding != null) {
          cubit.adoptAuthenticatedUser(
            uid: onboarding.uid,
            fullName: onboarding.displayName ?? '',
            email: onboarding.email ?? '',
          );
        }
        return cubit;
      },
      child: BlocListener<SignUpCubit, SignUpState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == SignUpStatus.success) {
            // The lock state was read when auth flipped — before step 3 wrote
            // the PIN — so it still believes no PIN exists and would refuse to
            // re-lock. Re-read it now that the PIN is stored.
            context.read<AppLockCubit>().markUnlocked();
            // Onboarding has no route of its own: writing the profile makes
            // the AuthGate swap to the app on its own.
            if (!widget._isOnboarding) Navigator.of(context).pop();
          } else if (state.status == SignUpStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                if (onboarding == null)
                  SignUpStep1Account(onNext: _next, onBack: _back),
                SignUpStep2Profile(onNext: _next, onBack: _back),
                SignUpStep3Security(onBack: _back),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
