part of 'share_cubit.dart';

enum ShareStatus { editing, generating, ready, error }

class ShareState extends Equatable {
  const ShareState({
    this.status = ShareStatus.editing,
    this.categories = const {ShareCategory.basicProfile},
    this.duration = '24 Hours',
    this.code,
    this.pin,
    this.errorMessage,
  });

  final ShareStatus status;
  final Set<ShareCategory> categories;
  final String duration;

  /// The encrypted QR string, once generated.
  final String? code;

  /// The PIN the patient reads aloud to the recipient.
  final String? pin;

  final String? errorMessage;

  bool isSelected(ShareCategory c) => categories.contains(c);

  ShareState copyWith({
    ShareStatus? status,
    Set<ShareCategory>? categories,
    String? duration,
    String? code,
    String? pin,
    String? errorMessage,
  }) =>
      ShareState(
        status: status ?? this.status,
        categories: categories ?? this.categories,
        duration: duration ?? this.duration,
        code: code ?? this.code,
        pin: pin ?? this.pin,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, categories, duration, code, pin, errorMessage];
}
