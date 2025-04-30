class CompraDirectaResponse {
  final int pedidoId;
  final String producto;
  final int cantidad;
  final double total;
  final int pagoId;
  final String metodoPago;
  final String estadoPago;
  final int envioId;
  final String direccionEnvio;
  final String fechaEstimadaEntrega;

  CompraDirectaResponse({
    required this.pedidoId,
    required this.producto,
    required this.cantidad,
    required this.total,
    required this.pagoId,
    required this.metodoPago,
    required this.estadoPago,
    required this.envioId,
    required this.direccionEnvio,
    required this.fechaEstimadaEntrega,
  });

  factory CompraDirectaResponse.fromJson(Map<String, dynamic> json) {
    return CompraDirectaResponse(
      pedidoId: json['pedido_id'],
      producto: json['producto'],
      cantidad: json['cantidad'],
      total: json['total'],
      pagoId: json['pago_id'],
      metodoPago: json['metodo_pago'],
      estadoPago: json['estado_pago'],
      envioId: json['envio_id'],
      direccionEnvio: json['direccion_envio'],
      fechaEstimadaEntrega: json['fecha_estimada_entrega'],
    );
  }
}
