class Product {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String imagenUrl;

  Product({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagenUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      precio: (json['precio'] as num).toDouble(),
      imagenUrl: json['imagen_url'],
    );
  }
}
