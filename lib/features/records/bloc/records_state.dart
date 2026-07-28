part of 'records_cubit.dart';

enum RecordsStatus { loading, ready, error }

class RecordsState extends Equatable {
  const RecordsState({
    this.status = RecordsStatus.loading,
    this.records = const [],
    this.filter = 'All',
    this.query = '',
  });

  final RecordsStatus status;
  final List<MedicalRecord> records;

  /// The active category chip: 'All', 'Diagnoses', 'Medications', 'Labs'.
  final String filter;
  final String query;

  /// Which [RecordCategory] each chip maps to (null = All).
  static const _filterCategory = {
    'Diagnoses': RecordCategory.diagnosis,
    'Medications': RecordCategory.medication,
    'Labs': RecordCategory.labResult,
  };

  /// Records after the active filter + search are applied.
  List<MedicalRecord> get visibleRecords {
    final q = query.trim().toLowerCase();
    final category = _filterCategory[filter];
    return records.where((r) {
      final matchesFilter = category == null || r.category == category;
      final matchesQuery = q.isEmpty ||
          r.title.toLowerCase().contains(q) ||
          r.provider.toLowerCase().contains(q) ||
          r.detail.toLowerCase().contains(q);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  bool get isEmpty => status == RecordsStatus.ready && records.isEmpty;

  RecordsState copyWith({
    RecordsStatus? status,
    List<MedicalRecord>? records,
    String? filter,
    String? query,
  }) =>
      RecordsState(
        status: status ?? this.status,
        records: records ?? this.records,
        filter: filter ?? this.filter,
        query: query ?? this.query,
      );

  @override
  List<Object?> get props => [status, records, filter, query];
}
