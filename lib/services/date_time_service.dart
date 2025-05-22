import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DateTimeService {
  /// Cihazın localine göre tarih biçimlendir
  static String formatLocalDate(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).toString(); // Örn: tr_TR
    final formatter = DateFormat.yMMMMd(locale).add_Hm(); // Örn: 21 Mayıs 2025 18:12
    return formatter.format(date);
  }

  /// ISO tarih string'ini local biçime çevir
  static String formatFromISO(String isoString, BuildContext context) {
    try {
      final date = DateTime.parse(isoString);
      return formatLocalDate(date, context);
    } catch (_) {
      return isoString;
    }
  }
}
