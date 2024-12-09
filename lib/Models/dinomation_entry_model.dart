import 'package:denomination/Models/dinomination_model.dart';

class DenominationEntry {
  int? id;
  String date;        // Date of the entry
  String remarks;     // Optional remarks
  String category;    // Optional category
  List<Denomination> denominations;  // List of Denominations

  DenominationEntry({
    this.id,
    required this.date,
    required this.remarks,
    required this.category,
    required this.denominations,
  });

  // Convert DenominationEntry to Map for SQLite insertion (without denominations)
  Map<String, dynamic> toMapWithoutDenominations() {
    return {
      'id': id,
      'date': date,
      'remarks': remarks,
      'category': category,
    };
  }

  // Extract DenominationEntry from Map with its Denominations
  factory DenominationEntry.fromMapWithDenominations(Map<String, dynamic> map, List<Denomination> denominations) {
    return DenominationEntry(
      id: map['id'],
      date: map['date'],
      remarks: map['remarks'],
      category: map['category'],
      denominations: denominations,
    );
  }
}
