import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subscription.dart';

class SubscriptionModel extends Subscription {
  const SubscriptionModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.price,
    required super.currency,
    required super.billingCycle,
    required super.category,
    required super.nextBillingDate,
    super.note,
    required super.createdAt,
  });


  factory SubscriptionModel.fromMap(String id, Map<String, dynamic> map) {
    return SubscriptionModel(
      id: id,
      userId: map['userId'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      currency: map['currency'] as String,
      billingCycle: BillingCycle.values.byName(map['billingCycle'] as String),
      category: SubscriptionCategory.values.byName(map['category'] as String),
      nextBillingDate: (map['nextBillingDate'] as Timestamp).toDate(),
      note: map['note'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'userId': userId,
      'price': price,
      'currency': currency,
      'billingCycle': billingCycle.name,
      'category': category.name,
      'nextBillingDate': Timestamp.fromDate(nextBillingDate),
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}