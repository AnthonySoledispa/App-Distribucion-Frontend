import 'package:material_ui/material_ui.dart';

import '../config/tema.dart';
import 'mini_ruta.dart';

/// Cabecera azul marino del login: logo, nombre, lema y mini ruta.
class CabeceraMarca extends StatelessWidget {
  const CabeceraMarca({super.key, required this.alto});

  final double alto;

  @override
  Widget build(BuildContext context) {
    // El alto pedido es el de la zona útil; se suma la barra de estado.
    return Container(
      height: alto + MediaQuery.paddingOf(context).top,
      width: double.infinity,
      color: ColoresDistriGO.principal,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 56),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Image.asset(
                  'assets/images/logo_distrigo.png',
                  semanticLabel: 'Logo de DistriGO',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'DistriGO',
                style: EstilosTexto.titulo(tamano: 34, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                'Gestiona, ordena, distribuye.',
                textAlign: TextAlign.center,
                style: EstilosTexto.cuerpo(
                  tamano: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
              const MiniRuta(),
            ],
          ),
        ),
      ),
    );
  }
}
