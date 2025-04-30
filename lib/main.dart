import 'package:ecommerce_mobile/models/checkout_response.dart';
import 'package:ecommerce_mobile/models/purchase_response.dart';
import 'package:ecommerce_mobile/screens/cart_screen.dart';
import 'package:ecommerce_mobile/screens/pay_screen_cart.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/pay_screen.dart';

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
        '/pay': (context) {
          final compra =
              ModalRoute.of(context)!.settings.arguments
                  as CompraDirectaResponse;
          return PayScreen(compra: compra);
        },
        '/payCart': (context) {
          final compra =
              ModalRoute.of(context)!.settings.arguments as CheckoutResponse;
          return PayScreenCart(compra: compra);
        },
      },
    );
  }
}
