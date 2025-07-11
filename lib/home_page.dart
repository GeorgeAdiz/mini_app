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
  List filteredBooks = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  fetchBooks() async {
    try {
      var url = Uri.parse('http://192.168.193.252:3000/books');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          books = json.decode(response.body);
          applyFilter();
        });
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

  void applyFilter() {
    setState(() {
      if (searchQuery.isEmpty) {
        filteredBooks = List.from(books);
      } else {
        filteredBooks = books.where((book) {
          final title = (book['title'] ?? '').toString().toLowerCase();
          final author = (book['author'] ?? '').toString().toLowerCase();
          final category = (book['category'] ?? '').toString().toLowerCase();
          return title.contains(searchQuery) ||
              author.contains(searchQuery) ||
              category.contains(searchQuery);
        }).toList();
      }
    });
  }

  deleteBook(String id) async {
    try {
      var url = Uri.parse('http://192.168.193.252:3000/books/$id');
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

  Widget buildBookTile(Map book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              book['imageUrl'] ?? '',
              width: 60,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(width: 60, height: 90, color: Colors.grey[300], child: Icon(Icons.broken_image)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book['title'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            book['author'] ?? '',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Year: ${book['year']?.toString() ?? 'N/A'}",
                            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                          ),
                          Text(
                            "Category: ${book['category'] ?? 'N/A'}",
                            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: 22),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Book'),
                            content: Text('Do you want to delete this book?'),
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
                SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    if (book['source'] != null)
                      Chip(
                        label: Text(book['source'], style: TextStyle(fontSize: 11, color: Colors.white)),
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Library", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.orange),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.orange),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => AddBookPage()));
              fetchBooks();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search by title, author, or category",
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  searchQuery = value.toLowerCase();
                  applyFilter();
                },
              ),
            ),
            Expanded(
              child: filteredBooks.isEmpty
                  ? Center(child: Text("No books found"))
                  : ListView.builder(
                      itemCount: filteredBooks.length,
                      itemBuilder: (context, index) => buildBookTile(filteredBooks[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
