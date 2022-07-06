import 'dart:html';
import 'dart:math';

import 'chart.dart';
import 'utils.dart';

class Axis {
  Axis(this.chart);

  late Chart chart;
  double xStepPix = 0;
  double xStepInterval = 0;
  double yScaleValue = 0;
  double yFrom = 0;
  double yTo = 0;
  int? yDecimals;
  String timeStep = '';

  ChartStyle get style => chart.style;

  void renderXAxis(CanvasRenderingContext2D ctx, List<DateTime> xDates) {
    final cWidth = chart.width;
    final cHeight = chart.height;
    ctx
      ..strokeStyle = style.fontColor
      ..beginPath()
      ..moveTo(style.leftMargin, cHeight - style.bottomMargin)
      ..lineTo(cWidth - style.rightMargin, cHeight - style.bottomMargin)
      ..stroke()
      ..textAlign = 'center';
    final usableWidth = cWidth - style.leftMargin - style.rightMargin - 1;
    xStepPix = usableWidth / (xDates.length - 1);
    if (chart.candleData.isNotEmpty) {
      xStepPix = usableWidth / (xDates.length - 0.5);
    }

    final y = cHeight - style.bottomMargin;
    ctx
      ..textBaseline = 'top'
      ..textAlign = 'center';
    drawXLabel(ctx, style.leftMargin, y, xDates.first);
    var prevX = style.leftMargin;
    for (var i = 1; i < (xDates.length - 1); i++) {
      final x = (style.leftMargin + (i * xStepPix)).round();
      if (x - prevX < xStepInterval) {
        continue;
      }
      drawXLabel(ctx, x, y, xDates[i]);
      prevX = x;
    }
    if (cWidth - style.rightMargin - prevX > xStepInterval) {
      drawXLabel(ctx, cWidth - style.rightMargin, y, xDates.last);
    }
  }

  void drawXLabel(CanvasRenderingContext2D ctx, int x, int y, DateTime date) {
    ctx
      ..beginPath()
      ..moveTo(x, y)
      ..lineTo(x, y + style.dashLength)
      ..stroke();
    var label = '??';
    if (timeStep.endsWith('s')) {
      label = '${date.minute}:${date.second}';
    } else if (timeStep.endsWith('m')) {
      label = formatHoursMinutes(date);
    } else if (timeStep.endsWith('h')) {
      label = formatHoursMinutes(date);
    } else if (timeStep.endsWith('d')) {
      label = formatDateHum(date);
    }
    ctx.fillText(label, x, y + style.xLabelIndent);
  }

  void renderYAxis(
      CanvasRenderingContext2D ctx, double minValue, double maxValue) {
    final cWidth = chart.width;
    final cHeight = chart.height;
    ctx
      ..beginPath()
      ..strokeStyle = style.fontColor
      ..moveTo(cWidth - style.rightMargin, style.topMargin)
      ..lineTo(cWidth - style.rightMargin, cHeight - style.bottomMargin)
      ..stroke();

    final usableHeight = cHeight - style.topMargin - style.bottomMargin;
    if (usableHeight < 10) {
      print('Not enough space for Y axis');
      return;
    }
    final diff = maxValue - minValue;
    if (yFrom == 0 && yTo == 0) {
      yFrom = minValue - (diff * 0.1);
      yTo = maxValue + (diff * 0.1);
    }
    if (yFrom < 0 && minValue >= 0) {
      yFrom = 0;
    }
    final preferStepCount = usableHeight ~/ 20;
    var yStepVal = diff / preferStepCount;
    if (yDecimals == null) {
      yDecimals = 0;
      yStepVal.toStringAsFixed(18).split('.')[1].split('').forEach((e) {
        if (e == '0') {
          yDecimals = (yDecimals ?? 0) + 1;
        } else {
          return;
        }
      });
    }
    if (yDecimals! > 6) {
      yDecimals = 0;
    }
    yDecimals = (yDecimals ?? 0) + 1;
    yFrom = roundDouble(yFrom, yDecimals!);
    yStepVal = roundDouble(yStepVal, yDecimals!);
    var currStepY = yFrom;
    var stepCount = 0;
    if (yStepVal <= 0) {
      throw Exception('yStepVal must be greater than 0');
    }
    while (yTo > currStepY) {
      currStepY += yStepVal;
      stepCount++;
    }
    yTo = currStepY;
    final yStepPix = usableHeight / stepCount;
    yScaleValue = (yTo - yFrom) / usableHeight;
    ctx
      ..textAlign = 'left'
      ..textBaseline = 'middle';

    final x = cWidth - style.rightMargin;
    for (var i = 1; i < stepCount; i++) {
      final y = (cHeight - style.bottomMargin) - (i * yStepPix);
      drawYLabel(ctx, x, y.round(), yFrom + (i * yStepVal), yDecimals!);
    }
  }

  void drawYLabel(
      CanvasRenderingContext2D ctx, int x, int y, double value, int decimals) {
    final roundedValue = roundDouble(value, decimals);
    ctx
      ..beginPath()
      ..moveTo(x, y)
      ..lineTo(x + style.dashLength, y)
      ..stroke();
    final label = roundedValue.toStringAsFixed(decimals);
    ctx.fillText(label, x + style.yLabelIndent, y);
  }

  void render(CanvasRenderingContext2D ctx) {
    if (chart.data.length < 2 && chart.candleData.length < 2) {
      print('Not enough data to draw chart');
      return;
    }
    ctx
      ..strokeStyle = style.lineColor
      ..fillStyle = style.fontColor;
    if (timeStep == '') {
      Duration diff;
      if (chart.data.isNotEmpty) {
        diff = chart.data[1].date.difference(chart.data.first.date);
      } else {
        diff = chart.candleData[1].date.difference(chart.candleData.first.date);
      }
      xStepInterval = 40;
      if (diff.inSeconds < 60) {
        timeStep = '${diff.inSeconds}s';
      } else if (diff.inMinutes < 60) {
        timeStep = '${diff.inMinutes}m';
        xStepInterval = 40;
      } else if (diff.inHours < 24) {
        timeStep = '${diff.inHours}h';
        xStepInterval = 40;
      } else {
        timeStep = '${diff.inHours / 24}d';
        xStepInterval = 60;
      }
    }
    if (chart.candleData.isNotEmpty) {
      final maxValue = chart.candleData.map((e) => e.high).reduce(max);
      final minValue = chart.candleData.map((e) => e.low).reduce(min);
      renderXAxis(ctx, chart.candleData.map((e) => e.date).toList());
      renderYAxis(ctx, minValue, maxValue);
    } else {
      final maxValue = chart.data.map((e) => e.value).reduce(max);
      final minValue = chart.data.map((e) => e.value).reduce(min);
      renderXAxis(ctx, chart.data.map((e) => e.date).toList());
      renderYAxis(ctx, minValue, maxValue);
    }
  }
}
