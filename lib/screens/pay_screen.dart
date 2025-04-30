import 'package:flutter/material.dart';
import '../models/purchase_response.dart';

class PayScreen extends StatelessWidget {
  final CompraDirectaResponse compra;

  const PayScreen({Key? key, required this.compra}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Pago'),
        backgroundColor: Colors.green[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  '¡Compra realizada con éxito!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: Text('Producto: ${compra.producto}'),
                  subtitle: Text('Cantidad: ${compra.cantidad}'),
                ),

                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: Text('Total: Bs ${compra.total.toStringAsFixed(2)}'),
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.payment),
                  title: Text('Método de Pago: ${compra.metodoPago}'),
                  subtitle: Text('Estado: ${compra.estadoPago}'),
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text('Dirección de Envío'),
                  subtitle: Text(compra.direccionEnvio),
                ),

                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Entrega Estimada'),
                  subtitle: Text(compra.fechaEstimadaEntrega),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.popUntil(context, ModalRoute.withName('/'));
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Finalizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
