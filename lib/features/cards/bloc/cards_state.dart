part of 'cards_cubit.dart';

enum CardsStatus { loading, ready, error }

class CardsState extends Equatable {
  const CardsState({this.status = CardsStatus.loading, this.cards = const []});

  final CardsStatus status;
  final List<InsuranceCard> cards;

  /// Cards that are still valid, expiring ones first so a card that needs
  /// renewing before the next visit is the one the patient sees.
  List<InsuranceCard> get valid {
    final list = cards.where((c) => !c.isExpired).toList();
    list.sort((a, b) {
      final aUntil = a.validUntil;
      final bUntil = b.validUntil;
      if (aUntil == null && bUntil == null) return 0;
      if (aUntil == null) return 1;
      if (bUntil == null) return -1;
      return aUntil.compareTo(bUntil);
    });
    return list;
  }

  List<InsuranceCard> get expired =>
      cards.where((c) => c.isExpired).toList();

  CardsState copyWith({CardsStatus? status, List<InsuranceCard>? cards}) =>
      CardsState(status: status ?? this.status, cards: cards ?? this.cards);

  @override
  List<Object?> get props => [status, cards];
}
