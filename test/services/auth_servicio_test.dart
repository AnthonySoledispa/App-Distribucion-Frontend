import 'dart:convert';

import 'package:distrigo_repartidor/models/api_error.dart';
import 'package:distrigo_repartidor/services/api_cliente.dart';
import 'package:distrigo_repartidor/services/auth_servicio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/respuestas.dart';

void main() {
  test('U01: login envía cliente movil, correo sin espacios y sin Authorization', () async {
    final s = Servidor((_) async => loginOk());
    final api = ApiCliente(
      cliente: s.cliente,
      baseUrl: 'http://x/api',
      tokenProvider: () => 'no-debe-enviarse',
    );
    final sesion = await AuthServicio(api).login('  rosa@distrigo.test ', ' clave ');
    final p = s.peticiones.single;
    final cuerpo = jsonDecode(p.body) as Map<String, dynamic>;
    expect(p.method, 'POST');
    expect(p.url.path, '/api/auth/login');
    expect(cuerpo['correo'], 'rosa@distrigo.test');
    expect(cuerpo['contrasena'], ' clave ');
    expect(cuerpo['cliente'], 'movil');
    expect(p.headers.containsKey('Authorization'), isFalse);
    expect(sesion.token, 'jwt-falso');
    expect(sesion.usuario.esRepartidor, isTrue);
    expect(sesion.inactividadMinutos, 30);
  });

  test('perfil y logout usan las rutas correctas', () async {
    final s = Servidor((p) async => p.url.path.endsWith('perfil')
        ? okResp(usuarioJson())
        : okResp({'mensaje': 'ok'}));
    final api = ApiCliente(
      cliente: s.cliente,
      baseUrl: 'http://x/api',
      tokenProvider: () => 't',
    );
    final auth = AuthServicio(api);
    expect((await auth.perfil()).nombre, 'Rosa Pérez');
    await auth.logout();
    expect(s.peticiones.map((p) => '${p.method} ${p.url.path}'), [
      'GET /api/auth/perfil',
      'POST /api/auth/logout',
    ]);
  });

  test('ok:true con data nulo o mal formado -> RESPUESTA_INVALIDA', () async {
    final casos = <Object?>[
      null,
      <String, dynamic>{},
      <String, dynamic>{'token': 't', 'usuario': <String, dynamic>{'nombre': 'x'}},
    ];
    for (final data in casos) {
      final s = Servidor((_) async => jsonResp(200, {'ok': true, 'data': data}));
      final api = ApiCliente(cliente: s.cliente, baseUrl: 'http://x/api', tokenProvider: () => 't');
      final auth = AuthServicio(api);
      for (final f in [() => auth.login('a@b.co', 'x'), auth.perfil]) {
        await expectLater(
          f(),
          throwsA(isA<ApiError>().having((e) => e.codigo, 'codigo', 'RESPUESTA_INVALIDA')),
        );
      }
    }
  });
}
