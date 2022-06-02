import 'dart:math';

String formatDate(DateTime date) => '${date.year.toString()}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String formatDateTime(DateTime date) => '${date.year.toString()}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')} '
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}:'
    '${date.second.toString().padLeft(2, '0')}';

String formatDateHum(DateTime date) => '${date.day.toString().padLeft(2, '0')}.'
    '${date.month.toString().padLeft(2, '0')}.'
    '${date.year.toString()}';

String formatDateTimeHum(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.'
    '${date.month.toString().padLeft(2, '0')}.'
    '${date.year.toString()} '
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}:'
    '${date.second.toString().padLeft(2, '0')}';

String formatHoursMinutes(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

double roundDouble(double value, int places) {
  final mod = pow(10, places);
  return (value * mod).round().toDouble() / mod;
}
