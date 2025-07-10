import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddBookPage extends StatefulWidget {
  @override
  _AddBookPageState createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final titleController = TextEditingController();
  final authorController = TextEditingController();

  addBook() async {
    var url = Uri.parse('http://localhost:3000/books'); //Use 10.0.2.2 for Android Emulator

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': titleController.text,
        'author': authorController.text,
      }),
    );

    if (response.statusCode == 201) {
      Navigator.pop(context); // Go back to homepage
    } else {
      print('Error: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Book")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: "Title")),
            TextField(controller: authorController, decoration: InputDecoration(labelText: "Author")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: addBook, child: Text("Submit")),
          ],
        ),
      ),
    );
  }
}
