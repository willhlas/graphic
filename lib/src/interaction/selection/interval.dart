import 'dart:ui';

import 'package:graphic/src/common/dim.dart';
import 'package:graphic/src/coord/coord.dart';
import 'package:graphic/src/dataflow/tuple.dart';
import 'package:graphic/src/graffiti/figure.dart';
import 'package:graphic/src/interaction/gesture.dart';
import 'package:graphic/src/util/math.dart';

import 'selection.dart';

/// The selection to select a continuous range of data values
///
/// A rectangle mark is shown to depict the extents of the interval.
class IntervalSelection extends Selection {
  /// Creates an interval selection.
  IntervalSelection({
    this.color,
    Dim? dim,
    String? variable,
    Set<GestureType>? clear,
    Set<PointerDeviceKind>? devices,
    int? layer,
  }) : super(
          dim: dim,
          variable: variable,
          clear: clear,
          devices: devices,
          layer: layer,
        );

  /// The color of the interval mark.
  ///
  /// If null, a default `Color(0x10101010)` is set.
  Color? color;

  @override
  bool operator ==(Object other) =>
      other is IntervalSelection && super == other && color == other.color;
}

/// The interval selector.
///
/// The [points] are `[start, end]`.
class IntervalSelector extends Selector {
  IntervalSelector(
    this.color,
    Dim? dim,
    String? variable,
    List<Offset> points,
  ) : super(
          dim,
          variable,
          points,
        );

  /// The color of the interval mark.
  final Color color;

  @override
  Set<int>? select(
    AesGroups groups,
    List<Tuple> tuples,
    Set<int>? preSelects,
    CoordConv coord,
  ) {
    final start = coord.invert(points.first);
    final end = coord.invert(points.last);

    bool Function(Aes) test;
    if (dim == null) {
      final testRegion = Rect.fromPoints(start, end);
      test = (aes) {
        final p = aes.representPoint;
        return testRegion.contains(p);
      };
    } else {
      if (dim == Dim.x) {
        test = (aes) {
          final p = aes.representPoint;
          return p.dx.between(start.dx, end.dx);
        };
      } else {
        test = (aes) {
          final p = aes.representPoint;
          return p.dx.between(start.dy, end.dy);
        };
      }
    }

    final rst = <int>{};
    for (var group in groups) {
      for (var aes in group) {
        if (test(aes)) {
          rst.add(aes.index);
        }
      }
    }

    if (rst.isEmpty) {
      return null;
    }

    if (variable != null) {
      final values = Set();
      for (var index in rst) {
        values.add(tuples[index][variable]);
      }
      for (var i = 0; i < tuples.length; i++) {
        if (values.contains(tuples[i][variable])) {
          rst.add(i);
        }
      }
    }

    return rst.isEmpty ? null : rst;
  }
}

/// Renders interval selector.
List<Figure>? renderIntervalSelector(
  Offset start,
  Offset end,
  Color color,
) =>
    [
      PathFigure(
        Path()..addRect(Rect.fromPoints(start, end)),
        Paint()..color = color,
      )
    ];
