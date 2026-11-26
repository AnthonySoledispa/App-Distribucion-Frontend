import 'package:distrigo_repartidor/models/api_error.dart';
import 'package:distrigo_repartidor/services/mensajes.dart';
import 'package:flutter_test/flutter_test.dart';

String t(int estado, String codigo, [String mensaje = '']) =>
    Mensajes.deError(ApiError(estado: estado, codigo: codigo, mensaje: mensaje));

void main() {
  test('U07: texto por código', () {
    expect(t(401, 'CREDENCIALES_INVALIDAS'), 'Correo o contraseña incorrectos.');
    expect(t(401, 'OTRO'), 'Correo o contraseña incorrectos.');
    expect(t(403, 'USUARIO_INACTIVO'), 'Usuario desactivado. Contacte al administrador.');
    expect(
      t(403, 'CLIENTE_NO_PERMITIDO'),
      'Esta cuenta no tiene acceso a la aplicación móvil. Los administradores ingresan desde el panel web.',
    );
    expect(t(400, 'VALIDACION'), 'Revise los datos ingresados.');
    const sinRed =
        'No se pudo conectar con el servidor. Verifique su conexión e intente de nuevo.';
    expect(t(0, 'RED'), sinRed);
    expect(t(0, 'TIEMPO_AGOTADO'), sinRed);
    const noDisp = 'El servicio no está disponible en este momento. Intente más tarde.';
    expect(t(503, 'BD_NO_DISPONIBLE'), noDisp);
    expect(t(500, 'ERROR_INTERNO'), noDisp);
    expect(t(502, 'RESPUESTA_INVALIDA'), noDisp);
    expect(t(404, 'DESCONOCIDO'), 'Ocurrió un error inesperado. Intente de nuevo.');
  });

  test('429 usa el mensaje del backend o el genérico', () {
    expect(t(429, 'DEMASIADOS_INTENTOS', 'Espere 5 minutos.'), 'Espere 5 minutos.');
    expect(
      t(429, 'DEMASIADOS_INTENTOS'),
      'Demasiados intentos fallidos. Intente de nuevo más tarde.',
    );
  });

  test('flashes de sesión', () {
    expect(Mensajes.flashDeCodigo('SESION_EXPIRADA', porInactividad: true),
        'Su sesión expiró por inactividad. Inicie sesión nuevamente.');
    expect(Mensajes.flashDeCodigo('SESION_EXPIRADA'),
        'Su sesión expiró. Inicie sesión nuevamente.');
    for (final c in ['TOKEN_AUSENTE', 'TOKEN_INVALIDO', 'SESION_CERRADA']) {
      expect(Mensajes.flashDeCodigo(c), 'Su sesión fue cerrada. Inicie sesión nuevamente.');
    }
    expect(Mensajes.flashLogout, 'Sesión cerrada correctamente.');
  });
}
