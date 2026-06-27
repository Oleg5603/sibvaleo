import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/product.dart';
import 'data/recommendation_engine.dart';
import 'screens/home_screen.dart';
import 'screens/trial_expired_screen.dart';
import 'utils/trial.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final products = await _loadProducts();
  final trialStatus = await Trial.check();
  runApp(SibvaleoApp(products: products, trial: trialStatus));
}

Future<List<Product>> _loadProducts() async {
  final raw = await rootBundle.loadString('assets/data/products.json');
  final list = jsonDecode(raw) as List;
  return list.map((j) => Product.fromJson(j)).toList();
}

Widget _buildHome(List<Product> products, TrialStatus trial) {
  final engine = RecommendationEngine(products);
  if (trial.isExpired) {
    return TrialExpiredScreen(trial: trial, products: products, engine: engine);
  }
  return HomeScreen(products: products, engine: engine, trial: trial);
}

class SibvaleoApp extends StatelessWidget {
  final List<Product> products;
  final TrialStatus trial;
  const SibvaleoApp({super.key, required this.products, required this.trial});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sibvaleo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        cardTheme: const CardThemeData(elevation: 2),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: _buildHome(products, trial),
    );
  }
}
