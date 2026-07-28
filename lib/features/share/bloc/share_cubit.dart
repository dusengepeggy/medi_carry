import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/services/share_crypto.dart';
import '../../auth/models/patient_profile.dart';
import '../../records/models/medical_record.dart';
import '../data/shares_repository.dart';
import '../models/share_grant.dart';
import '../models/share_payload.dart';

part 'share_state.dart';

/// Owns the Share screen's granular selection + duration, and turns them into
/// an encrypted, self-contained QR code — recording a [ShareGrant] so the
/// patient can later see and revoke the share.
class ShareCubit extends Cubit<ShareState> {
  ShareCubit({required SharesRepository sharesRepository, required String uid})
      : _shares = sharesRepository,
        _uid = uid,
        super(const ShareState());

  final SharesRepository _shares;
  final String _uid;

  static const durations = ['1 Hour', '24 Hours', '7 Days', '30 Days'];

  void toggleCategory(ShareCategory category) {
    final next = Set<ShareCategory>.from(state.categories);
    if (!next.add(category)) next.remove(category);
    // Regenerating requires re-confirming, so clear any existing code.
    emit(state.copyWith(categories: next, status: ShareStatus.editing));
  }

  void setDuration(String duration) =>
      emit(state.copyWith(duration: duration, status: ShareStatus.editing));

  Duration get _durationValue => switch (state.duration) {
        '1 Hour' => const Duration(hours: 1),
        '7 Days' => const Duration(days: 7),
        '30 Days' => const Duration(days: 30),
        _ => const Duration(hours: 24),
      };

  /// Builds the payload from the patient's data, encrypts it under a freshly
  /// generated PIN, and logs the grant. Emits the QR string + PIN.
  Future<void> generate({
    required PatientProfile profile,
    required List<MedicalRecord> records,
  }) async {
    if (state.categories.isEmpty) {
      emit(state.copyWith(
        status: ShareStatus.error,
        errorMessage: 'Select at least one category to share.',
      ));
      return;
    }

    emit(state.copyWith(status: ShareStatus.generating));
    try {
      final expiresAt = DateTime.now().add(_durationValue);
      final payload = SharePayload.build(
        profile: profile,
        records: records,
        categories: state.categories,
        expiresAt: expiresAt,
      );
      final pin = _generatePin();
      final code = ShareCrypto.encryptToCode(payload.encode(), pin);

      await _shares.add(
        _uid,
        ShareGrant(
          id: '',
          recipientLabel: 'In-person QR',
          categories: state.categories.map((c) => c.id).toList(),
          createdAt: DateTime.now(),
          expiresAt: expiresAt,
        ),
      );

      emit(state.copyWith(status: ShareStatus.ready, code: code, pin: pin));
    } catch (_) {
      emit(state.copyWith(
        status: ShareStatus.error,
        errorMessage: 'Could not create the share. Please try again.',
      ));
    }
  }

  static String _generatePin() {
    final rand = Random.secure();
    return List.generate(4, (_) => rand.nextInt(10)).join();
  }
}
