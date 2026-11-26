/// Usuario autenticado (nunca incluye la contraseña).
class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String rol;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: (json['id'] as num).toInt(),
    nombre: (json['nombre'] ?? '').toString(),
    correo: (json['correo'] ?? '').toString(),
    rol: (json['rol'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'correo': correo,
    'rol': rol,
  };

  bool get esRepartidor => rol == 'repartidor';
}
