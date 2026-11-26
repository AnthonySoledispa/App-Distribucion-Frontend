import 'package:material_ui/material_ui.dart';

/// Botón principal de 52 px de alto y ancho completo, con estado "cargando".
class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.alPresionar,
    this.cargando = false,
    this.textoCargando,
  });

  final String texto;
  final VoidCallback? alPresionar;
  final bool cargando;
  final String? textoCargando;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: cargando ? null : alPresionar,
        child: cargando
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(textoCargando ?? texto),
                ],
              )
            : Text(texto),
      ),
    );
  }
}
