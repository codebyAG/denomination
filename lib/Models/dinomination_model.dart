class Denomination {
  int noteType;
  int numberOfNotes;
  int totalValue; // Make totalValue an integer
  int entryId; // Foreign key linking to DenominationEntry

  Denomination({
    required this.noteType,
    required this.numberOfNotes,
    required this.totalValue, // Integer total value
    required this.entryId,
  });

  // Convert Denomination to Map for SQLite insertion with entryId
  Map<String, dynamic> toMapWithEntryId(int entryId) {
    return {
      'noteType': noteType,
      'numberOfNotes': numberOfNotes,
      'totalValue': totalValue, // Store as integer
      'entryId': entryId,
    };
  }

  // Extract Denomination from Map
  factory Denomination.fromMap(Map<String, dynamic> map) {
    return Denomination(
      noteType: map['noteType'],
      numberOfNotes: map['numberOfNotes'],
      totalValue: map['totalValue'], // Read totalValue as integer
      entryId: map['entryId'],
    );
  }
}
