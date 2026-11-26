import 'package:distrigo_repartidor/services/sesion_controlador.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/entorno.dart';
import '../fakes/montar.dart';
import '../fakes/respuestas.dart';
import 'login_pantalla_test.dart' show tamanoTelefono;

Future<Entorno> conSesion(WidgetTester t) async {
  tamanoTelefono(t);
  final e = Entorno(
    responder: (p) async => p.url.path.endsWith('login')
        ? loginOk()
        : okResp({'mensaje': 'ok'}),
  );
  await e.controlador.iniciarSesion('rosa@distrigo.test', 'x');
  await montarApp(t, e);
  await t.pump();
  return e;
}

void main() {
  testWidgets('muestra el saludo, la etiqueta y la tarjeta provisional', (t) async {
    final e = await conSesion(t);
    expect(find.text('Mi ruta de hoy'), findsOneWidget);
    expect(find.text('Hola, Rosa Pérez'), findsOneWidget);
    expect(find.text('Repartidor'), findsOneWidget);
    expect(
      find.text('Sus entregas del día aparecerán aquí cuando se habilite el módulo de rutas.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
    await finalizar(t, e);
  });

  testWidgets('W08: confirmar cierra la sesión y vuelve al login con el flash', (t) async {
    final e = await conSesion(t);
    await t.tap(find.byTooltip('Cerrar sesión'));
    await t.pumpAndSettle();
    expect(find.text('¿Desea cerrar sesión?'), findsOneWidget);
    await t.tap(find.text('Cerrar sesión'));
    await t.pumpAndSettle();
    expect(e.controlador.estado, EstadoSesion.anonimo);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Sesión cerrada correctamente.'), findsOneWidget);
    expect(e.almacen.sesion, isNull);
    await finalizar(t, e);
  });

  testWidgets('W08: cancelar no hace nada', (t) async {
    final e = await conSesion(t);
    await t.tap(find.byTooltip('Cerrar sesión'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(e.controlador.estado, EstadoSesion.autenticado);
    expect(find.text('Hola, Rosa Pérez'), findsOneWidget);
    expect(e.servidor.a('/auth/logout'), isEmpty);
    await finalizar(t, e);
  });
}
