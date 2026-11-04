import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = (orderData['items'] as List<dynamic>?) ?? const [];
    final status = orderData['status'] as String? ?? 'Pending';
    final total = (orderData['totalPrice'] as num?)?.toDouble() ?? 0;
    final subtotal = (orderData['subtotal'] as num?)?.toDouble() ?? total;
    final vat = (orderData['vat'] as num?)?.toDouble() ?? 0;
    final timestamp = orderData['createdAt'] as Timestamp?;
    final date = timestamp == null
        ? 'Date not available'
        : DateFormat('MMM d, yyyy · h:mm a').format(timestamp.toDate());
    final statusSteps = ['Pending', 'Processing', 'Shipped', 'Delivered'];
    final currentStep = statusSteps.indexOf(status);
    final address = orderData['deliveryAddress'];

    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  const Color(0xFF3B176D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'YOUR ORDER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  status,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Order total · ₱${total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withAlpha(225),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _DetailsCard(
            title: 'Order progress',
            icon: Icons.local_shipping_outlined,
            child: currentStep < 0
                ? Text(
                    'This order is $status.',
                    style: theme.textTheme.bodyMedium,
                  )
                : Column(
                    children: List.generate(statusSteps.length, (index) {
                      final isComplete = index <= currentStep;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 30,
                            child: Column(
                              children: [
                                Icon(
                                  isComplete
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 22,
                                  color: isComplete
                                      ? theme.colorScheme.secondary
                                      : Colors.white38,
                                ),
                                if (index < statusSteps.length - 1)
                                  Container(
                                    width: 2,
                                    height: 25,
                                    color: isComplete
                                        ? theme.colorScheme.primary
                                        : Colors.white12,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              statusSteps[index],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: index == currentStep
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: isComplete
                                    ? Colors.white
                                    : const Color(0xFFC9BED8),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
          ),
          const SizedBox(height: 14),
          _DetailsCard(
            title: 'Items in this order',
            icon: Icons.inventory_2_outlined,
            child: items.isEmpty
                ? const Text('No item details are available for this order.')
                : Column(
                    children: items.map((item) {
                      if (item is! Map) return const SizedBox.shrink();
                      final data = Map<String, dynamic>.from(item);
                      final name = data['name'] as String? ?? 'Item';
                      final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
                      final price = (data['price'] as num?)?.toDouble() ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primary.withAlpha(35),
                              child: Icon(
                                Icons.devices_outlined,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$quantity item${quantity == 1 ? '' : 's'} · ₱${price.toStringAsFixed(2)} each',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFFC9BED8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₱${(price * quantity).toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 14),
          _DetailsCard(
            title: 'Delivery address',
            icon: Icons.location_on_outlined,
            child: address is Map
                ? Text(
                    [
                      address['name'],
                      address['phone'],
                      address['street'],
                      address['city'],
                    ]
                        .whereType<String>()
                        .where((part) => part.isNotEmpty)
                        .join('\n'),
                  )
                : Text(
                    'No delivery address was saved with this order.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFC9BED8),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          _DetailsCard(
            title: 'Order summary',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                _SummaryRow(label: 'Subtotal', value: subtotal),
                const SizedBox(height: 8),
                _SummaryRow(label: 'VAT', value: vat),
                const Divider(height: 22),
                _SummaryRow(label: 'Total', value: total, isTotal: true),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Order ID: $orderId\nPlaced $date',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFC9BED8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DetailsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.secondary, size: 21),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: isTotal ? FontWeight.w800 : FontWeight.normal,
          color: isTotal ? Theme.of(context).colorScheme.secondary : null,
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('₱${value.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
