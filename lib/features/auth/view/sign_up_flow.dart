import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/secure_storage_service.dart';
import '../bloc/signup/signup_cubit.dart';
import '../data/auth_repository.dart';
import '../data/user_repository.dart';
import 'signup_step1_account.dart';
import 'signup_step2_profile.dart';
import 'signup_step3_security.dart';

/// Hosts the 3-step sign-up wizard behind a single [SignUpCubit]. On success,
/// the [AuthBloc] auth stream flips to authenticated and the AuthGate swaps to
/// the app, so this flow simply pops itself.
class SignUpFlow extends StatefulWidget {
  const SignUpFlow({super.key});

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
    if (_controller.page?.round() == 0) {
      Navigator.of(context).pop();
    } else {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignUpCubit(
        authRepository: context.read<AuthRepository>(),
        userRepository: context.read<UserRepository>(),
        secureStorage: context.read<SecureStorageService>(),
      ),
      child: BlocListener<SignUpCubit, SignUpState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == SignUpStatus.success) {
            Navigator.of(context).pop();
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
