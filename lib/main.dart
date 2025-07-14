import 'package:flutter/material.dart';
import 'home_page.dart';

const kBg = Color(0xFF222831);
const kCard = Color(0xFF393E46);
const kTeal = Color(0xFF00BFCB);
const kLight = Color(0xFFEEEEEE);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        primaryColor: kTeal,
        scaffoldBackgroundColor: kBg,
        appBarTheme: AppBarTheme(
          backgroundColor: kBg,
          elevation: 0,
          iconTheme: IconThemeData(color: kTeal),
          titleTextStyle: TextStyle(
            color: kLight,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: kCard,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kTeal,
            foregroundColor: kBg,
            shape: StadiumBorder(),
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: kCard,
          labelStyle: TextStyle(color: kTeal, fontWeight: FontWeight.bold),
        ),
      ),
      home: HomePage(),
    );
  }
}

