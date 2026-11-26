import 'package:material_ui/material_ui.dart';

import '../config/tema.dart';

class CargandoPantalla extends StatelessWidget {
  const CargandoPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_distrigo.png',
              width: 96,
              height: 96,
              semanticLabel: 'Logo de DistriGO',
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: ColoresDistriGO.principal),
            const SizedBox(height: 16),
            Text('Verificando sesión…', style: EstilosTexto.cuerpo()),
          ],
        ),
      ),
    );
  }
}
