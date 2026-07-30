import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/signup/signup_cubit.dart';
import '../widgets/step_progress.dart';

/// Step 1 — Create Account: full name, email, password (or Google).
class SignUpStep1Account extends StatefulWidget {
  const SignUpStep1Account({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<SignUpStep1Account> createState() => _SignUpStep1AccountState();
}

class _SignUpStep1AccountState extends State<SignUpStep1Account> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final s = context.read<SignUpCubit>().state;
    _nameCtrl.text = s.fullName;
    _emailCtrl.text = s.email;
    _passwordCtrl.text = s.password;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<SignUpCubit>().updateAccount(
            fullName: _nameCtrl.text,
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
          );
      widget.onNext();
    }
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
          const StepProgress(currentStep: 1),
          const SizedBox(height: 24),
          Text('Create Account', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Label('FULL NAME'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'John Doe',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 16),
                _Label('EMAIL ADDRESS'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 16),
                _Label('PASSWORD'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Min. 8 characters',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8)
                      ? 'At least 8 characters'
                      : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _continue,
                  child: const Text('Continue'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child:
                          Text('OR', style: theme.textTheme.labelMedium),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context
                      .read<AuthBloc>()
                      .add(const AuthGoogleSignInRequested()),
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('Sign up with Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: widget.onBack,
              child: Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: 'Log in',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: AppColors.indigo),
                    ),
                  ],
                ),
              ),
            ),
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
