import 'package:distrigo_repartidor/models/api_error.dart';
import 'package:distrigo_repartidor/services/api_cliente.dart';
import 'package:distrigo_repartidor/services/auth_servicio.dart';
import 'package:distrigo_repartidor/services/sesion_controlador.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../fakes/almacen_memoria.dart';
import '../fakes/entorno.dart';
import '../fakes/respuestas.dart';

Future<void> vaciar() => pumpEventQueue();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('iniciarSesion', () {
    test('U11: login correcto guarda sesión y no guarda la contraseña', () async {
      final e = Entorno(responder: (_) async => loginOk(inactividad: 30));
      await e.controlador.iniciarSesion('rosa@distrigo.test', 'SecretaXYZ');
      final s = e.almacen.sesion!;
      expect(e.controlador.estado, EstadoSesion.autenticado);
      expect(s.token, 'jwt-falso');
      expect(s.usuario.nombre, 'Rosa Pérez');
      expect(s.inactividadMinutos, 30);
      expect(s.ultimaActividad, e.ahora);
      final volcado = '${s.token}${s.usuario.toJson()}${s.inactividadMinutos}';
      expect(volcado.contains('SecretaXYZ'), isFalse);
      e.controlador.dispose();
    });

    test('U10: rol administrador no se guarda, se llama a logout y sale CLIENTE_NO_PERMITIDO', () async {
      final e = Entorno(
        responder: (p) async =>
            p.url.path.endsWith('login') ? loginOk(rol: 'administrador') : okResp({'mensaje': 'ok'}),
      );
      await expectLater(
        e.controlador.iniciarSesion('a@b.co', 'x'),
        throwsA(isA<ApiError>().having((x) => x.codigo, 'codigo', 'CLIENTE_NO_PERMITIDO')),
      );
      await vaciar();
      expect(e.almacen.sesion, isNull);
      expect(e.controlador.estado, isNot(EstadoSesion.autenticado));
      final logout = e.servidor.a('/auth/logout').single;
      expect(logout.headers['Authorization'], 'Bearer jwt-falso');
      e.controlador.dispose();
    });

    test('credenciales inválidas propagan el error y no guardan nada', () async {
      final e = Entorno(responder: (_) async => errResp(401, 'CREDENCIALES_INVALIDAS'));
      await expectLater(
        e.controlador.iniciarSesion('a@b.co', 'x'),
        throwsA(isA<ApiError>()),
      );
      expect(e.almacen.sesion, isNull);
      e.controlador.dispose();
    });
  });

  group('iniciar', () {
    test('U12: sin sesión guardada -> anonimo', () async {
      final e = Entorno();
      await e.controlador.iniciar();
      expect(e.controlador.estado, EstadoSesion.anonimo);
      expect(e.servidor.peticiones, isEmpty);
      e.controlador.dispose();
    });

    test('U12: con sesión y perfil 200 -> autenticado', () async {
      final e = Entorno(almacen: AlmacenMemoria(sesionGuardada(ultimaActividad: DateTime.utc(2026, 11, 25, 11, 55))));
      await e.controlador.iniciar();
      expect(e.controlador.estado, EstadoSesion.autenticado);
      expect(e.controlador.usuario!.nombre, 'Rosa Pérez');
      e.controlador.dispose();
    });

    test('perfil con otro rol -> se borra y anonimo', () async {
      final e = Entorno(
        responder: (_) async => okResp(usuarioJson(rol: 'administrador')),
        almacen: AlmacenMemoria(sesionGuardada(ultimaActividad: DateTime.utc(2026, 11, 25, 11, 59))),
      );
      await e.controlador.iniciar();
      expect(e.controlador.estado, EstadoSesion.anonimo);
      expect(e.almacen.sesion, isNull);
      e.controlador.dispose();
    });

    test('U12: perfil 401 -> anonimo con flash y almacén vacío', () async {
      final e = Entorno(
        responder: (_) async => errResp(401, 'SESION_CERRADA'),
        almacen: AlmacenMemoria(sesionGuardada(ultimaActividad: DateTime.utc(2026, 11, 25, 11, 59))),
      );
      await e.controlador.iniciar();
      expect(e.controlador.estado, EstadoSesion.anonimo);
      expect(e.controlador.flash, 'Su sesión fue cerrada. Inicie sesión nuevamente.');
      expect(e.almacen.sesion, isNull);
      e.controlador.dispose();
    });

    test('U12: RED -> errorConexion y el token se conserva', () async {
      final e = Entorno(
        responder: (_) async => throw http.ClientException('sin red'),
        almacen: AlmacenMemoria(sesionGuardada(ultimaActividad: DateTime.utc(2026, 11, 25, 11, 59))),
      );
      await e.controlador.iniciar();
      expect(e.controlador.estado, EstadoSesion.errorConexion);
      expect(e.almacen.sesion?.token, 'jwt-guardado');
      e.controlador.dispose();
    });

    test('503 -> errorConexion', () async {
      final e = Entorno(
        responder: (_) async => errResp(503, 'BD_NO_DISPONIBLE'),
        almacen: AlmacenMemoria(sesionGuardada(ultimaActividad: DateTime.utc(2026, 11, 25, 11, 59))),
      );
      await e.controlador.iniciar();
      expect(e.controlador.estado, EstadoSesion.errorConexion);
      expect(e.almacen.sesion, isNotNull);
      e.controlador.dispose();
    });

    test('U13: inactividad local superada -> no llama a la API y deja flash', () async {
      final e = Entorno(
        almacen: AlmacenMemoria(sesionGuardada(ultimaActividad: DateTime.utc(2026, 11, 25, 11, 0))),
      );
      await e.controlador.iniciar();
      expect(e.servidor.peticiones, isEmpty);
      expect(e.almacen.sesion, isNull);
      expect(e.controlador.estado, EstadoSesion.anonimo);
      expect(e.controlador.flash, 'Su sesión expiró por inactividad. Inicie sesión nuevamente.');
      e.controlador.dispose();
    });
  });

  group('inactividad', () {
    Future<Entorno> autenticado() async {
      final e = Entorno(
        responder: (p) async => p.url.path.endsWith('login')
            ? loginOk(inactividad: 30)
            : okResp(usuarioJson()),
      );
      await e.controlador.iniciarSesion('a@b.co', 'x');
      return e;
    }

    test('U14: a 59 s del límite aparece el aviso; pasado el límite se cierra', () async {
      final e = await autenticado();
      e.ahora = e.ahora.add(const Duration(minutes: 30) - const Duration(seconds: 59));
      e.controlador.evaluarInactividad();
      expect(e.controlador.mostrarAviso, isTrue);
      expect(e.controlador.estado, EstadoSesion.autenticado);

      e.ahora = e.ahora.add(const Duration(seconds: 60));
      e.controlador.evaluarInactividad();
      await vaciar();
      expect(e.controlador.estado, EstadoSesion.anonimo);
      expect(e.controlador.mostrarAviso, isFalse);
      expect(e.controlador.flash, 'Su sesión expiró por inactividad. Inicie sesión nuevamente.');
      expect(e.almacen.sesion, isNull);
      e.controlador.dispose();
    });

    test('antes de los 60 s no hay aviso', () async {
      final e = await autenticado();
      e.ahora = e.ahora.add(const Duration(minutes: 28));
      e.controlador.evaluarInactividad();
      expect(e.controlador.mostrarAviso, isFalse);
      e.controlador.dispose();
    });

    test('U15: seguirConectado renueva la actividad y oculta el aviso', () async {
      final e = await autenticado();
      e.ahora = e.ahora.add(const Duration(minutes: 29, seconds: 30));
      e.controlador.evaluarInactividad();
      expect(e.controlador.mostrarAviso, isTrue);

      expect(await e.controlador.seguirConectado(), isTrue);
      await vaciar();
      expect(e.controlador.mostrarAviso, isFalse);
      expect(e.almacen.sesion!.ultimaActividad, e.ahora);
      expect(e.controlador.segundosRestantes, 30 * 60);
      e.controlador.dispose();
    });

    test('seguirConectado con 401 cierra la sesión con flash', () async {
      var n = 0;
      final e = Entorno(
        responder: (_) async => n++ == 0 ? loginOk() : errResp(401, 'SESION_EXPIRADA'),
      );
      await e.controlador.iniciarSesion('a@b.co', 'x');
      expect(await e.controlador.seguirConectado(), isFalse);
      await vaciar();
      expect(e.controlador.estado, EstadoSesion.anonimo);
      expect(e.controlador.flash, 'Su sesión expiró. Inicie sesión nuevamente.');
      expect(e.almacen.sesion, isNull);
      e.controlador.dispose();
    });

    test('el temporizador periódico dispara la evaluación', () async {
      final e = Entorno(responder: (_) async => loginOk());
      // Controlador con intervalo corto
      final api = ApiCliente(
        cliente: e.servidor.cliente,
        baseUrl: 'http://x/api',
        tokenProvider: () => null,
      );
      final c = SesionControlador(
        api: api,
        auth: AuthServicio(api, reloj: () => e.ahora),
        almacen: AlmacenMemoria(),
        reloj: () => e.ahora,
        intervalo: const Duration(milliseconds: 20),
        observarCicloVida: false,
      );
      await c.iniciarSesion('a@b.co', 'x');
      e.ahora = e.ahora.add(const Duration(minutes: 31));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(c.estado, EstadoSesion.anonimo);
      c.dispose();
      e.controlador.dispose();
    });
  });

  group('cerrarSesion', () {
    for (final caso in {
      'logout 200': (http.Request _) async => okResp({'mensaje': 'ok'}),
      'RED': (http.Request _) async => throw http.ClientException('sin red'),
      '401': (http.Request _) async => errResp(401, 'SESION_EXPIRADA'),
    }.entries) {
      test('U16: ${caso.key} -> almacén vacío, anonimo y flash de cierre', () async {
        final e = Entorno(
          responder: (p) async =>
              p.url.path.endsWith('login') ? loginOk() : caso.value(p),
        );
        await e.controlador.iniciarSesion('a@b.co', 'x');
        await e.controlador.cerrarSesion();
        expect(e.almacen.sesion, isNull);
        expect(e.controlador.estado, EstadoSesion.anonimo);
        expect(e.controlador.flash, 'Sesión cerrada correctamente.');
        expect(e.servidor.a('/auth/logout'), hasLength(1));
        e.controlador.dispose();
      });
    }
  });

  test('U17: 401 TOKEN_INVALIDO en una petición autenticada cierra la sesión local', () async {
    var n = 0;
    final e = Entorno(
      responder: (_) async => n++ == 0 ? loginOk() : errResp(401, 'TOKEN_INVALIDO'),
    );
    await e.controlador.iniciarSesion('a@b.co', 'x');
    await e.controlador.seguirConectado();
    await vaciar();
    expect(e.controlador.flash, 'Su sesión fue cerrada. Inicie sesión nuevamente.');
    expect(e.controlador.estado, EstadoSesion.anonimo);
    e.controlador.dispose();
  });

  test('descartarSesionLocal borra sin llamar al servidor', () async {
    final e = Entorno(
      responder: (_) async => throw http.ClientException('sin red'),
      almacen: AlmacenMemoria(sesionGuardada(ultimaActividad: DateTime.utc(2026, 11, 25, 11, 59))),
    );
    await e.controlador.iniciar();
    expect(e.controlador.estado, EstadoSesion.errorConexion);
    final antes = e.servidor.peticiones.length;
    await e.controlador.descartarSesionLocal();
    expect(e.controlador.estado, EstadoSesion.anonimo);
    expect(e.almacen.sesion, isNull);
    expect(e.servidor.peticiones.length, antes);
    e.controlador.dispose();
  });

  test('iniciar() con perfil mal formado (ok:true, data nulo) -> errorConexion', () async {
    final e = Entorno(
      responder: (_) async => jsonResp(200, {'ok': true, 'data': null}),
      almacen: AlmacenMemoria(sesionGuardada(ultimaActividad: DateTime.utc(2026, 11, 25, 11, 59))),
    );
    await e.controlador.iniciar();
    expect(e.controlador.estado, EstadoSesion.errorConexion);
    expect(e.almacen.sesion, isNotNull);
    e.controlador.dispose();
  });

  test('seguirConectado falla por RED: conserva la sesión, mantiene el aviso y expone el motivo', () async {
    var n = 0;
    final e = Entorno(
      responder: (_) async => n++ == 0 ? loginOk() : throw http.ClientException('x'),
    );
    await e.controlador.iniciarSesion('a@b.co', 'x');
    e.ahora = e.ahora.add(const Duration(minutes: 29, seconds: 30));
    e.controlador.evaluarInactividad();
    expect(await e.controlador.seguirConectado(), isFalse);
    expect(e.controlador.estado, EstadoSesion.autenticado);
    expect(e.controlador.mostrarAviso, isTrue);
    expect(e.controlador.errorAviso, contains('No se pudo conectar'));
    e.controlador.dispose();
  });
}
