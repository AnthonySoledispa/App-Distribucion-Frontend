import 'dart:async';
import 'dart:convert';

import 'package:distrigo_repartidor/models/api_error.dart';
import 'package:distrigo_repartidor/services/api_cliente.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../fakes/respuestas.dart';

ApiCliente crear(
  http.Client c, {
  String? token = 'tok',
  List<String>? invalidas,
  List<DateTime>? actividades,
  Duration tiempo = const Duration(seconds: 15),
}) => ApiCliente(
  cliente: c,
  baseUrl: 'http://x/api',
  tokenProvider: () => token,
  alSesionInvalida: invalidas?.add,
  alActividad: actividades?.add,
  reloj: () => DateTime.utc(2026, 1, 1),
  tiempoMaximo: tiempo,
);

Future<ApiError> falla(Future<dynamic> f) async {
  try {
    await f;
  } on ApiError catch (e) {
    return e;
  }
  fail('Se esperaba un ApiError');
}

void main() {
  test('U02: petición autenticada lleva Bearer', () async {
    final s = Servidor((_) async => okResp({}));
    await crear(s.cliente).solicitar('GET', '/auth/perfil');
    expect(s.peticiones.single.headers['Authorization'], 'Bearer tok');
    expect(s.peticiones.single.headers['Accept'], 'application/json');
  });

  test('no autenticada no lleva Authorization y el cuerpo va en JSON', () async {
    final s = Servidor((_) async => okResp({}));
    await crear(s.cliente).solicitar(
      'POST',
      '/auth/login',
      cuerpo: {'a': 1},
      autenticado: false,
    );
    final p = s.peticiones.single;
    expect(p.headers.containsKey('Authorization'), isFalse);
    expect(p.headers['Content-Type'], contains('application/json'));
    expect(jsonDecode(p.body), {'a': 1});
  });

  test('U03: 401 SESION_EXPIRADA llama al manejador', () async {
    final inv = <String>[];
    final s = Servidor((_) async => errResp(401, 'SESION_EXPIRADA'));
    final e = await falla(crear(s.cliente, invalidas: inv).solicitar('GET', '/auth/perfil'));
    expect(e.codigo, 'SESION_EXPIRADA');
    expect(inv, ['SESION_EXPIRADA']);
  });

  test('U04: 401 del login no llama al manejador', () async {
    final inv = <String>[];
    final act = <DateTime>[];
    final s = Servidor((_) async => errResp(401, 'CREDENCIALES_INVALIDAS'));
    final e = await falla(
      crear(s.cliente, invalidas: inv, actividades: act).solicitar(
        'POST',
        '/auth/login',
        cuerpo: {},
        autenticado: false,
      ),
    );
    expect(e.estado, 401);
    expect(e.codigo, 'CREDENCIALES_INVALIDAS');
    expect(inv, isEmpty);
    expect(act, isEmpty);
  });

  test('U05: error de red y tiempo agotado', () async {
    final red = MockClient((_) async => throw http.ClientException('sin red'));
    expect((await falla(crear(red).solicitar('GET', '/x'))).codigo, 'RED');

    final lento = MockClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return okResp({});
    });
    final e = await falla(
      crear(lento, tiempo: const Duration(milliseconds: 20)).solicitar('GET', '/x'),
    );
    expect(e.codigo, 'TIEMPO_AGOTADO');
    expect(e.estado, 0);
  });

  test('U06: HTML o JSON sin ok es RESPUESTA_INVALIDA', () async {
    final html = MockClient((_) async => http.Response('<html></html>', 502));
    expect(
      (await falla(crear(html).solicitar('GET', '/x'))).codigo,
      'RESPUESTA_INVALIDA',
    );
    final sinOk = MockClient((_) async => jsonResp(200, {'data': 1}));
    expect(
      (await falla(crear(sinOk).solicitar('GET', '/x'))).codigo,
      'RESPUESTA_INVALIDA',
    );
  });

  test('U17: respuestas no 401 renuevan la actividad; 403 no cierra sesión', () async {
    final inv = <String>[];
    final act = <DateTime>[];
    final ok = Servidor((_) async => okResp({}));
    await crear(ok.cliente, invalidas: inv, actividades: act).solicitar('GET', '/x');
    expect(act, hasLength(1));

    final prohibido = Servidor((_) async => errResp(403, 'ACCESO_DENEGADO'));
    final e = await falla(
      crear(prohibido.cliente, invalidas: inv, actividades: act).solicitar('GET', '/x'),
    );
    expect(e.codigo, 'ACCESO_DENEGADO');
    expect(act, hasLength(2));
    expect(inv, isEmpty);
  });

  test('decodifica tildes en UTF-8 y errores de validación', () async {
    final c = MockClient(
      (_) async => http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'ok': false,
            'codigo': 'VALIDACION',
            'mensaje': 'Año',
            'errores': [
              {'campo': 'correo', 'mensaje': 'Inválido'},
            ],
          }),
        ),
        400,
      ),
    );
    final e = await falla(crear(c).solicitar('POST', '/x', cuerpo: {}));
    expect(e.mensaje, 'Año');
    expect(e.errores.single['campo'], 'correo');
  });

  test('una excepción no ApiError dentro de Timeout no escapa', () async {
    final c = MockClient((_) => Completer<http.Response>().future);
    final e = await falla(
      crear(c, tiempo: const Duration(milliseconds: 10)).solicitar('GET', '/x'),
    );
    expect(e.codigo, 'TIEMPO_AGOTADO');
  });
}
