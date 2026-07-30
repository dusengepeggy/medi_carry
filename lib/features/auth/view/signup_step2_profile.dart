import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../bloc/signup/signup_cubit.dart';
import '../widgets/step_progress.dart';

/// Step 2 — Medical Profile: blood type, allergies, chronic conditions.
class SignUpStep2Profile extends StatefulWidget {
  const SignUpStep2Profile({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<SignUpStep2Profile> createState() => _SignUpStep2ProfileState();
}

class _SignUpStep2ProfileState extends State<SignUpStep2Profile> {
  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  String? _bloodType;
  final _allergiesCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<SignUpCubit>().state;
    _bloodType = s.bloodType;
    _allergiesCtrl.text = s.allergies.join(', ');
    _conditionsCtrl.text = s.chronicConditions.join(', ');
  }

  @override
  void dispose() {
    _allergiesCtrl.dispose();
    _conditionsCtrl.dispose();
    super.dispose();
  }

  List<String> _split(String text) => text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  void _continue() {
    context.read<SignUpCubit>().updateMedicalProfile(
          bloodType: _bloodType,
          allergies: _split(_allergiesCtrl.text),
          chronicConditions: _split(_conditionsCtrl.text),
        );
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(onBack: widget.onBack),
          const SizedBox(height: 8),
          const StepProgress(currentStep: 2),
          const SizedBox(height: 24),
          Text('Medical Profile', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Complete your health information to help us provide more accurate '
            'medical assistance.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: 24),
          _Label('BLOOD TYPE'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _bloodType,
            decoration: const InputDecoration(
              hintText: 'Select your blood type',
              prefixIcon: Icon(Icons.bloodtype_outlined),
            ),
            items: [
              for (final t in _bloodTypes)
                DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: (v) => setState(() => _bloodType = v),
          ),
          const SizedBox(height: 16),
          _Label('ALLERGIES'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _allergiesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g. Penicillin, Peanuts, Pollen',
            ),
          ),
          const SizedBox(height: 16),
          _Label('CHRONIC CONDITIONS'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _conditionsCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g. Diabetes, Asthma, Hypertension',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline,
                    size: 18, color: context.colors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This information is encrypted and only shared with verified '
                    'healthcare professionals during emergencies or when you '
                    'explicitly grant access.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: context.colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _continue,
            child: const Text('Continue'),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('STEP 2 OF 3',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: context.colors.textMuted)),
          ),
        ],
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(color: context.colors.textSecondary),
    );
  }
}
