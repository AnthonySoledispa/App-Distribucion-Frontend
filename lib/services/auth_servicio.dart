import '../models/api_error.dart';
import '../models/sesion.dart';
import '../models/usuario.dart';
import 'api_cliente.dart';

/// Llamadas de autenticación al backend.
class AuthServicio {
  AuthServicio(this._api, {DateTime Function()? reloj})
    : _reloj = reloj ?? DateTime.now;

  final ApiCliente _api;
  final DateTime Function() _reloj;

  Future<Sesion> login(String correo, String contrasena) async {
    final crudo = await _api.solicitar(
      'POST',
      '/auth/login',
      cuerpo: {
        'correo': correo.trim(),
        'contrasena': contrasena,
        'cliente': 'movil',
      },
      autenticado: false,
    );
    return _leer(() {
      final data = crudo as Map<String, dynamic>;
      final token = data['token'];
      if (token is! String || token.isEmpty) throw const FormatException();
      return Sesion(
        token: token,
        usuario: Usuario.fromJson(data['usuario'] as Map<String, dynamic>),
        inactividadMinutos:
            (data['inactividad_minutos'] as num?)?.toInt() ?? 30,
        ultimaActividad: _reloj().toUtc(),
      );
    });
  }

  /// Convierte datos mal formados (ok:true con data nulo o de otro tipo) en
  /// un ApiError controlado.
  T _leer<T>(T Function() convertir) {
    try {
      return convertir();
    } catch (_) {
      throw const ApiError(estado: 200, codigo: 'RESPUESTA_INVALIDA');
    }
  }

  Future<Usuario> perfil() async {
    final crudo = await _api.solicitar('GET', '/auth/perfil');
    return _leer(() => Usuario.fromJson(crudo as Map<String, dynamic>));
  }

  Future<void> logout() async {
    await _api.solicitar('POST', '/auth/logout');
  }
}
