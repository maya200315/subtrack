import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack/domain/entities/subscription.dart';
import 'package:subtrack/domain/strategies/currency_conversion_strategy.dart';
import 'package:subtrack/domain/usecases/calculate_budget_usage.dart';

// نسخة وهمية بسيطة: تحويل ثابت 1:1 (نفس العملة) لتسهيل الاختبار
// بدون الحاجة لاستدعاء API حقيقي
class FakeCurrencyConversionStrategy implements CurrencyConversionStrategy {
  @override
  Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    // بالاختبار، منفترض كل العملات متساوية القيمة (1:1)
    // هيك منختبر منطق الحساب لحاله، بدون تعقيد سعر الصرف الحقيقي
    return amount;
  }
}

void main() {
  late CalculateBudgetUsage calculateBudgetUsage;

  setUp(() {
    calculateBudgetUsage = CalculateBudgetUsage(FakeCurrencyConversionStrategy());
  });

  Subscription buildSubscription({
    required double price,
    required BillingCycle cycle,
    String currency = 'USD',
  }) {
    return Subscription(
      id: 'test-id',
      userId: 'test-user-id',
      name: 'Test Subscription',
      price: price,
      currency: currency,
      billingCycle: cycle,
      category: SubscriptionCategory.entertainment,
      nextBillingDate: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  test('يحسب المجموع الشهري صح لاشتراكات الشهرية ', () async {
    final subscriptions = [
      buildSubscription(price: 10, cycle: BillingCycle.monthly),
      buildSubscription(price: 20, cycle: BillingCycle.monthly),
    ];

    final result = await calculateBudgetUsage(subscriptions, 100, 'USD');

    expect(result.totalMonthlySpending, 30);
  });

  test('يحول الاشتراك السنوي لتكلفة شهرية مكافئة (÷12)', () async {
    final subscriptions = [
      buildSubscription(price: 120, cycle: BillingCycle.yearly),
    ];

    final result = await calculateBudgetUsage(subscriptions, 100, 'USD');

    expect(result.totalMonthlySpending, 10);
  });

  test('يرجع status = normal لو النسبة أقل من 80%', () async {
    final subscriptions = [
      buildSubscription(price: 50, cycle: BillingCycle.monthly),
    ];

    final result = await calculateBudgetUsage(subscriptions, 100, 'USD');

    expect(result.status, BudgetStatus.normal);
  });

  test('يرجع status = warning لو النسبة بين 80% و 100%', () async {
    final subscriptions = [
      buildSubscription(price: 85, cycle: BillingCycle.monthly),
    ];

    final result = await calculateBudgetUsage(subscriptions, 100, 'USD');

    expect(result.status, BudgetStatus.warning);
  });

  test('يرجع status = exceeded لو تجاوز الميزانية', () async {
    final subscriptions = [
      buildSubscription(price: 150, cycle: BillingCycle.monthly),
    ];

    final result = await calculateBudgetUsage(subscriptions, 100, 'USD');

    expect(result.status, BudgetStatus.exceeded);
  });

  test('يرجع 0% لو لا يوجد اشتراكات إطلاقاً', () async {
    final result = await calculateBudgetUsage([], 100, 'USD');

    expect(result.totalMonthlySpending, 0);
    expect(result.status, BudgetStatus.normal);
  });
}