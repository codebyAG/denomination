import 'package:denomination/Models/dinomation_entry_model.dart';
import 'package:denomination/Models/dinomination_model.dart';
import 'package:denomination/Services/Databasehelper.dart';
import 'package:denomination/history.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:num_to_words/num_to_words.dart';

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

  // Show dialog for category and remarks before saving
  void _showCategoryRemarksDialog(List<Denomination> denominations) {
    String selectedCategory = 'General'; // Default category
    TextEditingController remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Category and Remarks'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category Dropdown
              DropdownButtonFormField<String>(
                value: selectedCategory,
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
                items: [
                  DropdownMenuItem(child: Text('General'), value: 'General'),
                  DropdownMenuItem(child: Text('Festival'), value: 'Festival'),
                  DropdownMenuItem(child: Text('Others'), value: 'Others'),
                ],
                decoration: InputDecoration(labelText: 'Category'),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              // Remarks Text Field
              TextFormField(
                controller: remarksController,
                decoration: InputDecoration(labelText: 'Remarks'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter remarks';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (selectedCategory.isNotEmpty &&
                    remarksController.text.isNotEmpty) {
                  // If both category and remarks are filled, save the data
                  DenominationEntry newEntry = DenominationEntry(
                    date: DateFormat("d MMMM, yyyy, h:mm a")
                        .format(DateTime.now()), // Current date
                    remarks: remarksController.text,
                    category: selectedCategory,
                    denominations: denominations,
                  );

                  // Save the data to the database
                  DatabaseHelper.instance.insertDenominationEntry(newEntry);

                  // Close the dialog
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Add Denomination Entry and show dialog to enter category and remarks
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

    // Show dialog for category and remarks after collecting all denominations
    _showCategoryRemarksDialog(denominations);
  }

  void _clearFields() {
    _formKey.currentState?.reset(); // Resets the form
    _remarksController.clear(); // Clear remarks field
    _categoryController.clear(); // Clear category field
    _controllers.forEach((key, value) {
      value.clear(); // Clear the note type text fields
    });
    for (int noteType in _noteTypes) {
      _totalValues[noteType] = 0; // Initialize total values as integers
    }
    setState(() {}); // Trigger a rebuild to update the UI
  }

  // Calculate individual total value for each note type
  int _calculateIndividualTotalValue(int noteType) {
    int numberOfNotes = int.tryParse(_controllers[noteType]?.text ?? '0') ?? 0;
    int total = noteType * numberOfNotes;
    _totalValues[noteType] = total;
    return total;
  }

  // Calculate Total Price and Total Value
  int get totalValue {
    int totalValue = 0;
    _controllers.forEach((noteType, controller) {
      if (controller.text.isNotEmpty) {
        int numberOfNotes = int.tryParse(controller.text) ?? 0;
        totalValue += numberOfNotes * noteType;
      }
    });
    return totalValue;
  }

// Convert total value to words
  String get totalValueInWords {
    return totalValue.toWords(); // Convert totalValue to words
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'history') {
                    Get.to(
                        HistoryScreen()); // Navigate to HistoryScreen when History is selected
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.black,
                          ),
                          SizedBox(width: 8),
                          Text('History'),
                        ],
                      ),
                    ),
                  ];
                },
                icon: Icon(Icons.more_vert_rounded),
              ),
            ],

            expandedHeight: 200.0, // Height when expanded
            floating: false,
            pinned: true, // Keeps the app bar visible when collapsed
            centerTitle: false,
            backgroundColor: Colors.blue.shade900,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  totalValue > 0
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total Amount',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 2,
                            ),
                            Text(
                              '₹${totalValue.toString()}',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 2,
                            ),
                            Text(
                              '${totalValueInWords} only /-',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : Text(
                          'Denomination', // Static title when total value is 0
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
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
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _controllers[noteType],
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.white)),
                                          enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.white)),
                                          focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.white)),
                                          labelText: 'Enter Number of Notes',
                                          labelStyle:
                                              TextStyle(color: Colors.white)),
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
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'save') {
            _addDenominationEntry(); // Save action
          } else if (value == 'clear') {
            _clearFields(); // Clear action
          }
        },
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem<String>(
              value: 'save',
              child: Row(
                children: [
                  Icon(Icons.save),
                  SizedBox(width: 8),
                  Text('Save'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.clear),
                  SizedBox(width: 8),
                  Text('Clear'),
                ],
              ),
            ),
          ];
        },
        child: FloatingActionButton(
          onPressed: null, // No action needed when FAB itself is pressed
          tooltip: 'Actions',
          child: Icon(Icons.touch_app_rounded),
        ),
      ),
    );
  }
}
