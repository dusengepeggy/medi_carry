import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../bloc/app_lock/app_lock_cubit.dart';
import '../widgets/pin_keypad.dart';

/// Security settings — the app-lock PIN and biometric unlock.
///
/// Until now the PIN could only be set during sign-up and never changed, and
/// biometric unlock could never be turned on afterwards. An account created
/// before the security step existed had no route to a lock at all.
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  @override
  void initState() {
    super.initState();
    // The stored settings may have changed since the lock state was loaded at
    // startup — and biometric availability can change while the app runs.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AppLockCubit>().refresh(),
    );
  }

  Future<void> _setOrChangePin({required bool hasPin}) async {
    final cubit = context.read<AppLockCubit>();
    final messenger = ScaffoldMessenger.of(context);

    String? currentPin;
    if (hasPin) {
      currentPin = await PinSheet.show(
        context,
        title: 'Enter your current PIN',
        subtitle: 'Confirm it is you before changing the PIN.',
      );
      if (currentPin == null) return;
    }
    if (!mounted) return;

    final newPin = await PinSheet.show(
      context,
      title: hasPin ? 'Choose a new PIN' : 'Choose a PIN',
      subtitle: 'Four digits. You will need it to open MediCarry offline.',
    );
    if (newPin == null || !mounted) return;

    final confirmed = await PinSheet.show(
      context,
      title: 'Re-enter the PIN',
      subtitle: 'Just to be sure it is what you meant.',
    );
    if (confirmed == null) return;

    if (confirmed != newPin) {
      _tell(messenger, 'Those PINs did not match. Nothing was changed.');
      return;
    }

    if (hasPin) {
      final ok = await cubit.changePin(
        currentPin: currentPin!,
        newPin: newPin,
      );
      _tell(messenger, ok ? 'PIN updated' : 'That is not your current PIN.');
    } else {
      await cubit.setPin(newPin);
      _tell(messenger, 'PIN set — MediCarry will lock when you reopen it.');
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    final cubit = context.read<AppLockCubit>();
    final messenger = ScaffoldMessenger.of(context);
    if (!enable) {
      await cubit.disableBiometric();
      _tell(messenger, 'Biometric unlock turned off');
      return;
    }
    final ok = await cubit.enableBiometric();
    _tell(
      messenger,
      ok
          ? 'Biometric unlock turned on'
          : cubit.state.errorMessage ?? 'Could not turn on biometric unlock.',
    );
  }

  void _tell(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Security',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<AppLockCubit, AppLockState>(
          builder: (context, state) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'MediCarry locks itself with a PIN you set on this device. It '
                'works with no connection, because your records are readable '
                'offline and the lock has to be too.',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  height: 20 / 14,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              _SettingTile(
                icon: Icons.password_outlined,
                title: 'App-lock PIN',
                subtitle: state.isPinSet
                    ? 'A PIN is set on this device.'
                    : 'No PIN yet — the app opens without asking.',
                trailing: TextButton(
                  onPressed: () => _setOrChangePin(hasPin: state.isPinSet),
                  child: Text(state.isPinSet ? 'Change' : 'Set up'),
                ),
              ),
              const SizedBox(height: 12),
              _SettingTile(
                icon: Icons.fingerprint,
                title: 'Biometric unlock',
                subtitle: _biometricSubtitle(state),
                trailing: Switch.adaptive(
                  value: state.isBiometricEnabled,
                  activeThumbColor: AppColors.indigoFinal,
                  // A biometric is a shortcut past the PIN, never a
                  // replacement, so it needs a PIN behind it.
                  onChanged: state.isPinSet && state.isBiometricAvailable
                      ? _toggleBiometric
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              _SettingTile(
                icon: Icons.lock_outline,
                title: 'Lock now',
                subtitle: state.isPinSet
                    ? 'Close the app behind your PIN straight away.'
                    : 'Set a PIN first.',
                trailing: TextButton(
                  onPressed: state.isPinSet
                      ? () {
                          context.read<AppLockCubit>().lock();
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('Lock'),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: colors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your PIN is stored on this device only, salted and '
                        'hashed — never in plain text and never uploaded. '
                        'Signing out erases it, so you will set a new one next '
                        'time.',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          height: 18 / 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _biometricSubtitle(AppLockState state) {
    if (!state.isBiometricAvailable) {
      return 'This device has no fingerprint or face unlock set up.';
    }
    if (!state.isPinSet) return 'Set a PIN first — it is the fallback.';
    return state.isBiometricEnabled
        ? 'Unlock with your fingerprint or face.'
        : 'Use your fingerprint or face instead of typing the PIN.';
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: colors.textPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    height: 18 / 13,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

/// Asks for a 4-digit PIN and returns it, or null if dismissed.
///
/// Uses the same dots + keypad as the lock screen, so entering a PIN feels
/// identical wherever the app asks for one.
class PinSheet extends StatefulWidget {
  const PinSheet({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => PinSheet(title: title, subtitle: subtitle),
      );

  @override
  State<PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<PinSheet> {
  String _pin = '';

  void _tap(String digit) {
    if (_pin.length >= 4) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) {
      // Give the fourth dot a frame to paint before the sheet closes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(_pin);
      });
    }
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                height: 18 / 13,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            PinDots(length: _pin.length),
            const SizedBox(height: 20),
            PinKeypad(onDigit: _tap, onBackspace: _backspace),
          ],
        ),
      ),
    );
  }
}
