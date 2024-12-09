import 'package:denomination/Models/dinomation_entry_model.dart';
import 'package:denomination/Services/Databasehelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:num_to_words/num_to_words.dart';
import 'package:share_plus/share_plus.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text('History'),
      ),
      body: FutureBuilder<List<DenominationEntry>>(
        future: DatabaseHelper.instance.getAllDenominationEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(
              'No history available.',
              style: TextStyle(color: Colors.white),
            ));
          } else {
            return ListView.separated(
              separatorBuilder: (context, index) {
                return Divider();
              },
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var entry = snapshot.data![index];
                return Slidable(
                  endActionPane: ActionPane(motion: StretchMotion(), children: [
                    SlidableAction(
                      label: 'Edit',
                      backgroundColor: Colors.blue,
                      icon: Icons.edit,
                      onPressed: (value) {},
                    ),
                    SlidableAction(
                      label: 'Delete',
                      backgroundColor: Colors.red,
                      icon: Icons.delete,
                      onPressed: (value) async {
                        // Implement delete functionality
                        await DatabaseHelper.instance
                            .deleteDenominationEntry(entry.id!);
                        print('Deleted entry ${entry.id}');
                        // You can refresh the screen by using setState or Navigator.pop to go back to previous screen
                      },
                    ),
                    SlidableAction(
                      label: 'Share',
                      backgroundColor: Colors.green,
                      icon: Icons.share,
                      onPressed: (value) {
                        // Create a string for the denominations details
                        String denominationsDetails = '';
                        for (var denomination in entry.denominations) {
                          denominationsDetails +=
                              '₹${denomination.noteType} x ${denomination.numberOfNotes} = ₹${denomination.totalValue}\n';
                        }

                        // Calculate the Grand Total
                        int grandTotal = entry.denominations
                            .fold(0, (sum, item) => sum + item.totalValue);

                        // Convert Grand Total to Words (using a package like flutter_num_words)
                        String totalValueInWords = grandTotal.toWords();

                        // Construct the full share content with Category, Denominations, Divider, Value in Words, and Grand Total
                        String content =
                            'Category: ${entry.category}\n\n' // Display Category first
                            'Denominations Details:\n'
                            '$denominationsDetails' // Show Denominations
                            '------------------------\n' // Divider
                            'Value in Words: $totalValueInWords\n' // Show Value in Words
                            'Grand Total: ₹$grandTotal'; // Show Grand Total

                        // Share the content
                        Share.share(content);
                      },
                    ),
                  ]),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    tileColor: Colors.white12,
                    title: Text(
                      'Total Value: ₹${entry.denominations.fold(0, (sum, item) => sum + item.totalValue)}',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Category: ${entry.category}\nDate: ${entry.date}\nRemarks: ${entry.remarks}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
