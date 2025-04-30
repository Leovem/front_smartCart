// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/products.dart';
import '../models/cart_item.dart';
import '../models/purchase_response.dart';
import '../models/checkout_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'https://web-production-31b3.up.railway.app';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'mensaje': 'Error al iniciar sesión',
        'status': response.statusCode,
      };
    }
  }

  Future<bool> registrarUsuario(Usuario usuario) async {
    final url = Uri.parse('$baseUrl/api/auth/register/');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(usuario.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print('Error en registro: ${response.body}');
      return false;
    }
  }

  Future<List<Product>> fetchProducts() async {
    try {
      final url = Uri.parse('$baseUrl/api/products/catalogo/');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      // Imprimir el código de estado y la respuesta completa para debug
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map((productJson) => Product.fromJson(productJson))
            .toList();
      } else {
        throw Exception(
          'Error al cargar productos: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error en la solicitud: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addToCart({
    required int usuarioId,
    required int productoId,
    int cantidad = 1,
  }) async {
    final url = Uri.parse('$baseUrl/api/cart/agregar-producto/');
    final Map<String, dynamic> requestBody = {
      'usuario_id': usuarioId,
      'producto_id': productoId,
      'cantidad': cantidad,
    };

    print(
      '📦 Datos enviados al backend: ${const JsonEncoder.withIndent('  ').convert(requestBody)}',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer <token>', si es necesario
      },
      body: jsonEncode(requestBody),
    );

    print('📥 Código de estado: ${response.statusCode}');
    print('📥 Respuesta del backend: ${response.body}');

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      throw Exception('⚠️ Faltan datos necesarios');
    } else if (response.statusCode == 404) {
      throw Exception('❌ Producto no encontrado');
    } else {
      throw Exception('🚫 Error al agregar producto al carrito');
    }
  }

  Future<List<CartItem>> fetchCart(int usuarioId) async {
    final url = Uri.parse('$baseUrl/api/cart/$usuarioId/');

    // Imprimir la URL antes de hacer la solicitud
    print('URL del carrito: $url');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    print('Código de respuesta: ${response.statusCode}');
    print('Cuerpo de la respuesta: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      List<dynamic> productos = data['productos'];

      return productos.map((json) => CartItem.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar el carrito');
    }
  }

  Future<void> removeCartItem({
    required int usuarioId,
    required int productoId,
  }) async {
    final url = Uri.parse('$baseUrl/api/cart/eliminar-del-carrito/');
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'usuario_id': usuarioId, 'producto_id': productoId}),
    );

    if (response.statusCode != 200) {
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Error al eliminar el producto');
    } else {
      print('Producto eliminado correctamente');
    }
  }

  Future<CheckoutResponse> checkout({
    required int usuarioId,
    required int metodoPagoId,
    required String direccionEnvio,
    required String tipoEntrega,
  }) async {
    final url = Uri.parse('$baseUrl/api/orders/compra_carrito/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'usuario_id': usuarioId,
        'metodo_pago_id': metodoPagoId,
        'direccion_envio': direccionEnvio,
        'tipo_entrega': tipoEntrega,
      }),
    );

    print('📥 Código de estado (checkout): ${response.statusCode}');
    print('📥 Respuesta del backend (checkout): ${response.body}');

    if (response.statusCode == 201) {
      return CheckoutResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 400) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Faltan datos');
    } else if (response.statusCode == 404) {
      throw Exception(
        jsonDecode(response.body)['detail'] ?? 'Recurso no encontrado',
      );
    } else {
      throw Exception(
        'Error al procesar la compra: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<String> initiatePaypalPayment(int pagoId) async {
    final url = Uri.parse('$baseUrl/api/payment/generar_pago_paypal/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pago_id': pagoId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['approval_url'];
    } else {
      throw Exception(
        jsonDecode(response.body)['detail'] ??
            'Error al iniciar el pago con PayPal',
      );
    }
  }

  Future<void> updateCartItemQuantity({
    required int usuarioId,
    required int productoId,
    required int cantidad,
  }) async {
    final url = Uri.parse('$baseUrl/api/cart/actualizar-cantidad/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usuario_id': usuarioId,
        'producto_id': productoId,
        'cantidad': cantidad,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar la cantidad');
    }
  }

  Future<CompraDirectaResponse> compraDirecta({
    required int usuarioId,
    required int productoId,
    required int cantidad,
    required int metodoPagoId,
    required String direccionEnvio,
    String tipoEntrega = 'estándar',
  }) async {
    final url = Uri.parse('$baseUrl/api/orders/compra-directa/');

    final Map<String, dynamic> requestBody = {
      'usuario_id': usuarioId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'metodo_pago_id': metodoPagoId,
      'direccion_envio': direccionEnvio,
      'tipo_entrega': tipoEntrega,
    };

    print(
      '🛒 Datos enviados al backend: ${const JsonEncoder.withIndent('  ').convert(requestBody)}',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer <token>', // Descomenta si usas autenticación
      },
      body: jsonEncode(requestBody),
    );

    print('📥 Código de estado: ${response.statusCode}');
    print('📥 Respuesta del backend: ${response.body}');

    if (response.statusCode == 201) {
      return CompraDirectaResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 400) {
      throw Exception('⚠️ Faltan datos necesarios');
    } else if (response.statusCode == 404) {
      throw Exception('❌ Producto, usuario o método de pago no encontrado');
    } else {
      throw Exception('🚫 Error al realizar la compra');
    }
  }
}
