import 'package:distrigo_repartidor/services/sesion_controlador.dart';
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../fakes/almacen_memoria.dart';
import '../fakes/entorno.dart';
import '../fakes/montar.dart';
import '../fakes/respuestas.dart';
import 'login_pantalla_test.dart' show tamanoTelefono;

void main() {
  testWidgets('W07: login correcto lleva a Mi ruta de hoy con el saludo', (t) async {
    tamanoTelefono(t);
    final e = Entorno(responder: (_) async => loginOk());
    await e.controlador.iniciar();
    await montarApp(t, e);
    await t.pump();
    await escribirLogin(t);
    await t.tap(find.text('Ingresar'));
    await t.pumpAndSettle();
    expect(find.text('Mi ruta de hoy'), findsOneWidget);
    expect(find.text('Hola, Rosa Pérez'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsNothing);
    await finalizar(t, e);
  });

  testWidgets('verificando muestra la pantalla de carga', (t) async {
    tamanoTelefono(t);
    final e = Entorno();
    await montarApp(t, e);
    await t.pump();
    expect(find.text('Verificando sesión…'), findsOneWidget);
    await finalizar(t, e);
  });

  testWidgets('W09: errorConexion muestra Sin conexión y Reintentar vuelve a iniciar()', (t) async {
    tamanoTelefono(t);
    var conectado = false;
    final e = Entorno(
      responder: (_) async => conectado
          ? okResp(usuarioJson())
          : throw http.ClientException('sin red'),
      almacen: AlmacenMemoria(
        sesionGuardada(ultimaActividad: DateTime.utc(2026, 11, 25, 11, 59)),
      ),
    );
    await e.controlador.iniciar();
    await montarApp(t, e);
    await t.pump();
    expect(find.text('No se pudo conectar con el servidor.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);

    conectado = true;
    await t.tap(find.text('Reintentar'));
    await t.pumpAndSettle();
    expect(e.controlador.estado, EstadoSesion.autenticado);
    expect(find.text('Mi ruta de hoy'), findsOneWidget);
    await finalizar(t, e);
  });

  testWidgets('Sin conexión: Cerrar sesión borra la sesión local', (t) async {
    tamanoTelefono(t);
    final e = Entorno(
      responder: (_) async => throw http.ClientException('sin red'),
      almacen: AlmacenMemoria(
        sesionGuardada(ultimaActividad: DateTime.utc(2026, 11, 25, 11, 59)),
      ),
    );
    await e.controlador.iniciar();
    await montarApp(t, e);
    await t.pump();
    await t.tap(find.text('Cerrar sesión'));
    await t.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(e.almacen.sesion, isNull);
    await finalizar(t, e);
  });

  testWidgets('W10: el aviso de inactividad aparece y "Seguir conectado" lo cierra', (t) async {
    tamanoTelefono(t);
    final e = Entorno(
      responder: (p) async =>
          p.url.path.endsWith('login') ? loginOk() : okResp(usuarioJson()),
    );
    await e.controlador.iniciarSesion('a@b.co', 'x');
    await montarApp(t, e);
    await t.pump();

    e.ahora = e.ahora.add(const Duration(minutes: 29, seconds: 30));
    e.controlador.evaluarInactividad();
    await t.pump();
    await t.pump();
    expect(find.textContaining('Su sesión está por cerrarse por inactividad.'), findsOneWidget);
    expect(find.text('Seguir conectado'), findsOneWidget);

    await t.tap(find.text('Seguir conectado'));
    await t.pumpAndSettle();
    expect(find.textContaining('Su sesión está por cerrarse'), findsNothing);
    expect(e.controlador.mostrarAviso, isFalse);
    expect(e.controlador.estado, EstadoSesion.autenticado);
    expect(e.servidor.a('/auth/perfil'), hasLength(1));
    await finalizar(t, e);
  });

  testWidgets('W10: "Cerrar sesión" del aviso cierra la sesión', (t) async {
    tamanoTelefono(t);
    final e = Entorno(
      responder: (p) async => p.url.path.endsWith('login')
          ? loginOk()
          : okResp({'mensaje': 'ok'}),
    );
    await e.controlador.iniciarSesion('a@b.co', 'x');
    await montarApp(t, e);
    await t.pump();
    e.ahora = e.ahora.add(const Duration(minutes: 29, seconds: 30));
    e.controlador.evaluarInactividad();
    await t.pump();
    await t.pump();

    await t.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Cerrar sesión')));
    await t.pumpAndSettle();
    expect(e.controlador.estado, EstadoSesion.anonimo);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Sesión cerrada correctamente.'), findsOneWidget);
    await finalizar(t, e);
  });

  testWidgets('al vencer la inactividad con el aviso abierto, vuelve al login con el flash', (t) async {
    tamanoTelefono(t);
    final e = Entorno(responder: (_) async => loginOk());
    await e.controlador.iniciarSesion('a@b.co', 'x');
    await montarApp(t, e);
    await t.pump();
    e.ahora = e.ahora.add(const Duration(minutes: 29, seconds: 30));
    e.controlador.evaluarInactividad();
    await t.pump();
    await t.pump();
    e.ahora = e.ahora.add(const Duration(minutes: 1));
    e.controlador.evaluarInactividad();
    await t.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Su sesión expiró por inactividad. Inicie sesión nuevamente.'), findsOneWidget);
    expect(find.textContaining('está por cerrarse'), findsNothing);
    await finalizar(t, e);
  });

  testWidgets('seguirConectado falla por RED: el aviso reaparece con el mensaje de conexión', (t) async {
    tamanoTelefono(t);
    var caido = false;
    final e = Entorno(
      responder: (p) async {
        if (p.url.path.endsWith('login')) return loginOk();
        if (caido) throw http.ClientException('sin red');
        return okResp(usuarioJson());
      },
    );
    await e.controlador.iniciarSesion('a@b.co', 'x');
    await montarApp(t, e);
    await t.pump();
    e.ahora = e.ahora.add(const Duration(minutes: 29, seconds: 30));
    e.controlador.evaluarInactividad();
    await t.pump();
    await t.pump();

    caido = true;
    await t.tap(find.text('Seguir conectado'));
    await t.pumpAndSettle();
    expect(e.controlador.estado, EstadoSesion.autenticado);
    expect(e.controlador.mostrarAviso, isTrue);
    expect(find.textContaining('Su sesión está por cerrarse'), findsOneWidget);
    expect(
      find.text('No se pudo conectar con el servidor. Verifique su conexión e intente de nuevo.'),
      findsOneWidget,
    );

    caido = false;
    await t.tap(find.text('Seguir conectado'));
    await t.pumpAndSettle();
    expect(find.textContaining('Su sesión está por cerrarse'), findsNothing);
    expect(e.controlador.mostrarAviso, isFalse);
    await finalizar(t, e);
  });

  testWidgets('si la sesión expira con la confirmación de salida abierta, el diálogo se cierra', (t) async {
    tamanoTelefono(t);
    final e = Entorno(responder: (_) async => loginOk());
    await e.controlador.iniciarSesion('a@b.co', 'x');
    await montarApp(t, e);
    await t.pump();
    await t.tap(find.byTooltip('Cerrar sesión'));
    await t.pumpAndSettle();
    expect(find.text('¿Desea cerrar sesión?'), findsOneWidget);

    e.ahora = e.ahora.add(const Duration(minutes: 31));
    e.controlador.evaluarInactividad();
    await t.pumpAndSettle();
    expect(find.text('¿Desea cerrar sesión?'), findsNothing);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    await finalizar(t, e);
  });

  testWidgets('la confirmación de salida bloquea el doble envío mientras espera', (t) async {
    tamanoTelefono(t);
    final pendiente = Completer<http.Response>();
    final e = Entorno(
      responder: (p) => p.url.path.endsWith('login')
          ? Future.value(loginOk())
          : pendiente.future,
    );
    await e.controlador.iniciarSesion('a@b.co', 'x');
    await montarApp(t, e);
    await t.pump();
    await t.tap(find.byTooltip('Cerrar sesión'));
    await t.pumpAndSettle();
    await t.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Cerrar sesión')));
    await t.pump();
    final botones = t.widgetList<FilledButton>(find.descendant(of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
    expect(botones.single.onPressed, isNull);
    expect(e.servidor.a('/auth/logout'), hasLength(1));

    pendiente.complete(okResp({'mensaje': 'ok'}));
    await t.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('¿Desea cerrar sesión?'), findsNothing);
    await finalizar(t, e);
  });
}
