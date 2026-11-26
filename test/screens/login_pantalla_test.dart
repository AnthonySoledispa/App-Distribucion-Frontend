import 'dart:async';

import 'package:distrigo_repartidor/services/sesion_controlador.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../fakes/almacen_memoria.dart';
import '../fakes/entorno.dart';
import '../fakes/montar.dart';
import '../fakes/respuestas.dart';

void tamanoTelefono(WidgetTester t, {double w = 390, double h = 844}) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  addTearDown(t.view.resetViewInsets);
}

Future<Entorno> loginListo(
  WidgetTester t,
  Future<http.Response> Function(http.Request) responder,
) async {
  tamanoTelefono(t);
  final e = Entorno(responder: responder);
  await e.controlador.iniciar();
  await montarApp(t, e);
  await t.pump();
  return e;
}

void main() {
  testWidgets('W01: el login muestra los textos esperados y nada de registro', (t) async {
    final e = await loginListo(t, (_) async => loginOk());
    for (final texto in [
      'DistriGO',
      'Gestiona, ordena, distribuye.',
      'Iniciar sesión',
      'Ingrese con su cuenta de repartidor.',
      'Correo electrónico',
      'Contraseña',
      'Ingresar',
      '¿Problemas para entrar? Contacte a su administrador.',
    ]) {
      expect(find.text(texto), findsWidgets, reason: texto);
    }
    for (final prohibido in ['Registr', 'Olvid', 'Recuper', 'Crear cuenta']) {
      expect(find.textContaining(prohibido), findsNothing, reason: prohibido);
    }
    await finalizar(t, e);
  });

  testWidgets('W02: enviar vacío muestra errores y no hace peticiones', (t) async {
    final e = await loginListo(t, (_) async => loginOk());
    await t.tap(find.text('Ingresar'));
    await t.pump();
    expect(find.text('Ingrese su correo.'), findsOneWidget);
    expect(find.text('Ingrese su contraseña.'), findsOneWidget);
    expect(e.servidor.peticiones, isEmpty);
    await finalizar(t, e);
  });

  testWidgets('W03: el ojo alterna obscureText y su tooltip', (t) async {
    final e = await loginListo(t, (_) async => loginOk());
    bool oculto() => t
        .widget<EditableText>(
          find.descendant(
            of: find.byType(TextFormField).at(1),
            matching: find.byType(EditableText),
          ),
        )
        .obscureText;
    expect(oculto(), isTrue);
    expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);
    await t.tap(find.byTooltip('Mostrar contraseña'));
    await t.pump();
    expect(oculto(), isFalse);
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    await finalizar(t, e);
  });

  testWidgets('W04: 401 muestra el mensaje genérico, vacía la contraseña y conserva el correo', (t) async {
    final e = await loginListo(t, (_) async => errResp(401, 'CREDENCIALES_INVALIDAS'));
    await escribirLogin(t);
    await t.tap(find.text('Ingresar'));
    await t.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('rosa@distrigo.test'), findsOneWidget);
    expect(find.text('clave-secreta'), findsNothing);
    expect(t.widget<TextFormField>(find.byType(TextFormField).at(1)).controller!.text, isEmpty);
    await finalizar(t, e);
  });

  final casos = <String, (Future<http.Response> Function(http.Request), String)>{
    'USUARIO_INACTIVO': (
      (_) async => errResp(403, 'USUARIO_INACTIVO'),
      'Usuario desactivado. Contacte al administrador.',
    ),
    'CLIENTE_NO_PERMITIDO': (
      (_) async => errResp(403, 'CLIENTE_NO_PERMITIDO'),
      'Esta cuenta no tiene acceso a la aplicación móvil. Los administradores ingresan desde el panel web.',
    ),
    '429': (
      (_) async => errResp(429, 'DEMASIADOS_INTENTOS', 'Espere 5 minutos para reintentar.'),
      'Espere 5 minutos para reintentar.',
    ),
    'RED': (
      (_) async => throw http.ClientException('sin red'),
      'No se pudo conectar con el servidor. Verifique su conexión e intente de nuevo.',
    ),
  };
  for (final caso in casos.entries) {
    testWidgets('W05: ${caso.key}', (t) async {
      final e = await loginListo(t, caso.value.$1);
      await escribirLogin(t);
      await t.tap(find.text('Ingresar'));
      await t.pumpAndSettle();
      expect(find.text(caso.value.$2), findsOneWidget);
      await finalizar(t, e);
    });
  }

  testWidgets('W06: doble toque envía una sola petición y muestra Ingresando…', (t) async {
    final pendiente = Completer<http.Response>();
    final e = await loginListo(t, (_) => pendiente.future);
    await escribirLogin(t);
    await t.tap(find.text('Ingresar'));
    await t.pump();
    expect(find.text('Ingresando…'), findsOneWidget);
    expect(t.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await t.tap(find.text('Ingresando…'), warnIfMissed: false);
    await t.pump();
    expect(e.servidor.a('/auth/login'), hasLength(1));

    pendiente.complete(loginOk());
    await t.pumpAndSettle();
    expect(find.text('Mi ruta de hoy'), findsWidgets);
    await finalizar(t, e);
  });

  testWidgets('el flash de inactividad se muestra como información y se borra al enviar', (t) async {
    tamanoTelefono(t);
    final e = Entorno(
      responder: (_) async => errResp(401, 'CREDENCIALES_INVALIDAS'),
      almacen: AlmacenMemoria(
        sesionGuardada(ultimaActividad: DateTime.utc(2026, 11, 25, 10)),
      ),
    );
    await e.controlador.iniciar();
    await montarApp(t, e);
    await t.pump();
    const flash = 'Su sesión expiró por inactividad. Inicie sesión nuevamente.';
    expect(find.text(flash), findsOneWidget);

    await escribirLogin(t);
    await t.tap(find.text('Ingresar'));
    await t.pumpAndSettle();
    expect(find.text(flash), findsNothing);
    await finalizar(t, e);
  });

  for (final (w, h, top) in [
    (360.0, 640.0, 0.0),
    (360.0, 640.0, 24.0),
    (360.0, 640.0, 48.0),
    (360.0, 800.0, 24.0),
    (360.0, 800.0, 40.0),
    (393.0, 851.0, 48.0),
  ]) {
    testWidgets('W11: ${w}x$h, barra superior $top, teclado simulado, sin overflow y botón de 52 px', (t) async {
      tamanoTelefono(t, w: w, h: h);
      t.view.viewInsets = const FakeViewPadding(bottom: 300);
      t.view.padding = FakeViewPadding(top: top);
      t.view.viewPadding = FakeViewPadding(top: top);
      addTearDown(t.view.resetPadding);
      addTearDown(t.view.resetViewPadding);
      final e = Entorno(responder: (_) async => loginOk());
      await e.controlador.iniciar();
      await montarApp(t, e);
      await t.pump();
      expect(t.takeException(), isNull);
      expect(t.getSize(find.byType(FilledButton)).height, 52);
      expect(e.controlador.estado, EstadoSesion.anonimo);
      await finalizar(t, e);
    });
  }
}
