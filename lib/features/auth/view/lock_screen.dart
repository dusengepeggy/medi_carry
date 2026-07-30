import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../bloc/app_lock/app_lock_cubit.dart';
import '../bloc/auth/auth_bloc.dart';
import '../widgets/pin_keypad.dart';

/// Offline unlock screen shown when an authenticated session is restored.
/// Unlocks via biometric or a 4-digit PIN — works with no connectivity.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';

  @override
  void initState() {
    super.initState();
    // Offer biometric immediately if enabled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<AppLockCubit>();
      if (cubit.state.isBiometricEnabled) cubit.unlockWithBiometric();
    });
  }

  Future<void> _tap(String digit) async {
    if (_pin.length >= 4) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) {
      final ok = await context.read<AppLockCubit>().unlockWithPin(_pin);
      if (!ok && mounted) setState(() => _pin = '');
    }
  }

  void _backspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppLockCubit>().state;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.logoSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_outline,
                    color: AppColors.lime, size: 34),
              ),
              const SizedBox(height: 20),
              Text('Welcome back', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Enter your PIN to unlock',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: context.colors.textSecondary)),
              const SizedBox(height: 24),
              PinDots(length: _pin.length),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(state.errorMessage!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              PinKeypad(
                onDigit: _tap,
                onBackspace: _backspace,
                showBiometric: state.isBiometricEnabled,
                onBiometric: () =>
                    context.read<AppLockCubit>().unlockWithBiometric(),
              ),
              const Spacer(),
              // Emergency info is readable WITHOUT unlocking: the brief's
              // scenario is an unconscious patient, so a responder must be
              // able to reach it from the lock screen.
              TextButton.icon(
                onPressed: () => AppNav.openEmergencyInfo(context),
                icon: const Icon(Icons.emergency_outlined,
                    size: 18, color: AppColors.danger),
                label: const Text('Emergency Info'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthSignOutRequested()),
                child: const Text('Sign in with a different account'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
