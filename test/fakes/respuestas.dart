import 'dart:convert';

import 'package:distrigo_repartidor/models/sesion.dart';
import 'package:distrigo_repartidor/models/usuario.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResp(int estado, Map<String, dynamic> cuerpo) => http.Response(
  jsonEncode(cuerpo),
  estado,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

http.Response okResp(Map<String, dynamic> data) =>
    jsonResp(200, {'ok': true, 'data': data});

http.Response errResp(int estado, String codigo, [String mensaje = 'x']) =>
    jsonResp(estado, {'ok': false, 'codigo': codigo, 'mensaje': mensaje});

Map<String, dynamic> usuarioJson({String rol = 'repartidor'}) => {
  'id': 7,
  'nombre': 'Rosa Pérez',
  'correo': 'rosa@distrigo.test',
  'rol': rol,
};

http.Response loginOk({String rol = 'repartidor', int inactividad = 30}) =>
    okResp({
      'token': 'jwt-falso',
      'usuario': usuarioJson(rol: rol),
      'inactividad_minutos': inactividad,
    });

Sesion sesionGuardada({
  required DateTime ultimaActividad,
  int inactividad = 30,
}) => Sesion(
  token: 'jwt-guardado',
  usuario: Usuario.fromJson(usuarioJson()),
  inactividadMinutos: inactividad,
  ultimaActividad: ultimaActividad,
);

/// MockClient que registra las peticiones y responde según [responder].
class Servidor {
  Servidor(this.responder) {
    cliente = MockClient((peticion) async {
      peticiones.add(peticion);
      return responder(peticion);
    });
  }

  final Future<http.Response> Function(http.Request) responder;
  final List<http.Request> peticiones = [];
  late final MockClient cliente;

  Iterable<http.Request> a(String ruta) =>
      peticiones.where((p) => p.url.path.endsWith(ruta));
}
