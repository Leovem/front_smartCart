import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/products.dart';
import '../services/api_service.dart';
import '../screens/pay_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  _CatalogScreenState createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late Future<List<Product>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = ApiService().fetchProducts();
  }

  void _goTo(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catálogo de Productos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => _goTo('/cart'),
          ),
          IconButton(
            icon: const Icon(Icons.login_rounded),
            onPressed: () => _goTo('/login'),
          ),
          IconButton(
            icon: const Icon(Icons.app_registration_rounded),
            onPressed: () => _goTo('/register'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _futureProducts = ApiService().fetchProducts();
          });
        },
        child: FutureBuilder<List<Product>>(
          future: _futureProducts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Error al cargar productos'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _futureProducts = ApiService().fetchProducts();
                        });
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay productos disponibles'));
            } else {
              final products = snapshot.data!;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: products[index]);
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  Future<bool> _checkLoginStatus(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');
    if (usuarioId == null) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, inicia sesión primero'),
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

  void _addToCart(BuildContext context) async {
    final isLoggedIn = await _checkLoginStatus(context);
    if (!isLoggedIn || !context.mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id')!;
      final apiService = ApiService();
      final response = await apiService.addToCart(
        usuarioId: usuarioId,
        productoId: product.id,
        cantidad: 1,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.nombre} agregado al carrito (Cantidad: ${response['cantidad']})',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
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

  Future<Map<String, dynamic>?> _showCheckoutDialog(
    BuildContext context,
  ) async {
    final cantidadController = TextEditingController(text: '1');
    final direccionController = TextEditingController();
    int? metodoPagoId;
    String tipoEntrega = 'estándar';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirmar Compra: ${product.nombre}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      hintText: 'Ej. 1',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: direccionController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección de Envío',
                      hintText: 'Ej. Calle Principal 123, Ciudad',
                    ),
                  ),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Método de Pago',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text('Tarjeta de Crédito'),
                      ),
                      DropdownMenuItem(value: 2, child: Text('PayPal')),
                      DropdownMenuItem(
                        value: 3,
                        child: Text('Transferencia Bancaria'),
                      ),
                    ], // TODO: Cargar dinámicamente desde el backend
                    onChanged: (value) => metodoPagoId = value,
                    validator:
                        (value) =>
                            value == null
                                ? 'Seleccione un método de pago'
                                : null,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Entrega',
                    ),
                    value: tipoEntrega,
                    items: const [
                      DropdownMenuItem(
                        value: 'estándar',
                        child: Text('Estándar (3-5 días)'),
                      ),
                      DropdownMenuItem(
                        value: 'express',
                        child: Text('Express (1-2 días)'),
                      ),
                    ],
                    onChanged: (value) => tipoEntrega = value!,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total estimado: Bs${(product.precio * (int.tryParse(cantidadController.text) ?? 1)).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (direccionController.text.isEmpty ||
                      metodoPagoId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Complete todos los campos obligatorios'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  if (int.tryParse(cantidadController.text) == null ||
                      int.parse(cantidadController.text) <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'La cantidad debe ser un número mayor a 0',
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    'cantidad': int.parse(cantidadController.text),
                    'direccion_envio': direccionController.text,
                    'metodo_pago_id': metodoPagoId,
                    'tipo_entrega': tipoEntrega,
                  });
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );

    cantidadController.dispose();
    direccionController.dispose();
    return result;
  }

  void _buyNow(BuildContext context) async {
    final isLoggedIn = await _checkLoginStatus(context);
    if (!isLoggedIn || !context.mounted) return;

    // Mostrar diálogo para recolectar datos
    final checkoutData = await _showCheckoutDialog(context);
    if (checkoutData == null || !context.mounted) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id')!;
      final apiService = ApiService();

      final response = await apiService.compraDirecta(
        usuarioId: usuarioId,
        productoId: product.id,
        cantidad: checkoutData['cantidad'],
        metodoPagoId: checkoutData['metodo_pago_id'],
        direccionEnvio: checkoutData['direccion_envio'],
        tipoEntrega: checkoutData['tipo_entrega'],
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Cierra el diálogo de carga

      // Navegar a PayScreen con la respuesta
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PayScreen(compra: response)),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Cierra el diálogo de carga
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Opcional: Navegar a detalles del producto
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'product-${product.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    product.imagenUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                product.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                product.descripcion,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Text(
                '\Bs${product.precio.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _addToCart(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Añadir',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _buyNow(context),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Comprar',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
