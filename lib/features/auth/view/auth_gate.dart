import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_shell.dart';
import '../bloc/app_lock/app_lock_cubit.dart';
import '../bloc/auth/auth_bloc.dart';
import 'lock_screen.dart';
import 'login_screen.dart';

/// Top-level router that renders the right surface from the combined auth +                 → clear lock
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthStatus? _previous;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        final lock = context.read<AppLockCubit>();
        switch (state.status) {
          case AuthStatus.authenticated:
            final isColdStart =
                _previous == null || _previous == AuthStatus.unknown;
            if (isColdStart) {
              lock.loadForStartup();
            } else {
              lock.markUnlocked();
            }
          case AuthStatus.unauthenticated:
            lock.handleSignedOut();
          case AuthStatus.unknown:
            break;
        }
        _previous = state.status;
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (prev, curr) => prev.status != curr.status,
        builder: (context, authState) {
          switch (authState.status) {
            case AuthStatus.unknown:
              return const _Splash();
            case AuthStatus.unauthenticated:
              return const LoginScreen();
            case AuthStatus.authenticated:
              return BlocBuilder<AppLockCubit, AppLockState>(
                builder: (context, lockState) {
                  if (lockState.status == LockStatus.locked) {
                    return const LockScreen();
                  }
                  return const AppShell();
                },
              );
          }
        },
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
