import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../services/sesion_controlador.dart';

/// Inicio provisional del repartidor (sin datos hasta el módulo de rutas).
class MiRutaPantalla extends StatelessWidget {
  const MiRutaPantalla({super.key});

  Future<void> _confirmarSalida(BuildContext context) {
    return showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) => const _DialogoSalida(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = context.select<SesionControlador, String>(
      (s) => s.usuario?.nombre ?? '',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi ruta de hoy'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmarSalida(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Hola, $nombre', style: EstilosTexto.titulo(tamano: 28)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(
                  'Repartidor',
                  style: EstilosTexto.cuerpo(
                    tamano: 13,
                    negrita: true,
                    color: ColoresDistriGO.principal,
                  ),
                ),
                backgroundColor: ColoresDistriGO.principal.withValues(
                  alpha: 0.08,
                ),
                side: BorderSide.none,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: ColoresDistriGO.texto.withValues(alpha: 0.12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      color: ColoresDistriGO.secundario,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sus entregas del día aparecerán aquí cuando se habilite el módulo de rutas.',
                        style: EstilosTexto.cuerpo(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmación de salida. Evita el doble envío mientras se cierra la sesión
/// y se cierra sola si la sesión termina por otro motivo.
class _DialogoSalida extends StatefulWidget {
  const _DialogoSalida();

  @override
  State<_DialogoSalida> createState() => _DialogoSalidaState();
}

class _DialogoSalidaState extends State<_DialogoSalida> {
  SesionControlador? _sesion;
  bool _cerrando = false;
  bool _cerrado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sesion ??= context.read<SesionControlador>()..addListener(_alCambiar);
  }

  @override
  void dispose() {
    _sesion?.removeListener(_alCambiar);
    super.dispose();
  }

  void _alCambiar() {
    if (_sesion!.estado != EstadoSesion.autenticado) _cerrarDialogo();
  }

  void _cerrarDialogo() {
    if (_cerrado || !mounted) return;
    _cerrado = true;
    Navigator.of(context).pop();
  }

  Future<void> _confirmar() async {
    if (_cerrando) return;
    setState(() => _cerrando = true);
    await _sesion!.cerrarSesion();
    _cerrarDialogo();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Desea cerrar sesión?'),
      actions: [
        TextButton(
          onPressed: _cerrando ? null : _cerrarDialogo,
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: _cerrando ? null : _confirmar,
          child: _cerrando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
