import 'package:denomination/Models/dinomation_entry_model.dart';
import 'package:denomination/Services/Databasehelper.dart';
import 'package:flutter/material.dart';

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
                return ListTile(
                  title: Text(
                    'Total Value: ₹${entry.denominations.fold(0, (sum, item) => sum + item.totalValue)}',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Category: ${entry.category}\nDate: ${entry.date}\nRemarks: ${entry.remarks}',
                    style: TextStyle(color: Colors.white),
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
