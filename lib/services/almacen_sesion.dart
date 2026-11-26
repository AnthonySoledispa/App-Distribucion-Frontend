import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/sesion.dart';
import '../models/usuario.dart';

/// Guarda la sesión del repartidor. Nunca guarda la contraseña.
abstract class AlmacenSesion {
  Future<Sesion?> leer();
  Future<void> guardar(Sesion sesion);
  Future<void> actualizarActividad(DateTime ultimaActividad);
  Future<void> borrar();
}

/// Implementación con flutter_secure_storage (RB-11).
class AlmacenSesionSeguro implements AlmacenSesion {
  AlmacenSesionSeguro([FlutterSecureStorage? almacen])
    : _almacen = almacen ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacen;

  static const claveToken = 'distrigo.token';
  static const claveUsuario = 'distrigo.usuario';
  static const claveInactividad = 'distrigo.inactividad_min';
  static const claveActividad = 'distrigo.ultima_actividad';

  @override
  Future<Sesion?> leer() async {
    try {
      final token = await _almacen.read(key: claveToken);
      final usuario = await _almacen.read(key: claveUsuario);
      final inactividad = await _almacen.read(key: claveInactividad);
      final actividad = await _almacen.read(key: claveActividad);
      if (token == null ||
          usuario == null ||
          inactividad == null ||
          actividad == null) {
        return null;
      }
      return Sesion(
        token: token,
        usuario: Usuario.fromJson(jsonDecode(usuario) as Map<String, dynamic>),
        inactividadMinutos: int.parse(inactividad),
        ultimaActividad: DateTime.parse(actividad).toUtc(),
      );
    } catch (_) {
      // Datos corruptos o ilegibles: se descarta la sesión local.
      await borrar();
      return null;
    }
  }

  @override
  Future<void> guardar(Sesion sesion) async {
    await _almacen.write(key: claveToken, value: sesion.token);
    await _almacen.write(
      key: claveUsuario,
      value: jsonEncode(sesion.usuario.toJson()),
    );
    await _almacen.write(
      key: claveInactividad,
      value: sesion.inactividadMinutos.toString(),
    );
    await actualizarActividad(sesion.ultimaActividad);
  }

  @override
  Future<void> actualizarActividad(DateTime ultimaActividad) => _almacen.write(
    key: claveActividad,
    value: ultimaActividad.toUtc().toIso8601String(),
  );

  @override
  Future<void> borrar() async {
    for (final clave in [
      claveToken,
      claveUsuario,
      claveInactividad,
      claveActividad,
    ]) {
      try {
        await _almacen.delete(key: clave);
      } catch (_) {}
    }
  }
}
