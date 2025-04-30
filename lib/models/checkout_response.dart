class CheckoutResponse {
  final int pedidoId;
  final double total;
  final String estadoPedido;
  final int pagoId;
  final String estadoPago;
  final String metodoPago;
  final int envioId;
  final String direccionEnvio;
  final String fechaEstimadaEntrega;

  CheckoutResponse({
    required this.pedidoId,
    required this.total,
    required this.estadoPedido,
    required this.pagoId,
    required this.estadoPago,
    required this.metodoPago,
    required this.envioId,
    required this.direccionEnvio,
    required this.fechaEstimadaEntrega,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      pedidoId: json['pedido_id'],
      total: (json['total'] as num).toDouble(),
      estadoPedido: json['estado_pedido'],
      pagoId: json['pago_id'],
      estadoPago: json['estado_pago'],
      metodoPago: json['metodo_pago'],
      envioId: json['envio_id'],
      direccionEnvio: json['direccion_envio'],
      fechaEstimadaEntrega: json['fecha_estimada_entrega'],
    );
  }
}
