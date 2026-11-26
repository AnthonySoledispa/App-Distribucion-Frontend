import 'package:material_ui/material_ui.dart';

import '../config/tema.dart';

/// Dibujo decorativo: bodega -> 3 tiendas con línea discontinua.
class MiniRuta extends StatelessWidget {
  const MiniRuta({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: CustomPaint(painter: _PintorMiniRuta()),
      ),
    );
  }
}

class _PintorMiniRuta extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final margen = 28.0;
    final xs = [
      for (var i = 0; i < 4; i++) margen + (size.width - 2 * margen) * i / 3,
    ];
    final linea = Paint()
      ..color = ColoresDistriGO.secundario
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Línea discontinua entre nodos con una ligera ondulación.
    final trazo = Path()..moveTo(xs.first, y);
    for (var i = 1; i < xs.length; i++) {
      final medio = (xs[i - 1] + xs[i]) / 2;
      final desvio = i.isOdd ? -14.0 : 14.0;
      trazo.quadraticBezierTo(medio, y + desvio, xs[i], y);
    }
    for (final metrica in trazo.computeMetrics()) {
      var d = 0.0;
      while (d < metrica.length) {
        canvas.drawPath(metrica.extractPath(d, d + 7), linea);
        d += 13;
      }
    }

    final blanco = Paint()..color = Colors.white;
    final anillo = Paint()
      ..color = ColoresDistriGO.secundario
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Bodega: cuadrado redondeado más grande.
    final bodega = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(xs.first, y), width: 22, height: 22),
      const Radius.circular(5),
    );
    canvas.drawRRect(bodega, blanco);
    canvas.drawRRect(bodega, anillo);

    // Tiendas: círculos.
    for (var i = 1; i < xs.length; i++) {
      canvas.drawCircle(Offset(xs[i], y), 8, blanco);
      canvas.drawCircle(Offset(xs[i], y), 8, anillo);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
