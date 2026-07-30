import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../data/cards_repository.dart';
import '../models/insurance_card.dart';

part 'cards_state.dart';

/// Streams the patient's insurance / ID cards.
class CardsCubit extends Cubit<CardsState> {
  CardsCubit({required CardsRepository repository, required String uid})
      : _repository = repository,
        _uid = uid,
        super(const CardsState()) {
    if (uid.isEmpty) {
      emit(state.copyWith(status: CardsStatus.ready));
      return;
    }
    _subscription = _repository.watchCards(uid).listen(
          (cards) => emit(
            state.copyWith(status: CardsStatus.ready, cards: cards),
          ),
          onError: (_) => emit(state.copyWith(status: CardsStatus.error)),
        );
  }

  final CardsRepository _repository;
  final String _uid;

  StreamSubscription<List<InsuranceCard>>? _subscription;

  Future<void> add(InsuranceCard card) => _repository.add(_uid, card);

  Future<void> update(InsuranceCard card) => _repository.update(_uid, card);

  Future<void> delete(InsuranceCard card) =>
      _repository.delete(_uid, card.id);

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
