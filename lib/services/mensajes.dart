import '../models/api_error.dart';

/// Textos en español según el código del backend (el backend los envía sin tildes).
class Mensajes {
  Mensajes._();

  static const credenciales = 'Correo o contraseña incorrectos.';
  static const inactivo = 'Usuario desactivado. Contacte al administrador.';
  static const clienteNoPermitido =
      'Esta cuenta no tiene acceso a la aplicación móvil. Los administradores ingresan desde el panel web.';
  static const demasiadosIntentos =
      'Demasiados intentos fallidos. Intente de nuevo más tarde.';
  static const validacion = 'Revise los datos ingresados.';
  static const sinConexion =
      'No se pudo conectar con el servidor. Verifique su conexión e intente de nuevo.';
  static const servicioNoDisponible =
      'El servicio no está disponible en este momento. Intente más tarde.';
  static const inesperado = 'Ocurrió un error inesperado. Intente de nuevo.';

  static const flashInactividad =
      'Su sesión expiró por inactividad. Inicie sesión nuevamente.';
  static const flashExpirada = 'Su sesión expiró. Inicie sesión nuevamente.';
  static const flashCerrada = 'Su sesión fue cerrada. Inicie sesión nuevamente.';
  static const flashLogout = 'Sesión cerrada correctamente.';

  /// Texto para mostrar al usuario según el error.
  static String deError(ApiError e) {
    switch (e.codigo) {
      case 'CREDENCIALES_INVALIDAS':
        return credenciales;
      case 'USUARIO_INACTIVO':
        return inactivo;
      case 'CLIENTE_NO_PERMITIDO':
        return clienteNoPermitido;
      case 'DEMASIADOS_INTENTOS':
        return e.mensaje.isNotEmpty ? e.mensaje : demasiadosIntentos;
      case 'VALIDACION':
        return validacion;
      case 'RED':
      case 'TIEMPO_AGOTADO':
        return sinConexion;
      case 'BD_NO_DISPONIBLE':
      case 'RESPUESTA_INVALIDA':
        return servicioNoDisponible;
    }
    if (e.estado == 429) {
      return e.mensaje.isNotEmpty ? e.mensaje : demasiadosIntentos;
    }
    if (e.estado == 401) return credenciales;
    if (e.estado >= 500) return servicioNoDisponible;
    return inesperado;
  }

  /// Flash tras una sesión inválida detectada por el servidor.
  /// [porInactividad] indica que el tiempo local de inactividad se cumplió.
  static String flashDeCodigo(String codigo, {bool porInactividad = false}) {
    if (codigo == 'SESION_EXPIRADA' || codigo == 'INACTIVIDAD') {
      return porInactividad ? flashInactividad : flashExpirada;
    }
    return flashCerrada;
  }
}
