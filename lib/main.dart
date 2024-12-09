import 'package:denomination/Models/dinomation_model.dart';
import 'package:denomination/Services/Databasehelper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  // Note types (2000, 500, 200, etc.)
  final List<int> _noteTypes = [2000, 500, 200, 100, 50, 20, 10, 5, 2, 1];

  // Initialize text controllers for each note type
  @override
  void initState() {
    super.initState();
    for (int noteType in _noteTypes) {
      _controllers[noteType] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }

  // Calculate total value
  double _calculateTotalValue() {
    double totalValue = 0.0;
    _controllers.forEach((noteType, controller) {
      if (controller.text.isNotEmpty) {
        int numberOfNotes = int.tryParse(controller.text) ?? 0;
        totalValue += numberOfNotes * noteType;
      }
    });
    return totalValue;
  }

  // Add the denomination to the database
  Future<void> _addDenomination() async {
    if (_formKey.currentState?.validate() ?? false) {
      double totalValue = _calculateTotalValue();

      // Insert into the database
      Denomination newDenomination = Denomination(
        noteType: 0, // This is not necessary but included for simplicity
        numberOfNotes: 0, // This is not necessary but included for simplicity
        totalValue: totalValue,
      );

      // Save to database
      await DatabaseHelper.instance.insertDenomination(newDenomination);

      // Reset form after submission
      _formKey.currentState?.reset();
      setState(() {});
    }
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
                              child: TextFormField(
                                controller: _controllers[noteType],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Number of ${noteType} notes',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value!.isNotEmpty &&
                                      int.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _addDenomination,
                        child: Text('Submit Denomination'),
                      ),
                      SizedBox(height: 30),
                      FutureBuilder<List<Denomination>>(
                        future: DatabaseHelper.instance.getAllDenominations(),
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
                                child: Text('No denominations available.'));
                          } else {
                            return Column(
                              children: snapshot.data!
                                  .map((denomination) => ListTile(
                                        title: Text(
                                            'Total Value: ₹${denomination.totalValue}'),
                                        subtitle: Text(
                                            'Details: ${denomination.totalValue}'),
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
