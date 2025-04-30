import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cart_item.dart';
//import '../models/checkout_response.dart';
import '../services/api_service.dart';
import './pay_screen_cart.dart'; // Cambiado de pay_screen a pay_screen_cart

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<CartItem>> _futureCartItems;
  int? _usuarioId;
  final _direccionController = TextEditingController();
  String _selectedDeliveryType = 'estándar';
  int? _selectedMetodoPagoId;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Lista estática de métodos de pago
  final List<Map<String, dynamic>> _metodosPago = [
    {'id': 1, 'tipo': 'Tarjeta de Débito'},
    {'id': 2, 'tipo': 'PayPal'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usuarioId = prefs.getInt('usuario_id');
      if (_usuarioId != null) {
        _futureCartItems = ApiService().fetchCart(_usuarioId!);
      }
    });
  }

  Future<bool> _checkLoginStatus() async {
    if (_usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, inicia sesión para ver tu carrito'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pushNamed(context, '/login');
      return false;
    }
    return true;
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity < 1) return;
    try {
      await ApiService().updateCartItemQuantity(
        usuarioId: _usuarioId!,
        productoId: item.productoId,
        cantidad: newQuantity,
      );
      setState(() {
        _futureCartItems = ApiService().fetchCart(_usuarioId!);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cantidad actualizada para ${item.nombre}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      await ApiService().removeCartItem(
        usuarioId: _usuarioId!,
        productoId: item.productoId,
      );
      setState(() {
        _futureCartItems = ApiService().fetchCart(_usuarioId!);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.nombre} eliminado del carrito'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _checkout() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMetodoPagoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un método de pago'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crear el pedido
      final checkoutResponse = await ApiService().checkout(
        usuarioId: _usuarioId!,
        metodoPagoId: _selectedMetodoPagoId!,
        direccionEnvio: _direccionController.text,
        tipoEntrega: _selectedDeliveryType,
      );

      if (!mounted) return;

      // Navegar a PayScreenCart
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PayScreenCart(compra: checkoutResponse),
        ),
      );

      // Iniciar pago con PayPal
      final approvalUrl = await ApiService().initiatePaypalPayment(
        checkoutResponse.pagoId,
      );
      if (!mounted) return;
      if (await canLaunch(approvalUrl)) {
        await launch(approvalUrl, forceWebView: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redirigiendo a PayPal...'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw 'No se pudo lanzar la URL de PayPal';
      }

      // Refrescar el carrito
      setState(() {
        _futureCartItems = ApiService().fetchCart(_usuarioId!);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _direccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Carrito',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('usuario_id');
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body:
          _usuarioId == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Por favor, inicia sesión para ver tu carrito'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: const Text('Iniciar Sesión'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _futureCartItems = ApiService().fetchCart(_usuarioId!);
                  });
                },
                child: FutureBuilder<List<CartItem>>(
                  future: _futureCartItems,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Error al cargar el carrito'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _futureCartItems = ApiService().fetchCart(
                                    _usuarioId!,
                                  );
                                });
                              },
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Tu carrito está vacío'));
                    } else {
                      final cartItems = snapshot.data!;
                      final total = cartItems.fold<double>(
                        0,
                        (sum, item) => sum + item.precio * item.cantidad,
                      );
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: cartItems.length,
                              itemBuilder: (context, index) {
                                final item = cartItems[index];
                                return CartItemCard(
                                  item: item,
                                  onQuantityChanged:
                                      (newQuantity) =>
                                          _updateQuantity(item, newQuantity),
                                  onRemove: () => _removeItem(item),
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        '\$${total.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _direccionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Dirección de envío',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingresa una dirección';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<int>(
                                    decoration: const InputDecoration(
                                      labelText: 'Método de Pago',
                                      border: OutlineInputBorder(),
                                    ),
                                    items:
                                        _metodosPago.map((metodo) {
                                          return DropdownMenuItem<int>(
                                            value: metodo['id'],
                                            child: Text(metodo['tipo']),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedMetodoPagoId = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Por favor selecciona un método de pago';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedDeliveryType,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedDeliveryType = value!;
                                      });
                                    },
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'estándar',
                                        child: Text('Entrega estándar'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'express',
                                        child: Text('Entrega express'),
                                      ),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Tipo de entrega',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _isLoading
                                      ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                      : ElevatedButton(
                                        onPressed: _checkout,
                                        child: const Text('Pagar'),
                                      ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    Key? key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  }) : super(key: key);

  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Image.network(item.imagenUrl, width: 50, height: 50),
        title: Text(item.nombre),
        subtitle: Text('Precio: \$${item.precio}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => onQuantityChanged(item.cantidad - 1),
            ),
            Text('${item.cantidad}'),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => onQuantityChanged(item.cantidad + 1),
            ),
            IconButton(icon: const Icon(Icons.delete), onPressed: onRemove),
          ],
        ),
      ),
    );
  }
}
