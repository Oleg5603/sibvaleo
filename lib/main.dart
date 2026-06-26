import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/product.dart';
import 'data/recommendation_engine.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final products = await _loadProducts();
  runApp(SibvaleoApp(products: products));
}

Future<List<Product>> _loadProducts() async {
  final raw = await rootBundle.loadString('assets/data/products.json');
  final list = jsonDecode(raw) as List;
  return list.map((j) => Product.fromJson(j)).toList();
}

class SibvaleoApp extends StatelessWidget {
  final List<Product> products;
  const SibvaleoApp({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sibvaleo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // тёмно-зелёный
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        cardTheme: const CardThemeData(elevation: 2),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: HomeScreen(
        products: products,
        engine: RecommendationEngine(products),
      ),
    );
  }
}
