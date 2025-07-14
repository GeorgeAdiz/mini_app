import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const kBg = Color(0xFF222831);
const kCard = Color(0xFF393E46);
const kTeal = Color(0xFF00BFCB);
const kLight = Color(0xFFEEEEEE);

class AddBookPage extends StatefulWidget {
  final Map? book;
  const AddBookPage({Key? key, this.book}) : super(key: key);
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

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      titleController.text = widget.book!['title'] ?? '';
      authorController.text = widget.book!['author'] ?? '';
      yearController.text = widget.book!['year']?.toString() ?? '';
      selectedCategory = widget.book!['category'] ?? selectedCategory;
    }
  }

  Future<void> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kCard,
          content: Row(
            children: [
              CircularProgressIndicator(color: kTeal),
              SizedBox(width: 20),
              Text('Uploading book...', style: TextStyle(color: kLight)),
            ],
          ),
        );
      },
    );

    List<String> possibleUrls = [
      'http://192.168.194.4:3000/books',
      'http://192.168.193.252:3000/books',
      'http://10.0.2.2:3000/books',
      'http://localhost:3000/books',
      'http://127.0.0.1:3000/books',
    ];
    
    http.MultipartRequest? request;
    String? workingUrl;
    
    for (String urlString in possibleUrls) {
      try {
        var uri = Uri.parse(urlString);
        var testResponse = await http.get(uri).timeout(Duration(seconds: 5));
        
        if (testResponse.statusCode == 200 || testResponse.statusCode == 404) {
          workingUrl = urlString;
          request = http.MultipartRequest('POST', uri);
          break;
        }
      } catch (e) {
        continue;
      }
    }
    
    if (request == null || workingUrl == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not connect to server'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

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
      final respStr = await response.stream.bytesToString();

      Navigator.pop(context);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Book added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading book'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> saveBook() async {
    if (widget.book != null) {
      await updateBook();
    } else {
      await addBook();
    }
  }

  Future<void> updateBook() async {
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
    
    List<String> possibleUrls = [
      'http://192.168.194.4:3000/books/${widget.book!['_id']}',
      'http://192.168.193.252:3000/books/${widget.book!['_id']}',
      'http://10.0.2.2:3000/books/${widget.book!['_id']}',
      'http://localhost:3000/books/${widget.book!['_id']}',
    ];
    
    http.MultipartRequest? request;
    String? workingUrl;
    
    for (String urlString in possibleUrls) {
      try {
        var uri = Uri.parse(urlString);
        var testRequest = http.MultipartRequest('PUT', uri);
        testRequest.fields['title'] = title;
        testRequest.fields['author'] = author;
        testRequest.fields['year'] = year;
        testRequest.fields['category'] = selectedCategory;
        
        if (_imageFile != null) {
          testRequest.files.add(
            await http.MultipartFile.fromPath('image', _imageFile!.path),
          );
        }
        
        var testResponse = await http.get(uri).timeout(Duration(seconds: 3));
        if (testResponse.statusCode == 200 || testResponse.statusCode == 404) {
          workingUrl = urlString;
          request = testRequest;
          break;
        }
      } catch (e) {
        continue;
      }
    }
    
    if (request == null || workingUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not connect to server')),
      );
      return;
    }
    
    try {
      var response = await request.send();
      final respStr = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Book updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating book'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.book != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Book" : "Add Book", style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 26)),
        backgroundColor: kBg,
        iconTheme: IconThemeData(color: kTeal),
        elevation: 0,
      ),
      body: Container(
        color: kBg,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Card(
              elevation: 6,
              color: kCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(isEdit ? "Edit Book Details" : "Book Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kLight)),
                    Divider(height: 32, thickness: 1.2, color: kTeal),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: kLight, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(labelText: "Title", labelStyle: TextStyle(color: kTeal, fontWeight: FontWeight.bold), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: kCard),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: authorController,
                      style: TextStyle(color: kLight, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(labelText: "Author", labelStyle: TextStyle(color: kTeal, fontWeight: FontWeight.bold), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: kCard),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: yearController,
                      style: TextStyle(color: kLight, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(labelText: "Year", labelStyle: TextStyle(color: kTeal, fontWeight: FontWeight.bold), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: kCard),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: kLight, fontWeight: FontWeight.bold))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedCategory = val);
                      },
                      decoration: InputDecoration(labelText: "Category", labelStyle: TextStyle(color: kTeal, fontWeight: FontWeight.bold), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: kCard),
                      dropdownColor: kTeal,
                    ),
                    SizedBox(height: 24),
                    Text("Book Cover", style: TextStyle(fontWeight: FontWeight.w600, color: kLight, fontSize: 16)),
                    SizedBox(height: 10),
                    Center(
                      child: _imageFile == null
                          ? Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: kTeal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: kTeal, width: 2),
                              ),
                              child: Icon(Icons.photo, size: 40, color: kTeal),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: kTeal, width: 2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Image.file(_imageFile!, width: 120, height: 120, fit: BoxFit.cover),
                              ),
                            ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: pickImage,
                      icon: Icon(Icons.photo, color: kCard),
                      label: Text("Pick Image", style: TextStyle(color: kCard, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTeal,
                        shape: StadiumBorder(),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    SizedBox(height: 24),
                    Divider(height: 24, thickness: 1.2, color: kTeal),
                    ElevatedButton(
                      onPressed: saveBook,
                      child: Text(isEdit ? "Update" : "Submit", style: TextStyle(fontWeight: FontWeight.bold, color: kBg, fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTeal,
                        shape: StadiumBorder(),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
