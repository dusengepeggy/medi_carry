import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_semantic_colors.dart';

/// The four filled/empty dots showing how much of a PIN has been entered.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, this.of = 4});

  /// How many digits have been entered.
  final int length;

  /// How many digits the PIN has in total.
  final int of;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < of; i++)
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < length ? AppColors.navy : context.colors.surfaceMuted,
              border: Border.all(color: context.colors.border),
            ),
          ),
      ],
    );
  }
}

/// The numeric keypad used to enter a PIN.
///
/// Shared by the lock screen and the security settings screen so a PIN is
/// entered the same way wherever it is asked for.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.showBiometric = false,
    this.onBiometric,
  });

  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;

  /// Offers the fingerprint shortcut in the empty bottom-left cell.
  final bool showBiometric;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.6,
      children: [
        for (final k in keys) _Key(label: k, onTap: () => onDigit(k)),
        showBiometric && onBiometric != null
            ? _Key(icon: Icons.fingerprint, onTap: onBiometric!)
            : const SizedBox.shrink(),
        _Key(label: '0', onTap: () => onDigit('0')),
        _Key(icon: Icons.backspace_outlined, onTap: onBackspace),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, required this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: context.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: icon != null
                ? Icon(icon, color: context.colors.textPrimary)
                : Text(
                    label!,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: context.colors.textPrimary),
                  ),
          ),
        ),
      ),
    );
  }
}
