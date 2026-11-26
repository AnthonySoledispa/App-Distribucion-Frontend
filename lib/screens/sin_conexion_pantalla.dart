import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../services/sesion_controlador.dart';
import '../widgets/boton_principal.dart';

class SinConexionPantalla extends StatelessWidget {
  const SinConexionPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = context.read<SesionControlador>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 64,
                    color: ColoresDistriGO.principal,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se pudo conectar con el servidor.',
                    textAlign: TextAlign.center,
                    style: EstilosTexto.titulo(tamano: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verifique su conexión e intente de nuevo.',
                    textAlign: TextAlign.center,
                    style: EstilosTexto.cuerpo(),
                  ),
                  const SizedBox(height: 24),
                  BotonPrincipal(
                    texto: 'Reintentar',
                    alPresionar: sesion.iniciar,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: sesion.descartarSesionLocal,
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
