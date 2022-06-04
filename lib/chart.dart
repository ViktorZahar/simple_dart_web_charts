import 'dart:html';
import 'dart:math';

import '../axis.dart';
import '../utils.dart';

class LineRow {
  LineRow(this.date, this.value);

  late DateTime date;
  late double value;
}

class CandleRow {
  CandleRow(this.date, this.open, this.high, this.low, this.close);

  late DateTime date;
  late double open;
  late double high;
  late double low;
  late double close;
}

class ChartPoint {
  ChartPoint(this.x, this.y, this.dataRow);

  late double x;
  late double y;
  late LineRow dataRow;
}

class CandlePoint {
  CandlePoint(this.x0, this.y0, this.x1, this.y1, this.candleRow);

  late double x0;
  late double x1;
  late double y0;
  late double y1;
  late CandleRow candleRow;
}

class ChartStyle {
  String backgroundColor = '#ffffff';
  String font = 'Arial';
  String fontColor = '#000000';
  String lineColor = '#000000';
  int xLabelIndent = 5;
  int yLabelIndent = 8;
  int rightMargin = 50;
  int bottomMargin = 20;
  int leftMargin = 15;
  int topMargin = 10;
  int dashLength = 3;
}

class Chart {
  Chart(this.container) {
    axis = Axis(this);
  }

  // This method calls after adding Chart on DOM
  void init() {
    if (chartCanvas == null) {
      createCanvases();
      container.children.add(chartCanvas!);
      container.children.add(mouseCanvas!);
    }
  }

  ChartStyle style = ChartStyle();
  late Element container;
  late Axis axis;
  CanvasElement? chartCanvas;
  CanvasElement? mouseCanvas;

  CanvasRenderingContext2D? ctx;
  CanvasRenderingContext2D? mouseCtx;

  List<LineRow> data = <LineRow>[];
  List<CandleRow> candleData = <CandleRow>[];
  List<ChartPoint> points = <ChartPoint>[];
  List<CandlePoint> candlePoints = <CandlePoint>[];
  int width = 0;
  int height = 0;

  void createCanvases() {
    chartCanvas = CanvasElement(
        width: container.clientWidth, height: container.clientHeight);
    mouseCanvas = CanvasElement(
        width: container.clientWidth, height: container.clientHeight);
    final unkCtx = chartCanvas!.getContext('2d');
    if (unkCtx is CanvasRenderingContext2D) {
      ctx = unkCtx;
    } else {
      throw Exception('Could not get CanvasRenderingContext2D');
    }
    final unkMouseCtx = mouseCanvas!.getContext('2d');
    if (unkMouseCtx is CanvasRenderingContext2D) {
      mouseCtx = unkMouseCtx;
    } else {
      throw Exception('Could not get CanvasRenderingContext2D');
    }
    container.style.position = 'relative';
    width = chartCanvas!.width!;
    height = chartCanvas!.height!;
    if (chartCanvas != null) {
      chartCanvas!.style
        ..position = 'absolute'
        ..top = '0'
        ..left = '0'
        ..bottom = '0'
        ..right = '0';
    }
    if (mouseCanvas != null) {
      mouseCanvas!.style
        ..position = 'absolute'
        ..top = '0'
        ..left = '0'
        ..bottom = '0'
        ..right = '0'
        ..zIndex = '9';
    }
  }

  void renderLineChart(List<LineRow> newData) {
    if (chartCanvas == null) {
      init();
    }
    var usableData = newData;
    final usableWidth = width - axis.style.leftMargin - axis.style.rightMargin;
    if ((newData.length * 2) > usableWidth) {
      final usableCount = usableWidth ~/ 2;
      usableData = newData.sublist(newData.length - usableCount);
    }
    data = usableData;
    ctx!.font = style.font;
    axis.render(ctx!);
    renderLine(ctx!);
    initMouseEvents(mouseCtx!);
  }

  void renderCandleChart(List<CandleRow> newCandleData) {
    if (chartCanvas == null) {
      init();
    }
    var usableData = newCandleData;
    final usableWidth = width - axis.style.leftMargin - axis.style.rightMargin;
    if ((newCandleData.length * 3 + 1) > usableWidth) {
      final usableCount = usableWidth ~/ 3 - 1;
      usableData = newCandleData.sublist(newCandleData.length - usableCount);
    }
    candleData = usableData;
    ctx!.font = style.font;
    axis.render(ctx!);
    renderCandles(ctx!);
    initMouseEvents(mouseCtx!);
  }

  void renderLine(CanvasRenderingContext2D ctx) {
    points.clear();
    ctx
      ..beginPath()
      ..strokeStyle = '#3366cc';
    var x = axis.style.leftMargin.toDouble();
    var y = height -
        axis.style.bottomMargin -
        (data.first.value - axis.yFrom) / axis.yScaleValue;
    points.add(ChartPoint(x, y, data.first));
    ctx.moveTo(x, y);
    for (var i = 1; i < data.length; i++) {
      final dataRow = data[i];
      x = axis.style.leftMargin + axis.xStepPix * i;
      y = height -
          axis.style.bottomMargin -
          (dataRow.value - axis.yFrom) / axis.yScaleValue;

      ctx.lineTo(x, y);
      points.add(ChartPoint(x, y, dataRow));
    }
    ctx.stroke();
  }

  void rerender() {
    clear();
    if (data.isNotEmpty) {
      renderLineChart(data);
    }
    if (candleData.isNotEmpty) {
      renderCandleChart(candleData);
    }
  }

  void renderCandles(CanvasRenderingContext2D ctx) {
    candlePoints.clear();
    for (var i = 0; i < candleData.length; i++) {
      final candleRow = candleData[i];
      final x = axis.style.leftMargin + axis.xStepPix * i;
      final x0 = x - axis.xStepPix / 2;
      final x1 = x + axis.xStepPix / 2;
      final y0 = height -
          axis.style.bottomMargin -
          (candleRow.open - axis.yFrom) / axis.yScaleValue;
      final y1 = height -
          axis.style.bottomMargin -
          (candleRow.close - axis.yFrom) / axis.yScaleValue;
      ctx
        ..beginPath()
        ..lineWidth = 1;
      if (candleRow.open > candleRow.close) {
        ctx
          ..fillStyle = '#dc3912'
          ..strokeStyle = '#dc3912'
          ..fillRect(x0, y1, x1 - x0, y0 - y1);
      } else {
        ctx
          ..fillStyle = '#33bb33'
          ..strokeStyle = '#33bb33'
          ..fillRect(x0, y0, x1 - x0, y1 - y0);
      }
      final midX = x + 0.5;
      var z0 = min(y0, y1);
      var z1 = max(y0, y1);
      if (candleRow.low < candleRow.open && candleRow.low < candleRow.close) {
        z0 = height -
            axis.style.bottomMargin -
            (candleRow.low - axis.yFrom) / axis.yScaleValue;
      }
      if (candleRow.high > candleRow.open && candleRow.high > candleRow.close) {
        z1 = height -
            axis.style.bottomMargin -
            (candleRow.high - axis.yFrom) / axis.yScaleValue;
      }
      ctx
        ..moveTo(midX, z0)
        ..lineTo(midX, z1)
        ..stroke();
      candlePoints.add(CandlePoint(x0, y0, x1, y1, candleRow));
    }
  }

  void initMouseEvents(CanvasRenderingContext2D ctx) {
    mouseCanvas!.onMouseOut.listen((e) {
      ctx.clearRect(0, 0, width, height);
    });
    mouseCanvas!.onMouseMove.listen((e) {
      ctx.clearRect(0, 0, width, height);
      final x = e.offset.x.toInt();
      final y = e.offset.y.toInt();
      ChartPoint? nearestPoint;
      var minDist = 0.0;
      if (points.isNotEmpty) {
        for (final point in points) {
          final dist = (point.x - x).abs() + (point.y - y).abs();
          if (nearestPoint == null || dist < minDist) {
            nearestPoint = point;
            minDist = dist;
          }
        }
      }
      CandlePoint? nearestCandlePoint;
      if (candlePoints.isNotEmpty) {
        for (final candlePoint in candlePoints) {
          final dist = (candlePoint.x0 - x).abs();
          if (nearestCandlePoint == null || dist < minDist) {
            nearestCandlePoint = candlePoint;
            minDist = dist;
          }
        }
      }
      if (nearestPoint != null) {
        ctx
          ..setLineDash([3, 3])
          ..strokeStyle = style.fontColor
          ..beginPath()
          ..moveTo(x, 0)
          ..lineTo(x, height)
          ..stroke()
          ..beginPath()
          ..moveTo(0, y)
          ..lineTo(width, y)
          ..stroke()
          ..setLineDash([])
          ..beginPath()
          ..arc(nearestPoint.x, nearestPoint.y, 3, 0, 2 * pi)
          ..stroke()
          ..fillStyle = style.fontColor;
        var label1 = 'date: ';
        if (axis.timeStep.endsWith('d')) {
          label1 += formatDateHum(nearestPoint.dataRow.date);
        } else {
          label1 += formatDateTimeHum(nearestPoint.dataRow.date);
        }
        final label2 = 'value: ${nearestPoint.dataRow.value}';
        if (nearestPoint.x > width / 2) {
          ctx
            ..textAlign = 'right'
            ..fillText(label1, nearestPoint.x - 3, 9)
            ..fillText(label2, nearestPoint.x - 3, 19);
        } else {
          ctx
            ..textAlign = 'left'
            ..fillText(label1, nearestPoint.x + 3, 9)
            ..fillText(label2, nearestPoint.x + 3, 19);
        }
      }
      if (nearestCandlePoint != null) {
        final x = (nearestCandlePoint.x0 + nearestCandlePoint.x1) / 2;
        ctx
          ..setLineDash([3, 3])
          ..strokeStyle = style.fontColor
          ..beginPath()
          ..moveTo(x, 0)
          ..lineTo(x, height)
          ..stroke()
          ..beginPath()
          ..moveTo(0, y)
          ..lineTo(width, y)
          ..stroke()
          ..setLineDash([])
          ..beginPath()
          ..stroke()
          ..fillStyle = style.fontColor;
        final candleRow = nearestCandlePoint.candleRow;
        var label1 = 'date: ';
        if (axis.timeStep.endsWith('d')) {
          label1 += formatDateHum(candleRow.date);
        } else {
          label1 += formatDateTimeHum(candleRow.date);
        }
        final labelO = 'o: ${candleRow.open}';
        final labelH = 'h: ${candleRow.high}';
        final labelL = 'l: ${candleRow.low}';
        final labelC = 'c: ${candleRow.close}';

        if (x > width / 2) {
          ctx
            ..textAlign = 'right'
            ..fillText(label1, x - 3, 9)
            ..fillText(labelO, x - 3, 19)
            ..fillText(labelH, x - 3, 29)
            ..fillText(labelL, x - 3, 39)
            ..fillText(labelC, x - 3, 49);
        } else {
          ctx
            ..textAlign = 'left'
            ..fillText(label1, x + 3, 9)
            ..fillText(labelO, x + 3, 19)
            ..fillText(labelH, x + 3, 29)
            ..fillText(labelL, x + 3, 39)
            ..fillText(labelC, x + 3, 49);
        }
      }
    });
  }

  void clear() {
    if (ctx != null) {
      ctx!.clearRect(0, 0, width, height);
      mouseCtx!.clearRect(0, 0, width, height);
    }
    axis
      ..yDecimals = null
      ..yFrom = 0
      ..yTo = 0;
  }
}
