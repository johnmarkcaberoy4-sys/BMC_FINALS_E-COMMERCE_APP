import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/order_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum PaymentMethod { card, gcash, bank }

class PaymentScreen extends StatefulWidget {
  final double totalAmount;

  const PaymentScreen({super.key, required this.totalAmount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.card;
  bool _isLoading = false;

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await Future.delayed(const Duration(seconds: 3));

      await cartProvider.placeOrder();
      await cartProvider.clearCart();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OrderSuccessScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Failed to place order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final selectedItems = cart.items.where((item) => item.selected).toList();
    final formattedTotal = '₱${widget.totalAmount.toStringAsFixed(2)}';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Review your order')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, const Color(0xFF3B176D)],
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
                const SizedBox(height: 17),
                Text(
                  selectedItems.isEmpty
                      ? 'Your selected items'
                      : selectedItems.first.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '$formattedTotal total · ${selectedItems.length} item${selectedItems.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withAlpha(225),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CheckoutCard(
            title: 'Items',
            icon: Icons.inventory_2_outlined,
            child: Column(
              children: selectedItems.map((item) {
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
                              item.name,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Quantity · ${item.quantity}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFFC9BED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₱${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          _CheckoutCard(
            title: 'How would you like to pay?',
            icon: Icons.account_balance_wallet_outlined,
            child: Column(
              children: [
                _PaymentOption(
                  title: 'Credit or debit card',
                  icon: Icons.credit_card_outlined,
                  value: PaymentMethod.card,
                  groupValue: _selectedMethod,
                  onChanged: (value) => setState(() => _selectedMethod = value),
                ),
                _PaymentOption(
                  title: 'GCash',
                  icon: Icons.phone_android_outlined,
                  value: PaymentMethod.gcash,
                  groupValue: _selectedMethod,
                  onChanged: (value) => setState(() => _selectedMethod = value),
                ),
                _PaymentOption(
                  title: 'Bank transfer',
                  icon: Icons.account_balance_outlined,
                  value: PaymentMethod.bank,
                  groupValue: _selectedMethod,
                  onChanged: (value) => setState(() => _selectedMethod = value),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Demo checkout · no payment will be charged.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFC9BED8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CheckoutCard(
            title: 'Order summary',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                _CheckoutSummaryRow(label: 'Subtotal', amount: cart.subtotal),
                const SizedBox(height: 8),
                _CheckoutSummaryRow(label: 'VAT (12%)', amount: cart.vat),
                const Divider(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      formattedTotal,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _isLoading ? null : _processPayment,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Place order · $formattedTotal'),
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

class _CheckoutCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _CheckoutCard({
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
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final PaymentMethod value;
  final PaymentMethod groupValue;
  final ValueChanged<PaymentMethod> onChanged;

  const _PaymentOption({
    required this.title,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<PaymentMethod>(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title),
      secondary: Icon(icon),
      value: value,
      groupValue: groupValue,
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}

class _CheckoutSummaryRow extends StatelessWidget {
  final String label;
  final double amount;

  const _CheckoutSummaryRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontFamilyFallback: ['Roboto', 'Noto Sans', 'sans-serif'],
          ),
        ),
      ],
    );
  }
}
