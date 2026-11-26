import 'package:distrigo_repartidor/app.dart';
import 'package:distrigo_repartidor/services/sesion_controlador.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'entorno.dart';

/// Monta la app completa con el controlador de [e] (sin llamar a iniciar()).
Future<void> montarApp(WidgetTester tester, Entorno e) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<SesionControlador>.value(
      value: e.controlador,
      child: const DistriGoApp(),
    ),
  );
}

/// Desmonta y libera temporizadores para que la prueba termine limpia.
Future<void> finalizar(WidgetTester tester, Entorno e) async {
  await tester.pumpWidget(const SizedBox());
  e.controlador.dispose();
}

Future<void> escribirLogin(
  WidgetTester tester, {
  String correo = 'rosa@distrigo.test',
  String contrasena = 'clave-secreta',
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), correo);
  await tester.enterText(find.byType(TextFormField).at(1), contrasena);
}
