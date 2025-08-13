import 'package:flutter/material.dart';

/// Dinamik Adam Asmaca figürü.
/// wrongCount: yapılan yanlış sayısı
/// maxSteps  : toplam yanlış hakkı (başlangıçtaki hak) — zorunlu!
class HangmanFigure extends StatelessWidget {
  const HangmanFigure({
    super.key,
    required this.wrongCount,
    required this.maxSteps,
    this.width = 240,
    this.height = 200,
    this.baseColor,
    this.highlightColor,
  });

  final int wrongCount;
  final int maxSteps;
  final double width;
  final double height;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _HangmanPainter(
          wrongCount: wrongCount,
          maxSteps: maxSteps,
          baseColor: baseColor ?? const Color(0xFF3E3A39).withOpacity(0.6),
          hiColor: highlightColor ?? Colors.redAccent,
        ),
      ),
    );
  }
}

class _HangmanPainter extends CustomPainter {
  _HangmanPainter({
    required this.wrongCount,
    required this.maxSteps,
    required this.baseColor,
    required this.hiColor,
  });

  final int wrongCount;
  final int maxSteps;
  final Color baseColor;
  final Color hiColor;

  // Toplam parça birimi (zemin+direk+kiriş+ip+kafa+gövde+2 kol+2 bacak = 10)
  static const int totalUnits = 10;

  @override
  void paint(Canvas canvas, Size size) {
    // 0..10 aralığında kırmızı ilerleme
    final double progressUnits = (maxSteps <= 0)
        ? 0
        : (wrongCount.clamp(0, maxSteps) / maxSteps) * totalUnits;

    Paint _p(Color c, [double w = 4]) => Paint()
      ..color = c
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void _line(Offset a, Offset b, Color c, [double w = 4]) =>
        canvas.drawLine(a, b, _p(c, w));

    // Bir çizgi parçasını kısmi boyamak:
    // frac=1 => tamamen kırmızı, 0<frac<1 => kısmi kırmızı + geri kalanı baz
    void _progressLine(Offset a, Offset b, double frac, [double w = 4]) {
      frac = frac.clamp(0.0, 1.0);
      if (frac <= 0) {
        _line(a, b, baseColor, w);
        return;
      }
      if (frac >= 1) {
        _line(a, b, hiColor, w);
        return;
      }
      final dx = b.dx - a.dx;
      final dy = b.dy - a.dy;
      final mid = Offset(a.dx + dx * frac, a.dy + dy * frac);
      // kırmızı kısım (başlangıçtan ortaya)
      _line(a, mid, hiColor, w);
      // kalan kısım baz renkte
      _line(mid, b, baseColor, w);
    }

    // Daireyi kısmi boyamak (arc):
    void _progressCircle(Offset c, double r, double frac, [double w = 4]) {
      frac = frac.clamp(0.0, 1.0);
      final rect = Rect.fromCircle(center: c, radius: r);
      const start = -3.14159; // -π (soldan başlasın)
      final sweepRed = 3.14159 * 2 * frac; // kırmızı yay
      final sweepBase = 3.14159 * 2 - sweepRed;

      if (frac <= 0) {
        canvas.drawArc(rect, start, 3.14159 * 2, false, _p(baseColor, w));
        return;
      }
      if (frac >= 1) {
        canvas.drawArc(rect, start, 3.14159 * 2, false, _p(hiColor, w));
        return;
      }
      // kırmızı yay
      canvas.drawArc(rect, start, sweepRed, false, _p(hiColor, w));
      // kalan baz yay
      canvas.drawArc(
          rect, start + sweepRed, sweepBase, false, _p(baseColor, w));
    }

    // Oranlar ve noktalar
    final w = size.width;
    final h = size.height;

    final baseY = h * 0.90;
    final postX = w * 0.18;
    final topY = h * 0.10;
    final beamEnd = w * 0.62;
    final ropeX = w * 0.50;
    final headCY = h * 0.33;
    final headR = h * 0.07;

    final bodyTop = headCY + headR;
    final bodyBot = h * 0.62;
    final armY = h * 0.42;

    // 10 birimlik parçalar sırası (her biri 1 birim):
    // 0 zemin, 1 direk, 2 kiriş, 3 ip, 4 kafa, 5 gövde, 6 sol kol, 7 sağ kol, 8 sol bacak, 9 sağ bacak
    // Her parça için ne kadar kırmızı gerektiğini hesapla:
    double remain = progressUnits;

    double take() {
      final t = remain.clamp(0.0, 1.0);
      remain = (remain - 1.0).clamp(0.0, totalUnits.toDouble());
      return t.toDouble(); // 0..1
    }

    // 0) Zemin
    _progressLine(
      Offset(postX - w * 0.10, baseY),
      Offset(postX + w * 0.25, baseY),
      take(),
      5,
    );

    // 1) Dik direk
    _progressLine(
      Offset(postX, baseY),
      Offset(postX, topY),
      take(),
    );

    // 2) Üst kiriş
    _progressLine(
      Offset(postX, topY),
      Offset(beamEnd, topY),
      take(),
    );

    // 3) İp
    _progressLine(
      Offset(ropeX, topY),
      Offset(ropeX, headCY - headR - 4),
      take(),
    );

    // 4) Kafa (arc ile kısmi)
    _progressCircle(Offset(ropeX, headCY), headR, take());

    // 5) Gövde
    _progressLine(
      Offset(ropeX, bodyTop),
      Offset(ropeX, bodyBot),
      take(),
    );

    // 6) Sol kol
    _progressLine(
      Offset(ropeX, armY),
      Offset(ropeX - w * 0.12, armY + h * 0.08),
      take(),
    );

    // 7) Sağ kol
    _progressLine(
      Offset(ropeX, armY),
      Offset(ropeX + w * 0.12, armY + h * 0.08),
      take(),
    );

    // 8) Sol bacak
    _progressLine(
      Offset(ropeX, bodyBot),
      Offset(ropeX - w * 0.12, bodyBot + h * 0.12),
      take(),
    );

    // 9) Sağ bacak
    _progressLine(
      Offset(ropeX, bodyBot),
      Offset(ropeX + w * 0.12, bodyBot + h * 0.12),
      take(),
    );
  }

  @override
  bool shouldRepaint(covariant _HangmanPainter old) =>
      old.wrongCount != wrongCount ||
      old.maxSteps != maxSteps ||
      old.baseColor != baseColor ||
      old.hiColor != hiColor;
}
