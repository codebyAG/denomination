import 'package:denomination/Models/dinomation_entry_model.dart';
import 'package:denomination/Models/dinomination_model.dart';
import 'package:denomination/Services/Databasehelper.dart';
import 'package:denomination/history.dart';
import 'package:denomination/homepage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:num_to_words/num_to_words.dart';

class EditDenominationScreen extends StatefulWidget {
  final DenominationEntry entryToEdit;

  // Constructor to receive the entry to edit
  EditDenominationScreen({required this.entryToEdit});

  @override
  _EditDenominationScreenState createState() => _EditDenominationScreenState();
}

class _EditDenominationScreenState extends State<EditDenominationScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, int> _totalValues = {};
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // Note types (2000, 500, 200, etc.)
  final List<int> _noteTypes = [2000, 500, 200, 100, 50, 20, 10, 5, 2, 1];

  @override
  void initState() {
    super.initState();

    // Pre-fill data for editing
    _remarksController.text = widget.entryToEdit.remarks;
    _categoryController.text = widget.entryToEdit.category;

    for (int noteType in _noteTypes) {
      // Default note count to 0
      int noteCount = 0;

      // Iterate over the denominations to find the matching note type
      for (var denom in widget.entryToEdit.denominations) {
        if (denom.noteType == noteType) {
          noteCount = denom.numberOfNotes;
          break;
        }
      }

      // Initialize controllers and total values
      _controllers[noteType] =
          TextEditingController(text: noteCount.toString());
      _totalValues[noteType] = noteType * noteCount;
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

  void _showCategoryRemarksDialog(List<Denomination> denominations) {
    String selectedCategory = _categoryController.text;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Category and Remarks'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
                items: [
                  DropdownMenuItem(child: Text('General'), value: 'General'),
                  DropdownMenuItem(child: Text('Income'), value: 'Income'),
                  DropdownMenuItem(child: Text('Expense'), value: 'Expense'),
                ],
                decoration: InputDecoration(labelText: 'Category'),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _remarksController,
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
                    _remarksController.text.isNotEmpty) {
                  // Update the entry
                  DenominationEntry updatedEntry = DenominationEntry(
                    id: widget.entryToEdit.id,
                    date: widget.entryToEdit.date, // Keep the original date
                    remarks: _remarksController.text,
                    category: selectedCategory,
                    denominations: denominations,
                  );

                  DatabaseHelper.instance.updateDenominationEntry(updatedEntry);

                  Navigator.pop(context); // Close dialog
                  Get.offAll(() => HomePage());
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateDenominationEntry() async {
    List<Denomination> denominations = _noteTypes.map((noteType) {
      int numberOfNotes =
          int.tryParse(_controllers[noteType]?.text ?? '0') ?? 0;
      return Denomination(
        noteType: noteType,
        numberOfNotes: numberOfNotes,
        totalValue: noteType * numberOfNotes,
        entryId: widget.entryToEdit.denominations.first.entryId,
      );
    }).toList();

    _showCategoryRemarksDialog(denominations);
  }

  int _calculateIndividualTotalValue(int noteType) {
    int numberOfNotes = int.tryParse(_controllers[noteType]?.text ?? '0') ?? 0;
    int total = noteType * numberOfNotes;
    _totalValues[noteType] = total;
    return total;
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

  int get totalValue => _calculateTotalValue();

  String get totalValueInWords => totalValue.toWords();

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
                    Get.to(HistoryScreen());
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(Icons.history, color: Colors.black),
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
            expandedHeight: 200.0,
            toolbarHeight: 100,
            floating: false,
            pinned: true,
            centerTitle: false,
            backgroundColor: Colors.blue.shade900,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  totalValue > 0
                      ? Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Total Amount',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('₹${totalValue.toString()}',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('${totalValueInWords} only /-',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : Text('Denomination',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              titlePadding: EdgeInsets.all(10),
              background: Image.asset(
                'assets/images/currency_banner.jpg',
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
                                    width: 80,
                                    child: Text(
                                      '₹${noteType}  x',
                                      style: TextStyle(
                                          fontSize: 20, color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Container(
                                    width: 150,
                                    child: TextFormField(
                                      controller: _controllers[noteType],
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20),
                                      cursorHeight: 25,
                                      decoration: InputDecoration(
                                        fillColor: Colors.grey.withOpacity(0.5),
                                        filled: true,
                                        suffix: InkWell(
                                          onTap: () {
                                            _controllers[noteType]!.clear();
                                            setState(() {
                                              _calculateIndividualTotalValue(
                                                  noteType);
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.black,
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.white)),
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.white)),
                                        focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.white)),
                                        hintText: "",
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
                                  SizedBox(width: 10),
                                  Text(
                                    '= ₹${_totalValues[noteType]?.toStringAsFixed(0)}', // Display as integer
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
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
            _updateDenominationEntry(); // Update action
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
          child: Icon(Icons.edit),
        ),
      ),
    );
  }
}
