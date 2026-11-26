import 'package:material_ui/material_ui.dart';

import '../services/sesion_controlador.dart';
import 'mensaje_alerta.dart';

/// Diálogo de aviso de cierre por inactividad con cuenta regresiva.
/// Se redibuja solo porque escucha al [SesionControlador] y a un reloj de 1 s.
class AvisoInactividad extends StatelessWidget {
  const AvisoInactividad({
    super.key,
    required this.controlador,
    required this.alSeguir,
    required this.alCerrar,
  });

  final SesionControlador controlador;
  final VoidCallback alSeguir;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Sesión por cerrarse'),
        content: StreamBuilder<int>(
          stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
          builder: (context, _) {
            final s = controlador.segundosRestantes;
            final error = controlador.errorAviso;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Su sesión está por cerrarse por inactividad. Se cerrará en $s s.',
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  MensajeAlerta.error(error),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: alCerrar, child: const Text('Cerrar sesión')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: alSeguir,
            child: const Text('Seguir conectado'),
          ),
        ],
      ),
    );
  }
}
