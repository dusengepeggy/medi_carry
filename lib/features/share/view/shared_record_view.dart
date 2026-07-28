import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/share_payload.dart';

/// Read-only view of a decrypted share, shown to the **recipient** (a clinician
/// or caregiver on a phone that isn't theirs). No app chrome or navigation —
/// they're not the patient. Rendered from the offline [SharePayload] alone.
class SharedRecordView extends StatelessWidget {
  const SharedRecordView({super.key, required this.payload});

  final SharePayload payload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onClose: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payload.name.isEmpty ? 'Patient' : payload.name,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 28,
                        height: 35 / 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (payload.patientId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Patient ID: ${payload.patientId}',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if ((payload.bloodType ?? '').isNotEmpty)
                      _BloodTypePanel(bloodType: payload.bloodType!),
                    if ((payload.bloodType ?? '').isNotEmpty)
                      const SizedBox(height: 16),
                    if (payload.allergies.isNotEmpty) ...[
                      _ListPanel(
                        label: 'ALLERGIES',
                        values: payload.allergies,
                        highlight: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (payload.conditions.isNotEmpty) ...[
                      _ListPanel(
                        label: 'CHRONIC CONDITIONS',
                        values: payload.conditions,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (payload.records.isNotEmpty) ...[
                      _RecordsPanel(records: payload.records),
                      const SizedBox(height: 16),
                    ],
                    if ((payload.emergencyContactPhone ?? '').isNotEmpty) ...[
                      _ContactPanel(
                        name: payload.emergencyContactName,
                        phone: payload.emergencyContactPhone!,
                      ),
                      const SizedBox(height: 24),
                    ],
                    _Footer(expiresAt: payload.expiresAt),
                  ],
                ),
              ),
            ),
          ],
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
      color: AppColors.slate,
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      child: Row(
        children: [
          const Icon(Icons.folder_shared_outlined, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'SHARED MEDICAL RECORDS',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
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

class _BloodTypePanel extends StatelessWidget {
  const _BloodTypePanel({required this.bloodType});
  final String bloodType;

  @override
  Widget build(BuildContext context) {
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
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.limeOnSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bloodType,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 56,
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

class _ListPanel extends StatelessWidget {
  const _ListPanel({
    required this.label,
    required this.values,
    this.highlight = false,
  });

  final String label;
  final List<String> values;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight
              ? AppColors.danger
              : Colors.white.withValues(alpha: 0.1),
          width: highlight ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: highlight
                  ? AppColors.warningSurface
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          for (final v in values)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $v',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  height: 26 / 18,
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

class _RecordsPanel extends StatelessWidget {
  const _RecordsPanel({required this.records});
  final List<SharedRecord> records;

  @override
  Widget build(BuildContext context) {
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
            'RECORDS',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < records.length; i++) ...[
            if (i > 0)
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 20),
            Text(
              '${records[i].category} · ${records[i].date}',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.limeFinal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              records[i].title,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (records[i].detail.isNotEmpty)
              Text(
                records[i].detail,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ContactPanel extends StatelessWidget {
  const _ContactPanel({this.name, required this.phone});
  final String? name;
  final String phone;

  @override
  Widget build(BuildContext context) {
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
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          if ((name ?? '').isNotEmpty)
            Text(
              name!,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 4),
          SelectableText(
            phone,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.limeFinal,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.expiresAt});
  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    final d = expiresAt;
    final stamp = '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
    return Row(
      children: [
        Icon(Icons.verified_user_outlined,
            size: 16, color: Colors.white.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Shared securely · offline · access expires $stamp',
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
