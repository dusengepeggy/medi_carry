import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/signup/signup_cubit.dart';
import '../widgets/step_progress.dart';

/// Step 3 — Final: enable biometric unlock and create a 4-digit PIN, then
/// submit the whole wizard.
class SignUpStep3Security extends StatefulWidget {
  const SignUpStep3Security({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<SignUpStep3Security> createState() => _SignUpStep3SecurityState();
}

class _SignUpStep3SecurityState extends State<SignUpStep3Security> {
  bool _biometric = false;
  String _pin = '';

  void _tap(String digit) {
    if (_pin.length < 4) setState(() => _pin += digit);
  }

  void _backspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _submit() {
    final cubit = context.read<SignUpCubit>();
    cubit.setBiometric(_biometric);
    cubit.setPin(_pin);
    cubit.submit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSubmitting = context.select(
      (SignUpCubit c) => c.state.status == SignUpStatus.submitting,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(onBack: widget.onBack),
          const SizedBox(height: 8),
          const StepProgress(
            currentStep: 3,
            labels: ['Profile', 'Verification', 'Secure'],
          ),
          const SizedBox(height: 24),
          Text('Final Step', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            "Let's secure your medical data with biometrics and a private "
            'passcode.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.fingerprint, color: AppColors.olive),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enable Biometrics',
                          style: theme.textTheme.titleMedium),
                      Text('Fast, secure access to records',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: _biometric,
                  onChanged: (v) => setState(() => _biometric = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Create a 4-digit PIN',
              textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Use this when biometrics are unavailable',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          _PinDots(length: _pin.length),
          const SizedBox(height: 20),
          _Keypad(onDigit: _tap, onBackspace: _backspace),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_pin.length == 4 && !isSubmitting) ? _submit : null,
            child: isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.white),
                    ),
                  )
                : const Text('Continue'),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('Your data is encrypted locally on this device.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.length});
  final int length;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < length ? AppColors.navy : AppColors.fill,
              border: Border.all(color: AppColors.divider),
            ),
          ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.8,
      children: [
        for (final k in keys)
          if (k.isEmpty)
            const SizedBox.shrink()
          else
            _Key(
              label: k,
              onTap: () => k == '⌫' ? onBackspace() : onDigit(k),
            ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.ink)),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        const Spacer(),
        Text('MediCarry', style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }
}
