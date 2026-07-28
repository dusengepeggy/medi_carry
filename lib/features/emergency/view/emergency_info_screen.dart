import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/emergency_card_store.dart';
import '../../../core/theme/app_colors.dart';

/// Emergency medical information.
///
/// No Figma frame exists for this screen, so it is designed in the established
/// system for its actual reader: a **stranger — paramedic, nurse, bystander —
/// reading a phone they do not own, in a hurry**. Hence oversized values,
/// allergy-first ordering, and no navigation chrome beyond Close.
///
/// It renders from the on-device [EmergencyCardStore] snapshot, so it works
/// while the app is locked, offline, and cold-started.
class EmergencyInfoScreen extends StatefulWidget {
  const EmergencyInfoScreen({super.key});

  @override
  State<EmergencyInfoScreen> createState() => _EmergencyInfoScreenState();
}

class _EmergencyInfoScreenState extends State<EmergencyInfoScreen> {
  late final Future<EmergencyCard?> _card =
      context.read<EmergencyCardStore>().read();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: FutureBuilder<EmergencyCard?>(
          future: _card,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.limeFinal),
              );
            }
            final card = snapshot.data;
            return Column(
              children: [
                _Header(onClose: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: card == null
                      ? const _EmptyState()
                      : _CardBody(card: card),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.danger,
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      child: Row(
        children: [
          const Icon(Icons.emergency_outlined, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'EMERGENCY MEDICAL INFORMATION',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: 'Close',
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.card});

  final EmergencyCard card;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.fullName.isEmpty ? 'MediCarry patient' : card.fullName,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 28,
              height: 35 / 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (card.patientId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Patient ID: ${card.patientId}',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Blood type reads first and largest — it is the single most
          // requested value in a trauma hand-off.
          _BloodTypePanel(bloodType: card.bloodType),
          const SizedBox(height: 16),

          _InfoPanel(
            label: 'ALLERGIES',
            values: card.allergies,
            emptyText: 'None recorded',
            highlight: true,
          ),
          const SizedBox(height: 16),
          _InfoPanel(
            label: 'CHRONIC CONDITIONS',
            values: card.chronicConditions,
            emptyText: 'None recorded',
          ),
          const SizedBox(height: 16),
          _EmergencyContactPanel(card: card),
          const SizedBox(height: 24),
          _Footer(updatedAt: card.updatedAt),
        ],
      ),
    );
  }
}

class _BloodTypePanel extends StatelessWidget {
  const _BloodTypePanel({this.bloodType});

  final String? bloodType;

  @override
  Widget build(BuildContext context) {
    final value = (bloodType ?? '').trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.limeFinal,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BLOOD TYPE',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.limeOnSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'Not recorded' : value,
            style: GoogleFonts.hankenGrotesk(
              fontSize: value.isEmpty ? 28 : 56,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              color: AppColors.limeOnSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.label,
    required this.values,
    required this.emptyText,
    this.highlight = false,
  });

  final String label;
  final List<String> values;
  final String emptyText;

  /// Allergies are highlighted — administering the wrong drug is the failure
  /// mode this screen exists to prevent.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final isEmpty = values.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: highlight && !isEmpty
            ? Border.all(color: AppColors.danger, width: 2)
            : Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: highlight && !isEmpty
                  ? AppColors.warningSurface
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          if (isEmpty)
            Text(
              emptyText,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                height: 26 / 18,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            )
          else
            for (final value in values)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $value',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 20,
                    height: 28 / 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _EmergencyContactPanel extends StatelessWidget {
  const _EmergencyContactPanel({required this.card});

  final EmergencyCard card;

  Future<void> _copyNumber(BuildContext context) async {
    final phone = card.emergencyContactPhone;
    if (phone == null) return;
    await Clipboard.setData(ClipboardData(text: phone));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (card.emergencyContactName ?? '').trim();
    final phone = (card.emergencyContactPhone ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EMERGENCY CONTACT',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          if (!card.hasContact)
            Text(
              'None recorded',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                height: 26 / 18,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            )
          else ...[
            if (name.isNotEmpty)
              Text(
                name,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 20,
                  height: 28 / 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            const SizedBox(height: 8),
            SelectableText(
              phone,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 24,
                height: 32 / 24,
                fontWeight: FontWeight.w700,
                color: AppColors.limeFinal,
              ),
            ),
            const SizedBox(height: 12),
            // Dialling needs a platform-call plugin the project does not have
            // yet, so offer copy — which works offline and never fails.
            TextButton.icon(
              onPressed: () => _copyNumber(context),
              icon: const Icon(Icons.copy, size: 18, color: Colors.white),
              label: Text(
                'Copy number',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({this.updatedAt});

  final DateTime? updatedAt;

  String get _stamp {
    if (updatedAt == null) return 'Stored on this device';
    final d = updatedAt!;
    return 'Last updated ${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.cloud_off_outlined,
          size: 16,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Available offline · $_stamp',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 40,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No emergency information yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 20,
                height: 28 / 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in and complete your medical profile so this information '
              'is available even when the phone is locked.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                height: 24 / 16,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
