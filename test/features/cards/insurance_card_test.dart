import 'package:flutter_test/flutter_test.dart';
import 'package:medi_carry/core/models/stored_attachment.dart';
import 'package:medi_carry/features/cards/models/insurance_card.dart';

InsuranceCard _card({
  InsuranceProvider provider = InsuranceProvider.rssb,
  String providerName = '',
  DateTime? validUntil,
  List<StoredAttachment> documents = const [],
}) =>
    InsuranceCard(
      id: 'c1',
      provider: provider,
      providerName: providerName,
      memberName: 'Sarah Johnson',
      memberNumber: 'RSSB-8829-41',
      policyNumber: 'POL-4471',
      scheme: 'Category 3',
      validUntil: validUntil,
      documents: documents,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('provider list', () {
    test('covers the Rwandan schemes patients actually carry', () {
      final labels =
          InsuranceProvider.values.map((p) => p.label).toList();
      expect(labels, containsAll(['RSSB', 'Mutuelle de Santé', 'RAMA', 'MMI']));
    });

    test('falls back to "other" for an unknown stored id', () {
      expect(InsuranceProvider.fromId('acme-health'), InsuranceProvider.other);
      expect(InsuranceProvider.fromId(null), InsuranceProvider.other);
      expect(InsuranceProvider.fromId('rama'), InsuranceProvider.rama);
    });
  });

  group('displayProvider', () {
    test('uses the enum label for a known provider', () {
      expect(_card().displayProvider, 'RSSB');
    });

    test('uses the free-text name for "other"', () {
      final card = _card(
        provider: InsuranceProvider.other,
        providerName: 'Acme Health',
      );
      expect(card.displayProvider, 'Acme Health');
    });

    test('falls back to the label when "other" has no name', () {
      final card = _card(provider: InsuranceProvider.other);
      expect(card.displayProvider, 'Other');
    });
  });

  group('validity', () {
    test('a card with no end date never expires', () {
      final card = _card();
      expect(card.isExpired, isFalse);
      expect(card.expiresSoon, isFalse);
      expect(card.validityLabel, isNull);
    });

    test('flags a past end date as expired', () {
      final card =
          _card(validUntil: DateTime.now().subtract(const Duration(days: 1)));
      expect(card.isExpired, isTrue);
      expect(card.expiresSoon, isFalse);
      expect(card.validityLabel, startsWith('Expired'));
    });

    test('warns within 30 days of expiry', () {
      final card =
          _card(validUntil: DateTime.now().add(const Duration(days: 10)));
      expect(card.isExpired, isFalse);
      expect(card.expiresSoon, isTrue);
      expect(card.validityLabel, startsWith('Valid to'));
    });

    test('does not warn well before expiry', () {
      final card =
          _card(validUntil: DateTime.now().add(const Duration(days: 200)));
      expect(card.expiresSoon, isFalse);
    });
  });

  test('round-trips through toMap/fromMap, documents included', () {
    final card = _card(
      validUntil: DateTime(2027, 12, 31),
      documents: const [
        StoredAttachment(
          url: 'https://cdn/card.jpg',
          name: 'card.jpg',
          kind: 'image',
          bytes: 204800,
        ),
      ],
    );

    final restored = InsuranceCard.fromMap('c1', card.toMap());

    expect(restored.provider, InsuranceProvider.rssb);
    expect(restored.memberNumber, 'RSSB-8829-41');
    expect(restored.policyNumber, 'POL-4471');
    expect(restored.scheme, 'Category 3');
    expect(restored.validUntil, DateTime(2027, 12, 31));
    expect(restored.documents, hasLength(1));
    expect(restored.documents.single.isImage, isTrue);
    expect(restored.documents.single.sizeLabel, '200 KB');
  });

  test('a card saved with no documents decodes to an empty list', () {
    final restored = InsuranceCard.fromMap('c1', {
      'provider': 'mutuelle',
      'memberNumber': '123',
    });
    expect(restored.documents, isEmpty);
    expect(restored.provider, InsuranceProvider.mutuelle);
    expect(restored.type, CardType.insurance);
  });
}
