import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/payment_screen.dart'; // 1. Import PaymentScreen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 2. It's a StatelessWidget again!
// We removed the StatefulWidget conversion and all the order logic
// The order logic is now in PaymentScreen
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. We listen: true, so the list and total update
    //    This ensures the UI rebuilds when the cart changes
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: Column(
        children: [
          // 4. "Select All" toggle
          if (cart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select All', style: TextStyle(fontSize: 16)),
                  Switch(
                    value: cart.items.every((i) => i.selected),
                    onChanged: (val) => cart.setAllSelected(val),
                  ),
                ],
              ),
            ),
          // 5. The ListView displays all items in the cart with a checkbox
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text('Your cart is empty.'))
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final cartItem = cart.items[index];
                      return ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: cartItem.selected,
                              onChanged: (val) {
                                if (val != null) {
                                  cart.setItemSelected(cartItem.id, val);
                                }
                              },
                            ),
                            CircleAvatar(
                              child: Text(cartItem.name[0]),
                            ),
                          ],
                        ),
                        title: Text(cartItem.name),
                        subtitle: Text('Qty: ${cartItem.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₱${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamilyFallback: [
                                  'Roboto',
                                  'Noto Sans',
                                  'sans-serif'
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                cart.removeItem(cartItem.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 6. --- PRICE BREAKDOWN for SELECTED items ---
          //    This shows the subtotal, VAT, and final total
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ROW 1: Subtotal
                  // This is the total price before VAT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal (selected):',
                          style: TextStyle(fontSize: 16)),
                      Text(
                        '₱${cart.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontFamilyFallback: [
                              'Roboto',
                              'Noto Sans',
                              'sans-serif'
                            ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ROW 2: VAT
                  // This shows the 12% VAT amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('VAT (12%):', style: TextStyle(fontSize: 16)),
                      Text(
                        '₱${cart.vat.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontFamilyFallback: [
                              'Roboto',
                              'Noto Sans',
                              'sans-serif'
                            ]),
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1),
                  // ROW 3: Total
                  // This is the final VAT-inclusive total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        '₱${cart.totalPriceWithVat.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontFamilyFallback: [
                            'Roboto',
                            'Noto Sans',
                            'sans-serif'
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 7. --- BUTTON: disabled if no selected items ---
          //    This button now navigates to PaymentScreen instead of placing order directly
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              // Disable when no items are selected
              onPressed: (!cart.hasSelectedItems)
                  ? null
                  : () {
                      // 8. Navigate to our new PaymentScreen
                      //    This separates "managing a cart" from "processing a payment"
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            // 9. Pass the final VAT-inclusive total
                            //    This is the amount the user needs to pay
                            totalAmount: cart.totalPriceWithVat,
                          ),
                        ),
                      );
                    },
              // 10. No more spinner!
              //    The loading state is now handled in PaymentScreen
              child: const Text('Proceed to Payment'),
            ),
          ),
        ],
      ),
    );
  }
}
