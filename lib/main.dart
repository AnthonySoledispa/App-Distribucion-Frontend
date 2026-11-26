import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/config_api.dart';
import 'services/almacen_sesion.dart';
import 'services/api_cliente.dart';
import 'services/auth_servicio.dart';
import 'services/sesion_controlador.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late final SesionControlador sesion;
  final api = ApiCliente(
    cliente: http.Client(),
    baseUrl: apiUrl,
    tokenProvider: () => sesion.token,
    tiempoMaximo: tiempoMaximo,
  );
  sesion = SesionControlador(
    api: api,
    auth: AuthServicio(api),
    almacen: AlmacenSesionSeguro(),
  )..iniciar();

  runApp(
    ChangeNotifierProvider<SesionControlador>.value(
      value: sesion,
      child: const DistriGoApp(),
    ),
  );
}
