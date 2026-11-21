enum EntryType { credit, payment }

class LedgerEntry {
  final int? id;
  final int customerId;
  final EntryType type;
  final int amountRupees;
  final DateTime createdAt;
  final String? note;

  const LedgerEntry({
    this.id,
    required this.customerId,
    required this.type,
    required this.amountRupees,
    required this.createdAt,
    this.note,
  });
}