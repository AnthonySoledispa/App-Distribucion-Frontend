import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Colores de la aplicación (AGENTES.md).
class ColoresDistriGO {
  ColoresDistriGO._();

  static const principal = Color(0xFF0A0B78);
  static const secundario = Color(0xFF2196F3);
  static const exito = Color(0xFF4CAF50);
  static const alerta = Color(0xFFFF9800);
  static const error = Color(0xFF730505);
  static const fondo = Color(0xFFF5F7FA);
  static const texto = Color(0xFF333333);
}

/// Estilos de texto. Títulos: Archivo condensada. Texto: Public Sans.
class EstilosTexto {
  EstilosTexto._();

  static const _titulo = TextStyle(
    fontFamily: 'Archivo',
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wdth', 75), FontVariation('wght', 700)],
    color: ColoresDistriGO.texto,
  );

  static TextStyle titulo({
    double tamano = 24,
    Color color = ColoresDistriGO.texto,
  }) => _titulo.copyWith(fontSize: tamano, color: color, height: 1.15);

  static TextStyle cuerpo({
    double tamano = 16,
    bool negrita = false,
    Color color = ColoresDistriGO.texto,
  }) => TextStyle(
    fontFamily: 'PublicSans',
    fontSize: tamano,
    fontWeight: negrita ? FontWeight.w600 : FontWeight.w400,
    fontVariations: [FontVariation('wght', negrita ? 600 : 400)],
    color: color,
    height: 1.4,
  );
}

ThemeData construirTema() {
  final esquema = ColorScheme.fromSeed(
    seedColor: ColoresDistriGO.principal,
    primary: ColoresDistriGO.principal,
    secondary: ColoresDistriGO.secundario,
    error: ColoresDistriGO.error,
    surface: Colors.white,
  );
  final borde = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: ColoresDistriGO.texto.withValues(alpha: 0.3)),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: ColoresDistriGO.fondo,
    fontFamily: 'PublicSans',
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'PublicSans',
      bodyColor: ColoresDistriGO.texto,
      displayColor: ColoresDistriGO.texto,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ColoresDistriGO.principal,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: EstilosTexto.titulo(tamano: 22, color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: borde,
      enabledBorder: borde,
      focusedBorder: borde.copyWith(
        borderSide: const BorderSide(
          color: ColoresDistriGO.principal,
          width: 2,
        ),
      ),
      errorBorder: borde.copyWith(
        borderSide: const BorderSide(color: ColoresDistriGO.error),
      ),
      focusedErrorBorder: borde.copyWith(
        borderSide: const BorderSide(color: ColoresDistriGO.error, width: 2),
      ),
      errorStyle: const TextStyle(color: ColoresDistriGO.error, fontSize: 13),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ColoresDistriGO.principal,
        foregroundColor: Colors.white,
        disabledBackgroundColor: ColoresDistriGO.principal.withValues(
          alpha: 0.6,
        ),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: EstilosTexto.cuerpo(negrita: true),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColoresDistriGO.principal,
        minimumSize: const Size(48, 48),
        textStyle: EstilosTexto.cuerpo(negrita: true),
      ),
    ),
  );
}
