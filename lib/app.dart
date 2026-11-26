import 'package:material_ui/material_ui.dart';

import 'config/tema.dart';
import 'screens/puerta_sesion.dart';

class DistriGoApp extends StatelessWidget {
  const DistriGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DistriGO',
      debugShowCheckedModeBanner: false,
      theme: construirTema(),
      locale: const Locale('es'),
      home: const PuertaSesion(),
    );
  }
}
