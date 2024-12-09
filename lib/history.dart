import 'dart:developer';

import 'package:denomination/Models/dinomation_entry_model.dart';
import 'package:denomination/Services/Databasehelper.dart';
import 'package:denomination/edit_denomination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:num_to_words/num_to_words.dart';
import 'package:share_plus/share_plus.dart';

class HistoryScreen extends StatefulWidget {
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future _showDeleteDialog(BuildContext context, String entryId) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure you want to delete this entry?'),
          content: Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // User pressed No
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () async {
                // User pressed Yes, delete the entry by its ID
                await DatabaseHelper.instance
                    .deleteDenominationEntry(int.parse(entryId.toString()));

                Navigator.of(context).pop(); // Close dialog after confirming
                setState(() {});
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

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
      body: new FutureBuilder<List<DenominationEntry>>(
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
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Slidable(
                      startActionPane:
                          ActionPane(motion: StretchMotion(), children: [
                        SlidableAction(
                          label: 'Edit',
                          backgroundColor: Colors.blue,
                          icon: Icons.edit,
                          onPressed: (value) {
                            log(entry.denominations.first.entryId.toString());
                            log(snapshot.data!.first.denominations.first.entryId
                                .toString());
                            Get.to(EditDenominationScreen(entryToEdit: entry));
                            // Implement edit functionality here
                          },
                        ),
                        SlidableAction(
                            label: 'Delete',
                            backgroundColor: Colors.red,
                            icon: Icons.delete,
                            onPressed: (value) async {
                              // Show confirmation dialog before deleting
                              _showDeleteDialog(context,
                                  entry.denominations.first.entryId.toString());
                            }),
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
                                '${entry.category}\n' // Display Category first
                                'Denominations\n'
                                '${entry.date}\n\n'
                                '------------------------\n' // Divider
                                'Rupees X Counts = Total\n'
                                '$denominationsDetails' // Show Denominations
                                '------------------------\n' // Divider
                                'Grand Total: ₹$grandTotal\n' // Show Grand Total
                                '$totalValueInWords'; // Show Value in Words

                            // Share the content
                            Share.share(content);
                          },
                        ),
                      ]),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.blue.shade800.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${entry.category}",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15),
                                  ),
                                  Text(
                                    "${entry.date}",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text(
                                '₹ ${entry.denominations.fold(0, (sum, item) => sum + item.totalValue)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 28),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text(
                                "${entry.remarks}",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      )),
                );
              },
            );
          }
        },
      ),
    );
  }
}
