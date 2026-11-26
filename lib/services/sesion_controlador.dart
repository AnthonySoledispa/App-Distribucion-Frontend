// Los parámetros con nombre no pueden ser privados: se asignan en la lista de inicialización.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/api_error.dart';
import '../models/sesion.dart';
import '../models/usuario.dart';
import 'almacen_sesion.dart';
import 'api_cliente.dart';
import 'auth_servicio.dart';
import 'mensajes.dart';

enum EstadoSesion { verificando, anonimo, autenticado, errorConexion }

/// Maneja la sesión del repartidor: inicio, cierre, inactividad y token.
///
/// La inactividad se mide como en el backend: solo las peticiones autenticadas
/// renuevan la actividad (los toques en pantalla no).
class SesionControlador extends ChangeNotifier {
  SesionControlador({
    required ApiCliente api,
    required AuthServicio auth,
    required AlmacenSesion almacen,
    DateTime Function()? reloj,
    Duration intervalo = const Duration(seconds: 15),
    bool observarCicloVida = true,
  }) : _api = api,
       _auth = auth,
       _almacen = almacen,
       _reloj = reloj ?? DateTime.now,
       _intervalo = intervalo {
    _api.alSesionInvalida = _alSesionInvalida;
    _api.alActividad = _alActividad;
    if (observarCicloVida) {
      _ciclo = AppLifecycleListener(onResume: evaluarInactividad);
    }
  }

  /// Segundos antes del límite en que aparece el aviso.
  static const Duration antesDelAviso = Duration(seconds: 60);

  final ApiCliente _api;
  final AuthServicio _auth;
  final AlmacenSesion _almacen;
  final DateTime Function() _reloj;
  final Duration _intervalo;
  AppLifecycleListener? _ciclo;
  Timer? _temporizador;
  Future<void> _pendiente = Future.value();
  bool _cerrando = false;
  bool _liberado = false;

  Sesion? _sesion;
  EstadoSesion _estado = EstadoSesion.verificando;
  String? _flash;
  bool _mostrarAviso = false;
  String? _errorAviso;

  EstadoSesion get estado => _estado;
  Usuario? get usuario => _sesion?.usuario;
  String? get token => _sesion?.token;
  String? get flash => _flash;
  bool get mostrarAviso => _mostrarAviso;

  /// Motivo por el que falló "Seguir conectado" (null si no hubo fallo).
  String? get errorAviso => _errorAviso;
  DateTime get ahora => _reloj();

  /// Segundos que faltan para el cierre por inactividad (0 si ya se cumplió).
  int get segundosRestantes {
    final s = _sesion;
    if (s == null) return 0;
    final restante = s.ultimaActividad.add(s.limiteInactividad).difference(
      _reloj(),
    );
    return restante.isNegative ? 0 : restante.inSeconds;
  }

  void limpiarFlash() {
    if (_flash == null) return;
    _flash = null;
    _avisar();
  }

  /// Arranque en frío o reintento: decide la pantalla inicial.
  Future<void> iniciar() async {
    _estado = EstadoSesion.verificando;
    _avisar();

    final guardada = await _almacen.leer();
    if (guardada == null) {
      _sesion = null;
      _cambiarEstado(EstadoSesion.anonimo);
      return;
    }
    _sesion = guardada;

    if (_inactividadSuperada(guardada)) {
      _expirarPorInactividad();
      await _pendiente;
      return;
    }

    try {
      final usuario = await _auth.perfil();
      if (_sesion == null) return;
      if (!usuario.esRepartidor) {
        await _cerrarLocal(EstadoSesion.anonimo);
        return;
      }
      _sesion = _sesion!.copiarCon(usuario: usuario);
      _encadenar(() => _almacen.guardar(_sesion!));
      _cambiarEstado(EstadoSesion.autenticado);
      _arrancarTemporizador();
    } on ApiError catch (e) {
      if (e.esSesionInvalida) {
        await _pendiente;
        return;
      }
      // Fallo de red o del servidor: se conserva el token.
      _detenerTemporizador();
      _cambiarEstado(EstadoSesion.errorConexion);
    } catch (_) {
      // Fallo inesperado: nunca dejar la app en "Verificando sesión…".
      _detenerTemporizador();
      _cambiarEstado(EstadoSesion.errorConexion);
    }
  }

  /// Inicia sesión. Lanza [ApiError] si falla o si el rol no es repartidor.
  Future<void> iniciarSesion(String correo, String contrasena) async {
    _flash = null;
    final nueva = await _auth.login(correo, contrasena);

    if (!nueva.usuario.esRepartidor) {
      // Defensa: el backend ya lo bloquea con cliente 'movil'. Se cierra la
      // sesión recién creada y no se guarda nada.
      _sesion = nueva;
      _cerrando = true;
      unawaited(_auth.logout().then((_) {}, onError: (_) {}));
      _sesion = null;
      _cerrando = false;
      throw const ApiError(estado: 403, codigo: 'CLIENTE_NO_PERMITIDO');
    }

    final conActividad = nueva.copiarCon(ultimaActividad: _reloj().toUtc());
    _sesion = conActividad;
    await _almacen.guardar(conActividad);
    _mostrarAviso = false;
    _cambiarEstado(EstadoSesion.autenticado);
    _arrancarTemporizador();
  }

  /// Cierra la sesión. Siempre limpia lo local, aunque falle el servidor.
  Future<void> cerrarSesion() async {
    if (_sesion != null) {
      _cerrando = true;
      try {
        await _auth.logout();
      } catch (_) {
        // Sin red o 401: igual se cierra la sesión local.
      }
      _cerrando = false;
    }
    _flash = Mensajes.flashLogout;
    await _cerrarLocal(EstadoSesion.anonimo);
  }

  /// Borra la sesión local sin avisar al servidor (pantalla Sin conexión).
  Future<void> descartarSesionLocal() async {
    await _cerrarLocal(EstadoSesion.anonimo);
  }

  /// Renueva la sesión pidiendo el perfil. Devuelve true si va bien.
  Future<bool> seguirConectado() async {
    try {
      await _auth.perfil();
      if (_sesion == null) return false;
      _mostrarAviso = false;
      _errorAviso = null;
      _avisar();
      return true;
    } on ApiError catch (e) {
      // Sesión inválida: ya la resolvió el manejador. Otro fallo (red,
      // servidor): el aviso vuelve a mostrarse con el motivo.
      if (_sesion != null && !e.esSesionInvalida) {
        _errorAviso = Mensajes.deError(e);
        _mostrarAviso = true;
        _avisar();
      }
      return false;
    }
  }

  /// Compara la última actividad con el límite. Pública para poder probarla.
  void evaluarInactividad() {
    final s = _sesion;
    if (s == null || _estado != EstadoSesion.autenticado) return;
    final restante = s.ultimaActividad
        .add(s.limiteInactividad)
        .difference(_reloj());
    if (restante <= Duration.zero) {
      _expirarPorInactividad();
    } else if (restante <= antesDelAviso && !_mostrarAviso) {
      _mostrarAviso = true;
      _avisar();
    }
  }

  // ---- Internos ----

  bool _inactividadSuperada(Sesion s) =>
      !s.ultimaActividad.add(s.limiteInactividad).isAfter(_reloj());

  void _expirarPorInactividad() {
    _flash = Mensajes.flashInactividad;
    _sesion = null;
    _detenerTemporizador();
    _mostrarAviso = false;
    _errorAviso = null;
    _encadenar(_almacen.borrar);
    _cambiarEstado(EstadoSesion.anonimo);
  }

  void _alSesionInvalida(String codigo) {
    final s = _sesion;
    if (s == null || _cerrando) return;
    _flash = Mensajes.flashDeCodigo(
      codigo,
      porInactividad: _inactividadSuperada(s),
    );
    _sesion = null;
    _detenerTemporizador();
    _mostrarAviso = false;
    _errorAviso = null;
    _encadenar(_almacen.borrar);
    _cambiarEstado(EstadoSesion.anonimo);
  }

  void _alActividad(DateTime ahoraServidor) {
    final s = _sesion;
    if (s == null || _cerrando) return;
    final utc = ahoraServidor.toUtc();
    _sesion = s.copiarCon(ultimaActividad: utc);
    _encadenar(() => _almacen.actualizarActividad(utc));
    if (_mostrarAviso && segundosRestantes > antesDelAviso.inSeconds) {
      _mostrarAviso = false;
      _avisar();
    }
  }

  Future<void> _cerrarLocal(EstadoSesion destino) async {
    _sesion = null;
    _detenerTemporizador();
    _mostrarAviso = false;
    _errorAviso = null;
    _encadenar(_almacen.borrar);
    await _pendiente;
    _cambiarEstado(destino);
  }

  /// Encadena operaciones del almacén para que se ejecuten en orden.
  void _encadenar(Future<void> Function() accion) {
    _pendiente = _pendiente.then((_) => accion()).catchError((_) {});
  }

  void _arrancarTemporizador() {
    _temporizador?.cancel();
    _temporizador = Timer.periodic(_intervalo, (_) => evaluarInactividad());
  }

  void _detenerTemporizador() {
    _temporizador?.cancel();
    _temporizador = null;
  }

  void _cambiarEstado(EstadoSesion nuevo) {
    _estado = nuevo;
    _avisar();
  }

  void _avisar() {
    if (!_liberado) notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    _temporizador?.cancel();
    _ciclo?.dispose();
    super.dispose();
  }
}
