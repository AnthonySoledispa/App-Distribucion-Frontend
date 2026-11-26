import 'package:flutter/foundation.dart';

/// Configuración de la conexión con la API.
///
/// Se puede cambiar con `--dart-define=API_URL=http://<host>:3000/api`.
/// Sin ella: web y Windows usan `localhost`; el emulador de Android ve el
/// `localhost` del PC como `10.0.2.2`.
const String _apiUrlDefinida = String.fromEnvironment('API_URL');

/// Tiempo máximo de espera por petición.
const Duration tiempoMaximo = Duration(seconds: 15);

/// Calcula la URL base (sin barra final). Separada para poder probarla.
String resolverApiUrl({
  String definida = '',
  bool esWeb = false,
  TargetPlatform plataforma = TargetPlatform.windows,
}) {
  var url = definida.trim();
  if (url.isEmpty) {
    url = (!esWeb && plataforma == TargetPlatform.android)
        ? 'http://10.0.2.2:3000/api'
        : 'http://localhost:3000/api';
  }
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  return url;
}

/// URL base de la API para la plataforma actual.
String get apiUrl => resolverApiUrl(
  definida: _apiUrlDefinida,
  esWeb: kIsWeb,
  plataforma: defaultTargetPlatform,
);
