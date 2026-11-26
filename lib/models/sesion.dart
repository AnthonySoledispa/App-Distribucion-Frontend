import 'usuario.dart';

/// Sesión del repartidor. El token es el JWT que entrega el backend.
class Sesion {
  final String token;
  final Usuario usuario;
  final int inactividadMinutos;
  final DateTime ultimaActividad;

  const Sesion({
    required this.token,
    required this.usuario,
    required this.inactividadMinutos,
    required this.ultimaActividad,
  });

  Sesion copiarCon({Usuario? usuario, DateTime? ultimaActividad}) => Sesion(
    token: token,
    usuario: usuario ?? this.usuario,
    inactividadMinutos: inactividadMinutos,
    ultimaActividad: ultimaActividad ?? this.ultimaActividad,
  );

  Duration get limiteInactividad => Duration(minutes: inactividadMinutos);
}
