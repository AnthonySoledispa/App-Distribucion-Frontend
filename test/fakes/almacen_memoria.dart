import 'package:distrigo_repartidor/models/sesion.dart';
import 'package:distrigo_repartidor/services/almacen_sesion.dart';

/// Almacén en memoria para las pruebas.
class AlmacenMemoria implements AlmacenSesion {
  Sesion? sesion;
  int borrados = 0;

  AlmacenMemoria([this.sesion]);

  @override
  Future<Sesion?> leer() async => sesion;

  @override
  Future<void> guardar(Sesion s) async => sesion = s;

  @override
  Future<void> actualizarActividad(DateTime ultimaActividad) async {
    final s = sesion;
    if (s != null) sesion = s.copiarCon(ultimaActividad: ultimaActividad);
  }

  @override
  Future<void> borrar() async {
    sesion = null;
    borrados++;
  }
}
