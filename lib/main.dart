import 'package:denomination/Models/dinomation_entry_model.dart';
import 'package:denomination/Models/dinomination_model.dart';
import 'package:denomination/Services/Databasehelper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For formatting date

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, int> _totalValues = {}; // Change to int for totalValue
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // Note types (2000, 500, 200, etc.)
  final List<int> _noteTypes = [2000, 500, 200, 100, 50, 20, 10, 5, 2, 1];

  // Initialize text controllers for each note type
  @override
  void initState() {
    super.initState();
    for (int noteType in _noteTypes) {
      _controllers[noteType] = TextEditingController();
      _totalValues[noteType] = 0; // Initialize total values as integers
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, value) {
      value.dispose();
    });
    _remarksController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // Calculate the total value for each note type
  int _calculateTotalValue() {
    int totalValue = 0;
    _controllers.forEach((noteType, controller) {
      if (controller.text.isNotEmpty) {
        int numberOfNotes = int.tryParse(controller.text) ?? 0;
        totalValue += numberOfNotes * noteType;
      }
    });
    return totalValue;
  }

  Future<void> _addDenominationEntry() async {
    List<Denomination> denominations = _noteTypes.map((noteType) {
      int numberOfNotes =
          int.tryParse(_controllers[noteType]?.text ?? '0') ?? 0;
      return Denomination(
        noteType: noteType,
        numberOfNotes: numberOfNotes,
        totalValue: noteType * numberOfNotes, // totalValue as integer
        entryId: 0, // entryId will be assigned after insertion
      );
    }).toList();

    DenominationEntry newEntry = DenominationEntry(
      date: DateFormat("d MMMM, yyyy, h:mm a")
          .format(DateTime.now()), // Current date
      remarks: _remarksController.text,
      category: _categoryController.text,
      denominations: denominations,
    );

    await DatabaseHelper.instance
        .insertDenominationEntry(newEntry); // Insert into the database
  }

  // Calculate individual total value for each note type
  int _calculateIndividualTotalValue(int noteType) {
    int numberOfNotes = int.tryParse(_controllers[noteType]?.text ?? '0') ?? 0;
    int total = noteType * numberOfNotes;
    _totalValues[noteType] = total;
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0, // Height when expanded
            floating: false,
            pinned: true, // Keeps the app bar visible when collapsed
            centerTitle: false,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Denomination'),
                ],
              ),
              titlePadding: EdgeInsets.all(10),
              background: Image.asset(
                'assets/images/currency_banner.jpg', // Replace with your image URL
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          children: _noteTypes.map((noteType) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    child: Text(
                                      '₹${noteType}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _controllers[noteType],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Enter Number of Notes',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _calculateIndividualTotalValue(
                                              noteType);
                                        });
                                      },
                                      validator: (value) {
                                        if (value!.isNotEmpty &&
                                            int.tryParse(value) == null) {
                                          return 'Please enter a valid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    '₹${_totalValues[noteType]?.toStringAsFixed(0)}', // Display as integer
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Remarks Field
                      TextFormField(
                        controller: _remarksController,
                        decoration: InputDecoration(
                          labelText: 'Remarks (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      // Category Field
                      TextFormField(
                        controller: _categoryController,
                        decoration: InputDecoration(
                          labelText: 'Category (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _addDenominationEntry,
                        child: Text('Submit Denomination Entry'),
                      ),
                      SizedBox(height: 30),
                      // Display Denomination Entries from the database
                      FutureBuilder<List<DenominationEntry>>(
                        future:
                            DatabaseHelper.instance.getAllDenominationEntries(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Center(
                                child:
                                    Text('No denomination entries available.'));
                          } else {
                            return Column(
                              children: snapshot.data!
                                  .map((entry) => ListTile(
                                        title: Text(
                                            'Total Value: ₹${entry.denominations.fold(0, (sum, item) => sum + item.totalValue)}'),
                                        subtitle: Text(
                                            'Category: ${entry.category}\nDate: ${entry.date}\nRemarks: ${entry.remarks}'),
                                      ))
                                  .toList(),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
