class Usuario {
  final String nombreCompleto;
  final String email;
  final String password;
  final String telefono;
  final String direccion;
  final int rolId;

  Usuario({
    required this.nombreCompleto,
    required this.email,
    required this.password,
    required this.telefono,
    required this.direccion,
    required this.rolId,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre_completo': nombreCompleto,
      'email': email,
      'password': password,
      'telefono': telefono,
      'direccion': direccion,
      'rol_id': rolId,
    };
  }
}
