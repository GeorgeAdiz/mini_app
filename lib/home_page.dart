import 'package:flutter/material.dart';
import 'add_book_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

const kBg = Color(0xFF222831);
const kCard = Color(0xFF393E46);
const kTeal = Color(0xFF00BFCB);
const kLight = Color(0xFFEEEEEE);

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
    testNetworkConnection();
    fetchBooks();
  }

  Future<void> testNetworkConnection() async {
    try {
      var url = Uri.parse('http://192.168.194.4:3000/books');
      var response = await http.get(url).timeout(Duration(seconds: 5));
    } catch (e) {
      // Network test failed silently
    }
  }

  fetchBooks() async {
    try {
      List<String> possibleUrls = [
        'http://192.168.194.4:3000/books',
        'http://192.168.193.252:3000/books',
        'http://10.0.2.2:3000/books',
        'http://localhost:3000/books',
        'http://192.168.1.100:3000/books',
        'http://192.168.0.100:3000/books',
        'http://172.20.10.1:3000/books',
        'http://192.168.43.1:3000/books',
      ];
      
      http.Response? response;
      String? workingUrl;
      
      for (String urlString in possibleUrls) {
        try {
          var url = Uri.parse(urlString);
          response = await http.get(url).timeout(
            Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Request timed out', Duration(seconds: 5));
            },
          );
          
          if (response.statusCode == 200) {
            workingUrl = urlString;
            break;
          }
        } catch (e) {
          continue;
        }
      }
      
      if (response == null || workingUrl == null) {
        throw Exception('Could not connect to any server');
      }
      
      if (response.statusCode == 200) {
        var decodedBooks = json.decode(response.body);
        setState(() {
          books = decodedBooks;
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
      List<String> possibleUrls = [
        'http://192.168.194.4:3000/books/$id',
        'http://192.168.193.252:3000/books/$id',
        'http://10.0.2.2:3000/books/$id',
        'http://localhost:3000/books/$id',
      ];
      
      http.Response? response;
      String? workingUrl;
      
      for (String urlString in possibleUrls) {
        try {
          var url = Uri.parse(urlString);
          response = await http.delete(url).timeout(Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            workingUrl = urlString;
            break;
          }
        } catch (e) {
          continue;
        }
      }
      
      if (response?.statusCode == 200) {
        fetchBooks();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Book deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete book: ${response?.statusCode ?? 'No response'}')),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: book['imageUrl'] != null && book['imageUrl'].toString().isNotEmpty
                ? Image.network(
                    book['imageUrl'],
                    width: 60,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(width: 60, height: 90, color: kTeal.withOpacity(0.1), child: Icon(Icons.broken_image, color: kTeal)),
                  )
                : Container(
                    width: 60,
                    height: 90,
                    color: kTeal.withOpacity(0.1),
                  ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? 'Unknown Title',
                  style: TextStyle(
                    color: kLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'By ${book['author'] ?? 'Unknown Author'}',
                  style: TextStyle(
                    color: kLight.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kTeal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        book['category'] ?? 'Unknown',
                        style: TextStyle(
                          color: kTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${book['year'] ?? 'Unknown'}',
                      style: TextStyle(
                        color: kLight.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: kTeal, size: 22),
                tooltip: 'Edit',
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddBookPage(book: book)),
                  );
                  if (updated == true) fetchBooks();
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: kTeal, size: 22),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: kCard,
                      titleTextStyle: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 18),
                      contentTextStyle: TextStyle(color: kLight),
                      title: Text('Delete Book'),
                      content: Text('Do you want to delete this book?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: TextStyle(color: kTeal)),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text("Library", style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 28)),
        backgroundColor: kBg,
        elevation: 0,
        iconTheme: IconThemeData(color: kTeal),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => AddBookPage()));
          fetchBooks();
        },
        icon: Icon(Icons.add, color: kBg),
        label: Text("Add Book", style: TextStyle(color: kBg, fontWeight: FontWeight.bold)),
        backgroundColor: kTeal,
        shape: StadiumBorder(),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  applyFilter();
                });
              },
              style: TextStyle(color: kLight),
              decoration: InputDecoration(
                hintText: 'Search books...',
                hintStyle: TextStyle(color: kLight.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: kTeal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: kTeal),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: kTeal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: kTeal, width: 2),
                ),
                filled: true,
                fillColor: kCard,
              ),
            ),
          ),
          Expanded(
            child: filteredBooks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_books, size: 80, color: kTeal.withOpacity(0.5)),
                        SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty ? 'No books yet' : 'No books found',
                          style: TextStyle(
                            color: kLight.withOpacity(0.7),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (searchQuery.isEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            'Add your first book!',
                            style: TextStyle(
                              color: kLight.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: kCard,
                        child: buildBookTile(filteredBooks[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
