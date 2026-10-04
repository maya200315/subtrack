abstract class CurrencyConversionStrategy {
  Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  });
}