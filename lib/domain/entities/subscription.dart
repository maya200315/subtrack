enum BillingCycle { monthly, yearly }

enum SubscriptionCategory { entertainment, productivity, other }

class Subscription {
  final String id;
  final String userId;
  final String name;
  final double price;
  final String currency;
  final BillingCycle billingCycle;
  final SubscriptionCategory category;
  final DateTime nextBillingDate;
  final String? note;
  final DateTime createdAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.name,
    required this.price,
    required this.currency,
    required this.billingCycle,
    required this.category,
    required this.nextBillingDate,
    this.note,
    required this.createdAt,
  });
}