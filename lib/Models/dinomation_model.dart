class Denomination {
  int? id;
  int noteType;      // Type of the note, e.g., 2000, 100
  int numberOfNotes; // Number of notes
  double totalValue; // Total value (noteType * numberOfNotes)

  Denomination({
    this.id,
    required this.noteType,
    required this.numberOfNotes,
    required this.totalValue,
  });

  // Convert a Denomination into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteType': noteType,
      'numberOfNotes': numberOfNotes,
      'totalValue': totalValue,
    };
  }

  // Extract a Denomination from a Map
  factory Denomination.fromMap(Map<String, dynamic> map) {
    return Denomination(
      id: map['id'],
      noteType: map['noteType'],
      numberOfNotes: map['numberOfNotes'],
      totalValue: map['totalValue'],
    );
  }
}
