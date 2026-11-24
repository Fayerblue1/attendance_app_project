import 'package:flutter/material.dart';

class QrCodeWidget extends StatelessWidget {
  final double size;
  final String data;
  final Color color;

  const QrCodeWidget({
    super.key,
    this.size = 100,
    required this.data,
    this.color = const Color(0xFF0F172A),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _QrCodePainter(color: color, data: data),
    );
  }
}

class _QrCodePainter extends CustomPainter {
  final Color color;
  final String data;

  _QrCodePainter({required this.color, required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const int modules = 21; // Standard Version 1 QR code 21x21
    final double moduleSize = size.width / modules;

    // Deterministic pseudo-random bits based on input data
    int hash = data.hashCode.abs();
    final List<List<bool>> grid = List.generate(
      modules,
      (y) => List.generate(
        modules,
        (x) {
          hash = (hash * 1103515245 + 12345) & 0x7FFFFFFF;
          return (hash % 100) < 45;
        },
      ),
    );

    // Function to draw QR Position Detection Pattern (7x7 box)
    void drawPositionPattern(int startX, int startY) {
      for (int r = 0; r < 7; r++) {
        for (int c = 0; c < 7; c++) {
          if (r == 0 || r == 6 || c == 0 || c == 6) {
            grid[startY + r][startX + c] = true;
          } else if (r >= 2 && r <= 4 && c >= 2 && c <= 4) {
            grid[startY + r][startX + c] = true;
          } else {
            grid[startY + r][startX + c] = false;
          }
        }
      }
      // Separator (clear surroundings)
      for (int i = 0; i < 8; i++) {
        if (startX + 7 < modules && startY + i < modules) {
          grid[startY + i][startX + 7] = false;
        }
        if (startY + 7 < modules && startX + i < modules) {
          grid[startY + 7][startX + i] = false;
        }
      }
    }

    // Top-Left Pattern
    drawPositionPattern(0, 0);
    // Top-Right Pattern
    drawPositionPattern(modules - 7, 0);
    // Bottom-Left Pattern
    drawPositionPattern(0, modules - 7);

    // Timing Patterns (Row 6 and Column 6)
    for (int i = 8; i < modules - 8; i++) {
      grid[6][i] = (i % 2 == 0);
      grid[i][6] = (i % 2 == 0);
    }

    // Alignment / Dark module
    grid[modules - 8][8] = true;

    // Draw all modules
    for (int y = 0; y < modules; y++) {
      for (int x = 0; x < modules; x++) {
        if (grid[y][x]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                x * moduleSize,
                y * moduleSize,
                moduleSize * 0.95,
                moduleSize * 0.95,
              ),
              Radius.circular(moduleSize * 0.2),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCodePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}

