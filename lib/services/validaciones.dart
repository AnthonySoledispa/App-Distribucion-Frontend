/// Validaciones locales del login (no sustituyen al backend).
final RegExp _formatoCorreo = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? validarCorreoLogin(String? valor) {
  final correo = (valor ?? '').trim();
  if (correo.isEmpty) return 'Ingrese su correo.';
  if (correo.length > 150 || !_formatoCorreo.hasMatch(correo)) {
    return 'Ingrese un correo válido.';
  }
  return null;
}

/// No se valida longitud ni composición: no se revela la política en el login.
String? validarContrasenaLogin(String? valor) {
  if (valor == null || valor.isEmpty) return 'Ingrese su contraseña.';
  return null;
}
