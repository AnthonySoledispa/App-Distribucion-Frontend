import 'package:distrigo_repartidor/services/api_cliente.dart';
import 'package:distrigo_repartidor/services/auth_servicio.dart';
import 'package:distrigo_repartidor/services/sesion_controlador.dart';
import 'package:http/http.dart' as http;

import 'almacen_memoria.dart';
import 'respuestas.dart';

/// Controlador con reloj simulado, servidor simulado y almacén en memoria.
class Entorno {
  Entorno({
    Future<http.Response> Function(http.Request)? responder,
    DateTime? inicio,
    AlmacenMemoria? almacen,
  }) : ahora = inicio ?? DateTime.utc(2026, 11, 25, 12),
       almacen = almacen ?? AlmacenMemoria() {
    servidor = Servidor(responder ?? (_) async => okResp(usuarioJson()));
    final api = ApiCliente(
      cliente: servidor.cliente,
      baseUrl: 'http://x/api',
      tokenProvider: () => controlador.token,
      reloj: () => ahora,
    );
    controlador = SesionControlador(
      api: api,
      auth: AuthServicio(api, reloj: () => ahora),
      almacen: this.almacen,
      reloj: () => ahora,
      observarCicloVida: false,
    );
  }

  DateTime ahora;
  final AlmacenMemoria almacen;
  late final Servidor servidor;
  late final SesionControlador controlador;
}
