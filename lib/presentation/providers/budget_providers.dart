import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/usecases/calculate_budget_usage.dart';
import '../../domain/strategies/currency_conversion_strategy.dart';
import '../../data/strategies/frankfurter_conversion_strategy.dart';
import 'subscription_providers.dart';

const _budgetAmountKey = 'monthly_budget_amount';
const _budgetCurrencyKey = 'monthly_budget_currency';

class BudgetSettings {
  final double amount;
  final String currency;

  const BudgetSettings({required this.amount, required this.currency});
}

class BudgetNotifier extends AsyncNotifier<BudgetSettings> {
  @override
  Future<BudgetSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return BudgetSettings(
      amount: prefs.getDouble(_budgetAmountKey) ?? 0.0,
      currency: prefs.getString(_budgetCurrencyKey) ?? 'USD',
    );
  }

  Future<void> setBudget(double amount, String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_budgetAmountKey, amount);
    await prefs.setString(_budgetCurrencyKey, currency);
    state = AsyncData(BudgetSettings(amount: amount, currency: currency));
  }
}

final budgetProvider = AsyncNotifierProvider<BudgetNotifier, BudgetSettings>(
  BudgetNotifier.new,
);

final currencyConversionStrategyProvider =
Provider<CurrencyConversionStrategy>((ref) {
  return FrankfurterConversionStrategy();
});

final calculateBudgetUsageProvider = Provider<CalculateBudgetUsage>((ref) {
  final strategy = ref.watch(currencyConversionStrategyProvider);
  return CalculateBudgetUsage(strategy);
});

final budgetUsageProvider = FutureProvider<BudgetUsageResult?>((ref) async {
  final subscriptionsAsync = ref.watch(subscriptionsStreamProvider);
  final budgetAsync = ref.watch(budgetProvider);
  final calculateUsage = ref.watch(calculateBudgetUsageProvider);

  final subscriptions = subscriptionsAsync.valueOrNull;
  final budgetSettings = budgetAsync.valueOrNull;

  if (subscriptions == null || budgetSettings == null) return null;
  if (budgetSettings.amount <= 0) return null;

  try {
    return await calculateUsage(
      subscriptions,
      budgetSettings.amount,
      budgetSettings.currency,
    );
  } catch (e) {
    throw Exception('budget_calculation_failed');
  }
});