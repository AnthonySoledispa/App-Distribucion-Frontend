// Los parámetros con nombre no pueden ser privados: se asignan en la lista de inicialización.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_error.dart';

typedef ProveedorToken = String? Function();
typedef AlSesionInvalida = void Function(String codigo);
typedef AlActividad = void Function(DateTime ahora);

/// Cliente HTTP de la API. No imprime ni registra tokens, contraseñas ni cuerpos.
class ApiCliente {
  ApiCliente({
    required http.Client cliente,
    required String baseUrl,
    ProveedorToken? tokenProvider,
    AlSesionInvalida? alSesionInvalida,
    AlActividad? alActividad,
    DateTime Function()? reloj,
    Duration tiempoMaximo = const Duration(seconds: 15),
  }) : _cliente = cliente,
       _baseUrl = baseUrl,
       _tokenProvider = tokenProvider,
       alSesionInvalida = alSesionInvalida,
       alActividad = alActividad,
       _reloj = reloj ?? DateTime.now,
       _tiempoMaximo = tiempoMaximo;

  final http.Client _cliente;
  final String _baseUrl;
  final ProveedorToken? _tokenProvider;
  final DateTime Function() _reloj;
  final Duration _tiempoMaximo;

  /// Se asignan después de crear el cliente (el controlador los conecta).
  AlSesionInvalida? alSesionInvalida;
  AlActividad? alActividad;

  /// Hace la petición y devuelve `data`. Lanza [ApiError] si algo falla.
  Future<dynamic> solicitar(
    String metodo,
    String ruta, {
    Map<String, dynamic>? cuerpo,
    bool autenticado = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$ruta');
    final cabeceras = <String, String>{'Accept': 'application/json'};
    if (cuerpo != null) {
      cabeceras['Content-Type'] = 'application/json; charset=utf-8';
    }
    final token = autenticado ? _tokenProvider?.call() : null;
    if (token != null && token.isNotEmpty) {
      cabeceras['Authorization'] = 'Bearer $token';
    }

    final peticion = http.Request(metodo, uri)..headers.addAll(cabeceras);
    if (cuerpo != null) peticion.body = jsonEncode(cuerpo);

    http.Response respuesta;
    try {
      final flujo = await _cliente.send(peticion).timeout(_tiempoMaximo);
      respuesta = await http.Response.fromStream(flujo).timeout(_tiempoMaximo);
    } on TimeoutException {
      throw const ApiError(estado: 0, codigo: 'TIEMPO_AGOTADO');
    } catch (_) {
      throw const ApiError(estado: 0, codigo: 'RED');
    }

    Map<String, dynamic> json;
    try {
      final decodificado = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (decodificado is! Map<String, dynamic> ||
          decodificado['ok'] is! bool) {
        throw const FormatException();
      }
      json = decodificado;
    } catch (_) {
      throw ApiError(estado: respuesta.statusCode, codigo: 'RESPUESTA_INVALIDA');
    }

    if (json['ok'] == true) {
      if (autenticado) alActividad?.call(_reloj());
      return json['data'];
    }

    final error = ApiError(
      estado: respuesta.statusCode,
      codigo: (json['codigo'] ?? 'ERROR').toString(),
      mensaje: (json['mensaje'] ?? '').toString(),
      errores: _leerErrores(json['errores']),
    );

    if (autenticado) {
      if (error.esSesionInvalida) {
        alSesionInvalida?.call(error.codigo);
      } else {
        alActividad?.call(_reloj());
      }
    }
    throw error;
  }

  List<Map<String, String>> _leerErrores(dynamic crudo) {
    if (crudo is! List) return const [];
    return [
      for (final e in crudo)
        if (e is Map)
          {
            'campo': (e['campo'] ?? '').toString(),
            'mensaje': (e['mensaje'] ?? '').toString(),
          },
    ];
  }
}
