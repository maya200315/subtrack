
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/strategies/currency_conversion_strategy.dart';

class FrankfurterConversionStrategy implements CurrencyConversionStrategy {
  // تم تصحيح الرابط إلى الإصدار الرسمي والمستقر من Frankfurter API
  static const _baseUrl = 'https://api.frankfurter.app/latest';

  // أسعار ثابتة يدوية للعملات غير المدعومة من الـ API (مثل SYP)
  static const Map<String, double> _manualRatesToUsd = {
    'SYP': 1 / 13000, // سعر تقريبي
  };

  @override
  Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) return amount;

    final fromIsManual = _manualRatesToUsd.containsKey(fromCurrency);
    final toIsManual = _manualRatesToUsd.containsKey(toCurrency);

    // حالة: عملة يدوية (SYP) تحويل لعملة أخرى
    if (fromIsManual || toIsManual) {
      final amountInUsd = fromIsManual
          ? amount * _manualRatesToUsd[fromCurrency]!
          : amount;

      if (toCurrency == 'USD') return amountInUsd;
      if (toIsManual) return amountInUsd / _manualRatesToUsd[toCurrency]!;

      // تحويل من USD للعملة الهدف عبر الـ API
      return _fetchRate(amountInUsd, 'USD', toCurrency);
    }

    // الحالة العادية: العملتان مدعومتان من الـ API
    return _fetchRate(amount, fromCurrency, toCurrency);
  }

  Future<double> _fetchRate(
      double amount, String from, String to) async {
    final uri = Uri.parse('$_baseUrl?from=$from&to=$to');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch exchange rate: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rates = data['rates'] as Map<String, dynamic>;
    final rate = (rates[to] as num).toDouble();

    return amount * rate;
  }
}