import 'package:distrigo_repartidor/services/validaciones.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('U08: correo', () {
    expect(validarCorreoLogin(''), 'Ingrese su correo.');
    expect(validarCorreoLogin('   '), 'Ingrese su correo.');
    expect(validarCorreoLogin(null), 'Ingrese su correo.');
    expect(validarCorreoLogin('abc'), 'Ingrese un correo válido.');
    expect(validarCorreoLogin('a@b'), 'Ingrese un correo válido.');
    expect(validarCorreoLogin('${'a' * 147}@b.c'), 'Ingrese un correo válido.');
    expect(validarCorreoLogin('  Rep@Dist.test '), isNull);
  });

  test('U08: contraseña', () {
    expect(validarContrasenaLogin(''), 'Ingrese su contraseña.');
    expect(validarContrasenaLogin(null), 'Ingrese su contraseña.');
    expect(validarContrasenaLogin('x'), isNull);
  });
}
