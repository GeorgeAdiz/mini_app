import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

class AddBookPage extends StatefulWidget {
  @override
  _AddBookPageState createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  String selectedCategory = 'Romance';
  final List<String> categories = [
    'Romance',
    'Horror',
    'Fantasy',
    'Mystery',
    'Science Fiction',
    'Non-fiction'
  ];

  // 📸 Pick image from gallery
  Future<void> pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 📤 Upload book with image
  Future<void> addBook() async {
    final String title = titleController.text.trim();
    final String author = authorController.text.trim();
    final String year = yearController.text.trim();

    if (title.isEmpty || author.isEmpty || year.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    if (int.tryParse(year) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Year must be a valid number')),
      );
      return;
    }

    var uri = Uri.parse('http://192.168.193.252:3000/books');
    var request = http.MultipartRequest('POST', uri);

    request.fields['title'] = title;
    request.fields['author'] = author;
    request.fields['year'] = year;
    request.fields['category'] = selectedCategory;

    if (_imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', _imageFile!.path),
      );
    }

    try {
      var response = await request.send();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Book added successfully')),
        );
        Navigator.pop(context);
      } else {
        final respStr = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${response.statusCode}')),
        );
        print('Upload failed: $respStr');
      }
    } catch (e) {
      print('Error uploading book: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading book')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Book", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.orange),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: authorController,
              decoration: InputDecoration(labelText: "Author"),
            ),
            TextField(
              controller: yearController,
              decoration: InputDecoration(labelText: "Year"),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => selectedCategory = val);
              },
              decoration: InputDecoration(labelText: "Category"),
            ),
            SizedBox(height: 20),
            _imageFile == null
                ? Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[200],
                    child: Icon(Icons.photo, size: 40, color: Colors.grey),
                  )
                : Image.file(_imageFile!,
                    width: 120, height: 120, fit: BoxFit.cover),
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: Icon(Icons.photo),
              label: Text("Pick Image"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: addBook,
              child: Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
