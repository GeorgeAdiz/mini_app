import 'package:flutter/material.dart';
import 'add_book_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List books = [];
  Map<String, List> groupedBooks = {};

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  fetchBooks() async {
    try {
      var url = Uri.parse('http://localhost:3000/books');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        books = json.decode(response.body);
        groupBooksByCategory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load books: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void groupBooksByCategory() {
    groupedBooks.clear();
    for (var book in books) {
      String category = book['category'] ?? 'Others';
      if (!groupedBooks.containsKey(category)) {
        groupedBooks[category] = [];
      }
      groupedBooks[category]!.add(book);
    }
    setState(() {});
  }

  deleteBook(String id) async {
    try {
      var url = Uri.parse('http://localhost:3000/books/$id');
      var response = await http.delete(url);
      if (response.statusCode == 200) {
        fetchBooks();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Book deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete book: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget buildBookCover(Map book) {
    return Container(
      width: 120,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 240, // Fixed height for all cards
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio: 0.65,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book['imageUrl'] != null && book['imageUrl'].toString().isNotEmpty
                      ? Image.network(
                          book['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[300], child: Icon(Icons.broken_image, size: 40)),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.book, size: 40, color: Colors.blue),
                        ),
                ),
              ),
              SizedBox(height: 4),
              // Scrollable text area for title and author
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        book['title'] ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        book['author'] ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red, size: 22),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete Book'),
                      content: Text('You want to delete this book?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    deleteBook(book['_id']);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Books")),
      body: groupedBooks.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.only(bottom: 16),
              children: groupedBooks.entries.map((entry) {
                final category = entry.key;
                final booksInCategory = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        category,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: booksInCategory.map((book) => buildBookCover(book)).toList(),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
              context, MaterialPageRoute(builder: (_) => AddBookPage()));
          fetchBooks();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
