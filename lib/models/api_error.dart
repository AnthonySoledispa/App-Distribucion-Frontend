/// Error devuelto por la API o por la conexión.
///
/// `estado` 0 significa que no hubo respuesta del servidor
/// (códigos 'RED' y 'TIEMPO_AGOTADO').
class ApiError implements Exception {
  final int estado;
  final String codigo;
  final String mensaje;
  final List<Map<String, String>> errores;

  const ApiError({
    required this.estado,
    required this.codigo,
    this.mensaje = '',
    this.errores = const [],
  });

  static const codigosSesionInvalida = {
    'TOKEN_AUSENTE',
    'TOKEN_INVALIDO',
    'SESION_CERRADA',
    'SESION_EXPIRADA',
  };

  /// 401 que indica que la sesión ya no sirve.
  bool get esSesionInvalida =>
      estado == 401 && codigosSesionInvalida.contains(codigo);

  /// Fallo de conexión o del servidor (no es culpa del usuario).
  bool get esFalloDeConexion =>
      estado == 0 || estado >= 500 || codigo == 'RESPUESTA_INVALIDA';

  @override
  String toString() => 'ApiError($estado, $codigo)';
}
