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
  // Removed serverIP and showIPInput

  @override
  void initState() {
    super.initState();
    // Test network connectivity first
    testNetworkConnection();
    fetchBooks();
  }

  // Test network connection
  Future<void> testNetworkConnection() async {
    try {
      print('Testing network connection...');
      var url = Uri.parse('http://192.168.193.252:3000/books');
      var response = await http.get(url).timeout(Duration(seconds: 5));
      print('Network test successful: ${response.statusCode}');
    } catch (e) {
      print('Network test failed: $e');
    }
  }

  fetchBooks() async {
    try {
      print('Fetching books from API...');
      // Use only the hardcoded list of possible URLs
      List<String> possibleUrls = [
        'http://192.168.193.252:3000/books', // Original IP
        'http://10.0.2.2:3000/books', // Android emulator localhost
        'http://localhost:3000/books',
        'http://192.168.1.100:3000/books', // Common router IP
        'http://192.168.0.100:3000/books', // Another common router IP
        'http://172.20.10.1:3000/books', // iPhone hotspot
        'http://192.168.43.1:3000/books', // Android hotspot
      ];
      
      http.Response? response;
      String? workingUrl;
      
      for (String urlString in possibleUrls) {
        try {
          print('Trying URL: $urlString');
          var url = Uri.parse(urlString);
          response = await http.get(url).timeout(
            Duration(seconds: 5),
            onTimeout: () {
              print('Request timed out for $urlString');
              throw TimeoutException('Request timed out', Duration(seconds: 5));
            },
          );
          
          if (response.statusCode == 200) {
            workingUrl = urlString;
            print('Successfully connected to: $workingUrl');
            break;
          }
        } catch (e) {
          print('Failed to connect to $urlString: $e');
          continue;
        }
      }
      
      if (response == null || workingUrl == null) {
        throw Exception('Could not connect to any server');
      }
      
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body length: ${response.body.length}');
      print('Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      
      if (response.statusCode == 200) {
        var decodedBooks = json.decode(response.body);
        print('Decoded books count: ${decodedBooks.length}');
        print('First book: ${decodedBooks.isNotEmpty ? decodedBooks.first : 'No books'}');
        
        setState(() {
          books = decodedBooks;
          applyFilter();
        });
        print('Books loaded successfully: ${books.length}');
      } else {
        print('Failed to load books: ${response.statusCode}');
        print('Error response: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load books: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error fetching books: $e');
      print('Error type: ${e.runtimeType}');
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
      // Try multiple possible IP addresses
      List<String> possibleUrls = [
        'http://192.168.193.252:3000/books/$id',
        'http://10.0.2.2:3000/books/$id', // Android emulator localhost
        'http://localhost:3000/books/$id',
      ];
      
      http.Response? response;
      String? workingUrl;
      
      for (String urlString in possibleUrls) {
        try {
          print('Trying to delete from: $urlString');
          var url = Uri.parse(urlString);
          response = await http.delete(url).timeout(Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            workingUrl = urlString;
            print('Successfully deleted from: $workingUrl');
            break;
          }
        } catch (e) {
          print('Failed to delete from $urlString: $e');
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
      print('Error deleting book: $e');
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
                  book['title'] ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kLight),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text(
                  book['author'] ?? '',
                  style: TextStyle(fontSize: 16, color: kLight, fontWeight: FontWeight.w600, letterSpacing: 0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    if (book['year'] != null && book['year'].toString().isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(
                            book['year'].toString(),
                            style: TextStyle(color: kBg, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          backgroundColor: kTeal,
                          shape: StadiumBorder(),
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (book['category'] != null && book['category'].toString().isNotEmpty)
                      Chip(
                        label: Text(
                          book['category'],
                          style: TextStyle(color: kTeal, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        backgroundColor: kCard,
                        shape: StadiumBorder(side: BorderSide(color: kTeal, width: 1.5)),
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    if (book['source'] != null)
                      Chip(
                        label: Text(book['source'], style: TextStyle(fontSize: 12, color: kBg, fontWeight: FontWeight.bold)),
                        backgroundColor: kTeal,
                        shape: StadiumBorder(),
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Action buttons column
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
      body: Container(
        color: kBg,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(16),
                  color: kCard,
                  child: TextField(
                    style: TextStyle(color: kLight, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: "Search by title, author, or category",
                      hintStyle: TextStyle(color: kLight.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.search, color: kTeal),
                      filled: true,
                      fillColor: kCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: (value) {
                      searchQuery = value.toLowerCase();
                      applyFilter();
                    },
                  ),
                ),
              ),
              Expanded(
                child: filteredBooks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book, size: 60, color: kTeal.withOpacity(0.5)),
                            SizedBox(height: 16),
                            Text("No books found", style: TextStyle(fontSize: 20, color: kLight, fontWeight: FontWeight.bold)),
                            if (books.isEmpty && searchQuery.isEmpty) ...[
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: fetchBooks,
                                child: Text("Retry Connection", style: TextStyle(color: kBg, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kTeal,
                                  shape: StadiumBorder(),
                                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(bottom: 80),
                        itemCount: filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = filteredBooks[index];
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Card(
                              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 4,
                              color: kCard,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              child: buildBookTile(book),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
