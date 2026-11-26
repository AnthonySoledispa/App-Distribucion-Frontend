import 'package:material_ui/material_ui.dart';

/// Campo de contraseña con botón de ojo para mostrar u ocultar.
class CampoContrasena extends StatefulWidget {
  const CampoContrasena({
    super.key,
    required this.controlador,
    this.validador,
    this.alEnviar,
    this.habilitado = true,
  });

  final TextEditingController controlador;
  final String? Function(String?)? validador;
  final VoidCallback? alEnviar;
  final bool habilitado;

  @override
  State<CampoContrasena> createState() => _CampoContrasenaState();
}

class _CampoContrasenaState extends State<CampoContrasena> {
  bool _oculta = true;

  @override
  Widget build(BuildContext context) {
    final etiquetaOjo = _oculta ? 'Mostrar contraseña' : 'Ocultar contraseña';
    return TextFormField(
      controller: widget.controlador,
      enabled: widget.habilitado,
      obscureText: _oculta,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      validator: widget.validador,
      onFieldSubmitted: (_) => widget.alEnviar?.call(),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: etiquetaOjo,
          icon: Icon(_oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _oculta = !_oculta),
        ),
      ),
    );
  }
}
