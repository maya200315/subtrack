import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/subscription_providers.dart';
import 'add_subscription_screen.dart';
import '../providers/budget_providers.dart';
import '../../domain/usecases/calculate_budget_usage.dart';
import '../../domain/entities/subscription.dart';
import '../providers/auth_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_buildGreeting(ref)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () => _showBudgetDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              final currentLocale = context.locale;
              if (currentLocale.languageCode == 'ar') {
                context.setLocale(const Locale('en'));
              } else {
                context.setLocale(const Locale('ar'));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer(
            builder: (context, ref, _) {
              final usageAsync = ref.watch(budgetUsageProvider);
              return usageAsync.when(
                data: (usage) {
                  if (usage == null) return const SizedBox.shrink();
                  return _buildBudgetCard(usage);
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'error_occurred'.tr(),
                    style: const TextStyle(color: Color(0xFFD9534F)),
                  ),
                ),
              );
            },
          ),
          subscriptionsAsync.when(
            data: (subscriptions) {
              if (subscriptions.isEmpty) return const SizedBox.shrink();
              return _buildUpcomingSection(subscriptions);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          subscriptionsAsync.when(
            data: (subscriptions) {
              if (subscriptions.isEmpty) return const SizedBox.shrink();
              return _buildCategoryChart(subscriptions);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: subscriptionsAsync.when(
              data: (subscriptions) {
                if (subscriptions.isEmpty) {
                  return Center(
                    child: Text(
                      'no_subscriptions'.tr(),
                      key: const Key('empty_state_text'),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    final sub = subscriptions[index];
                    return Dismissible(
                      key: Key(sub.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: const Color(0xFFD9534F),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text('confirm_delete'.tr()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(false),
                                child: Text('cancel'.tr()),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(true),
                                child: Text(
                                  'delete'.tr(),
                                  style: const TextStyle(color: Color(0xFFD9534F)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        ref.read(subscriptionRepositoryProvider).deleteSubscription(sub.id);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(sub.name),
                          subtitle: Text('${sub.price} ${sub.currency}'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddSubscriptionScreen(existingSubscription: sub),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('error_occurred'.tr())),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddSubscriptionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _buildGreeting(WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting = hour < 18 ? 'good_morning'.tr() : 'good_evening'.tr();
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    final name = userEmail != null ? userEmail.split('@').first : '';
    return name.isEmpty ? greeting : '$greeting, $name';
  }

  void _showBudgetDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final currentSettings = ref.read(budgetProvider).valueOrNull;
    String selectedCurrency = currentSettings?.currency ?? 'USD';
    if (currentSettings != null && currentSettings.amount > 0) {
      controller.text = currentSettings.amount.toString();
    }
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('set_budget'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'enter_amount'.tr()),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCurrency,
                decoration: InputDecoration(labelText: 'currency'.tr()),
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'SYP', child: Text('SYP')),
                  DropdownMenuItem(value: 'TRY', child: Text('TRY')),
                ],
                onChanged: (value) {
                  setDialogState(() => selectedCurrency = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text.trim());
                if (value != null && value > 0) {
                  ref.read(budgetProvider.notifier)
                      .setBudget(value, selectedCurrency);
                }
                Navigator.of(dialogContext).pop();
              },
              child: Text('save'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BudgetUsageResult usage) {
    Color barColor;
    switch (usage.status) {
      case BudgetStatus.exceeded:
        barColor = const Color(0xFFD9534F);
        break;
      case BudgetStatus.warning:
        barColor = Colors.orange;
        break;
      case BudgetStatus.normal:
        barColor = const Color(0xFFE8734A);
        break;
    }
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${usage.totalMonthlySpending.toStringAsFixed(2)} / ${usage.budgetLimit.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: usage.usagePercentage.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 4),
            Text('${(usage.usagePercentage * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(List<Subscription> subscriptions) {
    final sorted = [...subscriptions]
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    final upcoming = sorted.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'upcoming'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...upcoming.map((sub) {
            final daysLeft =
                sub.nextBillingDate.difference(DateTime.now()).inDays;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(sub.name),
                subtitle: Text('${sub.price} ${sub.currency}'),
                trailing: Text(
                  '$daysLeft ${'days_left'.tr()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(List<Subscription> subscriptions) {
    final Map<SubscriptionCategory, double> totals = {};
    for (final sub in subscriptions) {
      final monthly = sub.billingCycle == BillingCycle.yearly
          ? sub.price / 12
          : sub.price;
      totals[sub.category] = (totals[sub.category] ?? 0) + monthly;
    }
    final grandTotal = totals.values.fold<double>(0, (a, b) => a + b);
    if (grandTotal == 0) return const SizedBox.shrink();
    final colors = {
      SubscriptionCategory.entertainment: const Color(0xFFE8734A),
      SubscriptionCategory.productivity: const Color(0xFFF5DFC8),
      SubscriptionCategory.other: const Color(0xFF22252B),
    };
    final labels = {
      SubscriptionCategory.entertainment: 'entertainment'.tr(),
      SubscriptionCategory.productivity: 'productivity'.tr(),
      SubscriptionCategory.other: 'other'.tr(),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'spending_breakdown'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: totals.entries.map((entry) {
                  final percentage = (entry.value / grandTotal) * 100;
                  return PieChartSectionData(
                    color: colors[entry.key],
                    value: entry.value,
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            children: totals.keys.map((category) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[category],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(labels[category]!),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}