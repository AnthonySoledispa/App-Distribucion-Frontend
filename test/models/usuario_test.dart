import 'package:distrigo_repartidor/models/usuario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('U09: fromJson, toJson y esRepartidor', () {
    final u = Usuario.fromJson({
      'id': 3,
      'nombre': 'Ana',
      'correo': 'a@b.co',
      'rol': 'repartidor',
      'estado': 'activo',
    });
    expect(u.id, 3);
    expect(u.esRepartidor, isTrue);
    expect(u.toJson(), {'id': 3, 'nombre': 'Ana', 'correo': 'a@b.co', 'rol': 'repartidor'});
    expect(Usuario.fromJson({...u.toJson(), 'rol': 'administrador'}).esRepartidor, isFalse);
    expect(u.toJson().containsKey('contrasena'), isFalse);
  });
}
