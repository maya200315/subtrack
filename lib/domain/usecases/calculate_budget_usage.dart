import '../entities/subscription.dart';
import '../strategies/currency_conversion_strategy.dart';

enum BudgetStatus { normal, warning, exceeded }

class BudgetUsageResult {
  final double totalMonthlySpending;
  final double budgetLimit;
  final double usagePercentage;
  final BudgetStatus status;

  const BudgetUsageResult({
    required this.totalMonthlySpending,
    required this.budgetLimit,
    required this.usagePercentage,
    required this.status,
  });
}

class CalculateBudgetUsage {
  final CurrencyConversionStrategy _conversionStrategy;

  CalculateBudgetUsage(this._conversionStrategy);

  Future<BudgetUsageResult> call(
      List<Subscription> subscriptions,
      double budgetLimit,
      String budgetCurrency,
      ) async {
    double totalMonthly = 0;

    for (final sub in subscriptions) {
      final monthlyEquivalent = sub.billingCycle == BillingCycle.yearly
          ? sub.price / 12
          : sub.price;

      final convertedAmount = await _conversionStrategy.convert(
        amount: monthlyEquivalent,
        fromCurrency: sub.currency,
        toCurrency: budgetCurrency,
      );

      totalMonthly += convertedAmount;
    }

    final percentage = budgetLimit <= 0
        ? 0.0
        : (totalMonthly / budgetLimit).clamp(0.0, double.infinity);

    BudgetStatus status;
    if (percentage >= 1.0) {
      status = BudgetStatus.exceeded;
    } else if (percentage >= 0.8) {
      status = BudgetStatus.warning;
    } else {
      status = BudgetStatus.normal;
    }

    return BudgetUsageResult(
      totalMonthlySpending: totalMonthly,
      budgetLimit: budgetLimit,
      usagePercentage: percentage,
      status: status,
    );
  }
}