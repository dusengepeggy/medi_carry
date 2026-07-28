import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../data/records_repository.dart';
import '../models/medical_record.dart';

part 'records_state.dart';

/// Streams the patient's records and owns the Records screen's filter + search.
/// The filtering that used to live inline in the screen moves here.
class RecordsCubit extends Cubit<RecordsState> {
  RecordsCubit({
    required RecordsRepository repository,
    required String uid,
  })  : _repository = repository,
        super(const RecordsState()) {
    _subscription = _repository.watchRecords(uid).listen(
          (records) => emit(state.copyWith(
            status: RecordsStatus.ready,
            records: records,
          )),
          onError: (_) => emit(state.copyWith(status: RecordsStatus.error)),
        );
  }

  final RecordsRepository _repository;
  late final StreamSubscription<List<MedicalRecord>> _subscription;

  void selectFilter(String filter) => emit(state.copyWith(filter: filter));

  void search(String query) => emit(state.copyWith(query: query));

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
