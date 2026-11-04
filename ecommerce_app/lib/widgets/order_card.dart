import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.orderData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = (orderData['items'] as List<dynamic>?) ?? const [];
    final firstItem = items.isNotEmpty && items.first is Map
        ? Map<String, dynamic>.from(items.first as Map)
        : const <String, dynamic>{};
    final itemName = firstItem['name'] as String? ?? 'Order items';
    final itemCount = (orderData['itemCount'] as num?)?.toInt() ??
        items.fold<int>(0, (total, item) {
          if (item is! Map) return total;
          return total + ((item['quantity'] as num?)?.toInt() ?? 1);
        });
    final total = (orderData['totalPrice'] as num?)?.toDouble() ?? 0;
    final status = orderData['status'] as String? ?? 'Pending';
    final timestamp = orderData['createdAt'] as Timestamp?;
    final date = timestamp == null
        ? 'Date not available'
        : DateFormat('MMM d, yyyy · h:mm a').format(timestamp.toDate());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$status · $date',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFC9BED8),
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$itemCount item${itemCount == 1 ? '' : 's'} · ₱${total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
