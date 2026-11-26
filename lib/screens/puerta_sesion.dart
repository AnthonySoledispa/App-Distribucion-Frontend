import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../services/sesion_controlador.dart';
import '../widgets/aviso_inactividad.dart';
import 'cargando_pantalla.dart';
import 'login_pantalla.dart';
import 'mi_ruta_pantalla.dart';
import 'sin_conexion_pantalla.dart';

/// Elige la pantalla según el estado de la sesión y muestra el aviso de
/// inactividad. Sin router: al iniciar o cerrar sesión no queda nada al que
/// volver con "Atrás".
class PuertaSesion extends StatefulWidget {
  const PuertaSesion({super.key});

  @override
  State<PuertaSesion> createState() => _PuertaSesionState();
}

class _PuertaSesionState extends State<PuertaSesion> {
  final _claveNavegador = GlobalKey<NavigatorState>();
  bool _dialogoAbierto = false;
  SesionControlador? _controlador;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = context.read<SesionControlador>();
    if (!identical(c, _controlador)) {
      _controlador?.removeListener(_alCambiar);
      _controlador = c..addListener(_alCambiar);
    }
  }

  @override
  void dispose() {
    _controlador?.removeListener(_alCambiar);
    super.dispose();
  }

  void _alCambiar() {
    final c = _controlador!;
    final debeMostrar =
        c.mostrarAviso && c.estado == EstadoSesion.autenticado;
    if (debeMostrar && !_dialogoAbierto) {
      _abrirAviso(c);
    } else if (!debeMostrar && _dialogoAbierto) {
      _dialogoAbierto = false;
      _claveNavegador.currentState?.pop();
    }
  }

  void _abrirAviso(SesionControlador c) {
    _dialogoAbierto = true;
    final contexto = _claveNavegador.currentContext;
    if (contexto == null) {
      _dialogoAbierto = false;
      return;
    }
    showDialog<void>(
      context: contexto,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (ctx) => AvisoInactividad(
        controlador: c,
        alSeguir: () {
          _dialogoAbierto = false;
          Navigator.of(ctx).pop();
          c.seguirConectado();
        },
        alCerrar: () {
          _dialogoAbierto = false;
          Navigator.of(ctx).pop();
          c.cerrarSesion();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Navigator propio para poder mostrar el diálogo sobre cualquier pantalla.
    return Navigator(
      key: _claveNavegador,
      onGenerateRoute: (_) => PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const _Raiz(),
        transitionDuration: Duration.zero,
      ),
    );
  }
}

/// Raíz que reconstruye la pantalla según el estado (dentro del Navigator).
class _Raiz extends StatelessWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context) {
    final estado = context.select<SesionControlador, EstadoSesion>(
      (s) => s.estado,
    );
    return switch (estado) {
      EstadoSesion.verificando => const CargandoPantalla(),
      EstadoSesion.anonimo => const LoginPantalla(),
      EstadoSesion.autenticado => const MiRutaPantalla(),
      EstadoSesion.errorConexion => const SinConexionPantalla(),
    };
  }
}
