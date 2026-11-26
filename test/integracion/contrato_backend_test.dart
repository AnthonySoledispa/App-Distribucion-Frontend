@Tags(['integracion'])
library;

import 'dart:io';

import 'package:distrigo_repartidor/models/api_error.dart';
import 'package:distrigo_repartidor/models/sesion.dart';
import 'package:distrigo_repartidor/services/api_cliente.dart';
import 'package:distrigo_repartidor/services/auth_servicio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Contrato con el backend real. Requiere el backend en marcha.
/// Credenciales: variables E2E_REPARTIDOR_CORREO, E2E_REPARTIDOR_CONTRASENA,
/// E2E_ADMIN_CORREO, E2E_ADMIN_CONTRASENA o, si faltan, TEST_* del .env del
/// backend. Nunca se imprimen.
Map<String, String> _leerEnv() {
  final mapa = <String, String>{};
  final archivo = File('../App_DistriGo_Backen/.env');
  if (!archivo.existsSync()) return mapa;
  for (final linea in archivo.readAsLinesSync()) {
    final l = linea.trim();
    if (l.isEmpty || l.startsWith('#') || !l.contains('=')) continue;
    final i = l.indexOf('=');
    var v = l.substring(i + 1).trim();
    if (v.length >= 2 &&
        ((v.startsWith('"') && v.endsWith('"')) ||
            (v.startsWith("'") && v.endsWith("'")))) {
      v = v.substring(1, v.length - 1);
    }
    mapa[l.substring(0, i).trim()] = v;
  }
  return mapa;
}

void main() {
  final env = _leerEnv();
  String? cred(String e2e, String test) {
    final v = Platform.environment[e2e] ?? env[test];
    return (v == null || v.isEmpty) ? null : v;
  }

  final base = Platform.environment['E2E_API_URL'] ?? 'http://localhost:3000/api';
  final repCorreo = cred('E2E_REPARTIDOR_CORREO', 'TEST_REPARTIDOR_CORREO');
  final repClave = cred('E2E_REPARTIDOR_CONTRASENA', 'TEST_REPARTIDOR_CONTRASENA');
  final admCorreo = cred('E2E_ADMIN_CORREO', 'TEST_ADMIN_CORREO');
  final admClave = cred('E2E_ADMIN_CONTRASENA', 'TEST_ADMIN_CONTRASENA');

  late bool backendVivo;
  late http.Client cliente;
  String? token;
  final invalidas = <String>[];

  late ApiCliente api;
  late AuthServicio auth;

  setUpAll(() async {
    cliente = http.Client();
    try {
      final r = await cliente
          .get(Uri.parse('$base/salud'))
          .timeout(const Duration(seconds: 5));
      backendVivo = r.statusCode == 200;
    } catch (_) {
      backendVivo = false;
    }
    api = ApiCliente(
      cliente: cliente,
      baseUrl: base,
      tokenProvider: () => token,
      alSesionInvalida: invalidas.add,
    );
    auth = AuthServicio(api);
  });

  tearDownAll(() => cliente.close());

  bool omitir(bool necesitaCreds, [bool admin = false]) {
    if (!backendVivo) {
      markTestSkipped('El backend no responde en /salud.');
      return true;
    }
    final falta = admin
        ? (admCorreo == null || admClave == null)
        : (repCorreo == null || repClave == null);
    if (necesitaCreds && falta) {
      markTestSkipped('Faltan credenciales de prueba.');
      return true;
    }
    return false;
  }

  test('I01: login del repartidor devuelve una sesión válida', () async {
    if (omitir(true)) return;
    final Sesion s = await auth.login(repCorreo!, repClave!);
    token = s.token;
    expect(s.token, isNotEmpty);
    expect(s.usuario.esRepartidor, isTrue);
    expect(s.inactividadMinutos, greaterThan(0));
  });

  test('I02: contraseña incorrecta -> 401 CREDENCIALES_INVALIDAS', () async {
    if (omitir(true)) return;
    try {
      await auth.login(repCorreo!, '${repClave!}-incorrecta');
      fail('Debió fallar');
    } on ApiError catch (e) {
      expect(e.estado, 401);
      expect(e.codigo, 'CREDENCIALES_INVALIDAS');
    }
  });

  test('I03: el administrador no entra desde la app -> 403 CLIENTE_NO_PERMITIDO', () async {
    if (omitir(true, true)) return;
    try {
      await auth.login(admCorreo!, admClave!);
      fail('Debió fallar');
    } on ApiError catch (e) {
      expect(e.estado, 403);
      expect(e.codigo, 'CLIENTE_NO_PERMITIDO');
    }
  });

  test('I04: perfil con el token del repartidor', () async {
    if (omitir(true)) return;
    if (token == null) {
      markTestSkipped('No hay token de I01.');
      return;
    }
    final u = await auth.perfil();
    expect(u.esRepartidor, isTrue);
  });

  test('I05: tras el logout, el mismo token da 401 SESION_CERRADA', () async {
    if (omitir(true)) return;
    if (token == null) {
      markTestSkipped('No hay token de I01.');
      return;
    }
    await auth.logout();
    invalidas.clear();
    try {
      await auth.perfil();
      fail('Debió fallar');
    } on ApiError catch (e) {
      expect(e.estado, 401);
      expect(e.codigo, 'SESION_CERRADA');
    }
    expect(invalidas, ['SESION_CERRADA']);
    token = null;
  });
}
