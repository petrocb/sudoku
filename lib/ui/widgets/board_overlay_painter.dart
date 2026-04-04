import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/puzzle_config.dart';
import '../../models/grid_geometry.dart';
import '../../models/constraints/diagonal_constraint.dart';
import '../../models/constraints/hyper_window_constraint.dart';
import '../../models/constraints/killer_cage_constraint.dart';
import '../../models/constraints/thermo_constraint.dart';

// ── Background painter ────────────────────────────────────────────────────────

/// Draws behind cell widgets: thermo paths, diagonal tints, hyper window tints.
class BoardBackgroundPainter extends CustomPainter {
  final PuzzleConfig config;
  final ColorScheme scheme;

  const BoardBackgroundPainter({required this.config, required this.scheme});

  @override
  void paint(Canvas canvas, Size size) {
    final geo = config.geometry;
    final cellW = size.width / geo.size;
    final cellH = size.height / geo.size;

    if (config.hasConstraint<DiagonalConstraint>()) {
      _drawDiagonalTints(canvas, geo, cellW, cellH);
    }
    if (config.hasConstraint<HyperWindowConstraint>()) {
      _drawHyperTints(canvas, geo, cellW, cellH);
    }
    final thermo = config.constraint<ThermoConstraint>();
    if (thermo != null) {
      _drawThermos(canvas, geo, cellW, cellH, thermo);
    }
  }

  void _drawDiagonalTints(
      Canvas canvas, GridGeometry geo, double cellW, double cellH) {
    final paint = Paint()
      ..color = scheme.primaryContainer.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < geo.size; i++) {
      canvas.drawRect(
          Rect.fromLTWH(i * cellW, i * cellH, cellW, cellH), paint);
      final j = geo.size - 1 - i;
      if (j != i) {
        canvas.drawRect(
            Rect.fromLTWH(j * cellW, i * cellH, cellW, cellH), paint);
      }
    }
  }

  void _drawHyperTints(
      Canvas canvas, GridGeometry geo, double cellW, double cellH) {
    final w = geo.boxRows; // window size
    final starts = [
      (1, 1),
      (1, geo.size - w - 1),
      (geo.size - w - 1, 1),
      (geo.size - w - 1, geo.size - w - 1),
    ];
    final paint = Paint()
      ..color = scheme.tertiaryContainer.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    for (final s in starts) {
      for (int r = s.$1; r < s.$1 + w; r++) {
        for (int c = s.$2; c < s.$2 + w; c++) {
          canvas.drawRect(
              Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH), paint);
        }
      }
    }
  }

  void _drawThermos(Canvas canvas, GridGeometry geo, double cellW, double cellH,
      ThermoConstraint thermo) {
    final linePaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = cellW * 0.44
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bulbPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    for (final path in thermo.thermos) {
      if (path.length < 2) continue;

      final linePath = Path();
      for (int i = 0; i < path.length; i++) {
        final idx = path[i];
        final cx = (geo.colOf(idx) + 0.5) * cellW;
        final cy = (geo.rowOf(idx) + 0.5) * cellH;
        if (i == 0) {
          linePath.moveTo(cx, cy);
        } else {
          linePath.lineTo(cx, cy);
        }
      }
      canvas.drawPath(linePath, linePaint);

      // Bulb: filled circle at start
      final bulbIdx = path.first;
      final bx = (geo.colOf(bulbIdx) + 0.5) * cellW;
      final by = (geo.rowOf(bulbIdx) + 0.5) * cellH;
      canvas.drawCircle(Offset(bx, by), cellW * 0.38, bulbPaint);
    }
  }

  @override
  bool shouldRepaint(BoardBackgroundPainter old) =>
      old.config != config || old.scheme != scheme;
}

// ── Foreground painter ────────────────────────────────────────────────────────

/// Draws on top of cell widgets: killer cage dashed outlines + sum labels.
class BoardForegroundPainter extends CustomPainter {
  final PuzzleConfig config;
  final ColorScheme scheme;

  static const double _inset = 2.5;   // gap between cell border and cage line
  static const double _dash  = 4.0;
  static const double _gap   = 3.0;

  const BoardForegroundPainter({required this.config, required this.scheme});

  @override
  void paint(Canvas canvas, Size size) {
    final killer = config.constraint<KillerCageConstraint>();
    if (killer == null) return;

    final geo = config.geometry;
    final cellW = size.width / geo.size;
    final cellH = size.height / geo.size;
    _drawKillerCages(canvas, geo, cellW, cellH, killer);
  }

  void _drawKillerCages(Canvas canvas, GridGeometry geo, double cellW,
      double cellH, KillerCageConstraint killer) {
    // Build cellIndex → cageId lookup
    final cageOf = <int, int>{};
    for (int c = 0; c < killer.cages.length; c++) {
      for (final cell in killer.cages[c].cells) {
        cageOf[cell] = c;
      }
    }

    final paint = Paint()
      ..color = scheme.onSurface.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (int c = 0; c < killer.cages.length; c++) {
      final cage = killer.cages[c];

      // Draw cage boundary edges
      for (final idx in cage.cells) {
        final row = geo.rowOf(idx);
        final col = geo.colOf(idx);
        final x = col * cellW;
        final y = row * cellH;

        // Top edge
        if (row == 0 || cageOf[geo.indexOf(row - 1, col)] != c) {
          _dashedLine(canvas, paint,
              Offset(x + _inset, y + _inset),
              Offset(x + cellW - _inset, y + _inset));
        }
        // Bottom edge
        if (row == geo.size - 1 || cageOf[geo.indexOf(row + 1, col)] != c) {
          _dashedLine(canvas, paint,
              Offset(x + _inset, y + cellH - _inset),
              Offset(x + cellW - _inset, y + cellH - _inset));
        }
        // Left edge
        if (col == 0 || cageOf[geo.indexOf(row, col - 1)] != c) {
          _dashedLine(canvas, paint,
              Offset(x + _inset, y + _inset),
              Offset(x + _inset, y + cellH - _inset));
        }
        // Right edge
        if (col == geo.size - 1 || cageOf[geo.indexOf(row, col + 1)] != c) {
          _dashedLine(canvas, paint,
              Offset(x + cellW - _inset, y + _inset),
              Offset(x + cellW - _inset, y + cellH - _inset));
        }
      }

      // Draw sum label in the top-left cell of this cage
      int topLeft = cage.cells.first;
      for (final cell in cage.cells) {
        final r = geo.rowOf(cell), tr = geo.rowOf(topLeft);
        final co = geo.colOf(cell), tc = geo.colOf(topLeft);
        if (r < tr || (r == tr && co < tc)) topLeft = cell;
      }

      final lx = geo.colOf(topLeft) * cellW + _inset + 1;
      final ly = geo.rowOf(topLeft) * cellH + _inset;
      final fontSize = (cellW * 0.22).clamp(7.0, 12.0);
      final tp = TextPainter(
        text: TextSpan(
          text: '${cage.targetSum}',
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.65),
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx, ly));
    }
  }

  void _dashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final nx = dx / len;
    final ny = dy / len;

    double dist = 0;
    bool drawing = true;
    while (dist < len) {
      final segLen = drawing ? _dash : _gap;
      final next = min(dist + segLen, len);
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + nx * dist, start.dy + ny * dist),
          Offset(start.dx + nx * next, start.dy + ny * next),
          paint,
        );
      }
      dist = next;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(BoardForegroundPainter old) =>
      old.config != config || old.scheme != scheme;
}
