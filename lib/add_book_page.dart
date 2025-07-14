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

  Set<String> selectedCategories = {};
  final List<String> categories = [
    'Romance',
    'Horror',
    'Fantasy',
    'Mystery',
    'Comedy',
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
      // Handle both single category (old format) and multiple categories (new format)
      if (widget.book!['category'] != null) {
        if (widget.book!['category'] is List) {
          selectedCategories = Set<String>.from(widget.book!['category']);
        } else {
          selectedCategories = {widget.book!['category']};
        }
      }
    }
  }

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

    // Try multiple possible IP addresses
    List<String> possibleUrls = [
      'http://192.168.194.4:3000/books',
      'http://10.0.2.2:3000/books', // Android emulator localhost
      'http://localhost:3000/books',
    ];
    
    http.MultipartRequest? request;
    String? workingUrl;
    
    for (String urlString in possibleUrls) {
      try {
        print('Trying to upload to: $urlString');
        var uri = Uri.parse(urlString);
        var testRequest = http.MultipartRequest('POST', uri);
        
        // Test the connection first
        var testResponse = await http.get(uri).timeout(Duration(seconds: 3));
        if (testResponse.statusCode == 200 || testResponse.statusCode == 404) {
          workingUrl = urlString;
          request = testRequest;
          print('Successfully connected to: $workingUrl');
          break;
        }
      } catch (e) {
        print('Failed to connect to $urlString: $e');
        continue;
      }
    }
    
    if (request == null || workingUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not connect to server')),
      );
      return;
    }

    request.fields['title'] = title;
    request.fields['author'] = author;
    request.fields['year'] = year;
    request.fields['category'] = selectedCategories.join(',');

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
      'http://10.0.2.2:3000/books/${widget.book!['_id']}',
      'http://localhost:3000/books/${widget.book!['_id']}',
    ];
    http.MultipartRequest? request;
    String? workingUrl;
    for (String urlString in possibleUrls) {
      try {
        var uri = Uri.parse(urlString);
        var testRequest = http.MultipartRequest('PUT', uri);
        // Always add all fields as strings
        testRequest.fields['title'] = title;
        testRequest.fields['author'] = author;
        testRequest.fields['year'] = year;
        testRequest.fields['category'] = selectedCategories.join(',');
        if (_imageFile != null) {
          testRequest.files.add(
            await http.MultipartFile.fromPath('image', _imageFile!.path),
          );
        }
        // Test connection with GET
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
      print('Update response: $respStr');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Book updated successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${response.statusCode}')),
        );
        print('Update failed: $respStr');
      }
    } catch (e) {
      print('Error updating book: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating book')),
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
                    Text("Categories", style: TextStyle(fontWeight: FontWeight.w600, color: kLight, fontSize: 16)),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: kTeal, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                        color: kCard,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategories.isEmpty ? null : selectedCategories.first,
                          isExpanded: true,
                          dropdownColor: kCard,
                          style: TextStyle(
                            color: kLight,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                          icon: Icon(Icons.arrow_drop_down, color: kTeal),
                          hint: Text(
                            selectedCategories.isEmpty 
                              ? "Select categories" 
                              : "${selectedCategories.length} selected",
                            style: TextStyle(color: kLight.withOpacity(0.7)),
                          ),
                          items: [
                            ...categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Row(
                                  children: [
                                    Icon(
                                      selectedCategories.contains(category) 
                                        ? Icons.check_box 
                                        : Icons.check_box_outline_blank,
                                      color: kTeal,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          color: kLight,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                if (selectedCategories.contains(newValue)) {
                                  selectedCategories.remove(newValue);
                                } else {
                                  selectedCategories.add(newValue);
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    if (selectedCategories.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: selectedCategories.map((category) => Chip(
                          label: Text(
                            category,
                            style: TextStyle(color: kBg, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          backgroundColor: kTeal,
                          shape: StadiumBorder(),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          deleteIcon: Icon(Icons.close, color: kBg, size: 16),
                          onDeleted: () {
                            setState(() {
                              selectedCategories.remove(category);
                            });
                          },
                        )).toList(),
                      ),
                    ],
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
