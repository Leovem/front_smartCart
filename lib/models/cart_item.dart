// lib/models/cart_item.dart
class CartItem {
  final int productoId;
  final String nombre;
  final String imagenUrl;
  final double precio;
  final int cantidad;

  CartItem({
    required this.productoId,
    required this.nombre,
    required this.imagenUrl,
    required this.precio,
    required this.cantidad,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productoId: json['producto_id'],
      nombre: json['nombre'],
      imagenUrl: json['imagen_url'],
      precio: json['precio'].toDouble(),
      cantidad: json['cantidad'],
    );
  }
}
