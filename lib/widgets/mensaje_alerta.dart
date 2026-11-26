import 'package:material_ui/material_ui.dart';

import '../config/tema.dart';

/// Caja de error (rojo #730505) o de información, anunciada a lectores de pantalla.
class MensajeAlerta extends StatelessWidget {
  const MensajeAlerta.error(this.texto, {super.key}) : esError = true;
  const MensajeAlerta.info(this.texto, {super.key}) : esError = false;

  final String texto;
  final bool esError;

  @override
  Widget build(BuildContext context) {
    final color = esError ? ColoresDistriGO.error : ColoresDistriGO.principal;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.info_outline,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                texto,
                style: EstilosTexto.cuerpo(tamano: 14, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
