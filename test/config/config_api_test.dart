import 'package:distrigo_repartidor/config/config_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('U18: valor por defecto según plataforma', () {
    expect(resolverApiUrl(esWeb: true), 'http://localhost:3000/api');
    expect(
      resolverApiUrl(plataforma: TargetPlatform.windows),
      'http://localhost:3000/api',
    );
    expect(
      resolverApiUrl(plataforma: TargetPlatform.android),
      'http://10.0.2.2:3000/api',
    );
    // En web nunca se usa 10.0.2.2 aunque la plataforma sea Android.
    expect(
      resolverApiUrl(esWeb: true, plataforma: TargetPlatform.android),
      'http://localhost:3000/api',
    );
  });

  test('U18: dart-define con barra final se normaliza', () {
    expect(
      resolverApiUrl(definida: 'http://192.168.1.5:3000/api//'),
      'http://192.168.1.5:3000/api',
    );
  });

  test('tiempo máximo de 15 s', () {
    expect(tiempoMaximo, const Duration(seconds: 15));
  });
}
