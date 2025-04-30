import 'package:ecommerce_mobile/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/catalog_screen.dart'; // Asegúrate de importar el catalog_screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-commerce App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/catalog', // Cambiamos la ruta inicial a '/catalog'
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/catalog': (context) => CatalogScreen(),
        '/cart': (context) => const CartScreen(),
      },
    );
  }
}
