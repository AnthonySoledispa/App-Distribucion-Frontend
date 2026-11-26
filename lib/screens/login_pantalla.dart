import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../models/api_error.dart';
import '../services/mensajes.dart';
import '../services/sesion_controlador.dart';
import '../services/validaciones.dart';
import '../widgets/boton_principal.dart';
import '../widgets/cabecera_marca.dart';
import '../widgets/campo_contrasena.dart';
import '../widgets/mensaje_alerta.dart';

class LoginPantalla extends StatefulWidget {
  const LoginPantalla({super.key});

  @override
  State<LoginPantalla> createState() => _LoginPantallaState();
}

class _LoginPantallaState extends State<LoginPantalla> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    if (!(_formulario.currentState?.validate() ?? false)) return;
    final sesion = context.read<SesionControlador>();
    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _error = null;
    });
    sesion.limpiarFlash();
    try {
      await sesion.iniciarSesion(_correo.text, _contrasena.text);
      // Al autenticar, PuertaSesion reemplaza esta pantalla.
    } on ApiError catch (e) {
      _mostrarError(Mensajes.deError(e));
    } catch (_) {
      _mostrarError(Mensajes.inesperado);
    }
  }

  void _mostrarError(String texto) {
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _error = texto;
      _contrasena.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final flash = context.select<SesionControlador, String?>((s) => s.flash);
    final alto = MediaQuery.sizeOf(context).height;
    final altoCabecera = (alto * 0.38).clamp(300.0, 380.0);

    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            CabeceraMarca(alto: altoCabecera),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      _tarjeta(flash),
                      const SizedBox(height: 20),
                      Text(
                        '¿Problemas para entrar? Contacte a su administrador.',
                        textAlign: TextAlign.center,
                        style: EstilosTexto.cuerpo(
                          tamano: 13,
                          color: ColoresDistriGO.texto.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjeta(String? flash) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formulario,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Iniciar sesión', style: EstilosTexto.titulo(tamano: 26)),
              const SizedBox(height: 4),
              Text(
                'Ingrese con su cuenta de repartidor.',
                style: EstilosTexto.cuerpo(
                  tamano: 14,
                  color: ColoresDistriGO.texto.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              if (flash != null) ...[
                MensajeAlerta.info(flash),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _correo,
                enabled: !_enviando,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                validator: validarCorreoLogin,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 14),
              CampoContrasena(
                controlador: _contrasena,
                habilitado: !_enviando,
                validador: validarContrasenaLogin,
                alEnviar: _enviar,
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                MensajeAlerta.error(_error!),
                const SizedBox(height: 14),
              ],
              BotonPrincipal(
                texto: 'Ingresar',
                textoCargando: 'Ingresando…',
                cargando: _enviando,
                alPresionar: _enviar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
