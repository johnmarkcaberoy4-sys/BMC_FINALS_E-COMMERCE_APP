import 'package:flutter/material.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';

// 1. Change StatelessWidget to StatefulWidget
// This allows us to manage state (the quantity selector)
class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productData,
    required this.productId,
  });

  @override
  // 2. Create the State class
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

// 3. Rename the main class to _ProductDetailScreenState and extend State
class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // 4. ADD OUR NEW STATE VARIABLE FOR QUANTITY
  // This holds the number shown between the + and - buttons
  // It always starts at 1
  int _quantity = 1;

  // 1. ADD THIS FUNCTION
  // This function increases the quantity by 1
  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  // 2. ADD THIS FUNCTION
  // This function decreases the quantity by 1, but not below 1
  void _decrementQuantity() {
    // We don't want to go below 1
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  // 5. The build method will go inside here
  @override
  Widget build(BuildContext context) {
    // 1. We now access productData using 'widget.'
    //    Because we are in a StatefulWidget, we must access the original parameters using widget.
    final String name = widget.productData['name'] ?? '';
    final String description = widget.productData['description'] ?? '';
    final String imageUrl = widget.productData['imageUrl'] ?? '';
    final double price =
        (widget.productData['price'] as num?)?.toDouble() ?? 0.0;

    // 2. Get the CartProvider (same as before)
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product image with responsive sizing
            // Uses 40% of screen height for better viewing
            SizedBox(
              height: MediaQuery.of(context).size.height *
                  0.4, // 40% of screen height
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit
                    .contain, // Changed to contain so full image is visible
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child:
                        Icon(Icons.broken_image, size: 100, color: Colors.grey),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors
                          .white, // White text for visibility on black background
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                      // Ensure Peso sign renders on all platforms by using system font fallback
                      fontFamilyFallback: ['Roboto', 'Noto Sans', 'sans-serif'],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  Text(
                    'About this item',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white, // White text for visibility
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color:
                          Color(0xFFE0E0E0), // Light grey text for readability
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. --- ADD THIS NEW SECTION ---
                  //    (before the "Add to Cart" button)
                  //    This is the quantity selector with + and - buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 5. DECREMENT BUTTON
                      //    This decreases the quantity (but not below 1)
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: _decrementQuantity,
                      ),

                      // 6. QUANTITY DISPLAY
                      //    This shows the current selected quantity
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '$_quantity', // 7. Display our state variable
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // White text for visibility
                          ),
                        ),
                      ),

                      // 8. INCREMENT BUTTON
                      //    This increases the quantity
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: _incrementQuantity,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // --- END OF NEW SECTION ---
                  // Add some bottom spacing so content isn't hidden behind the bottom button
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            onPressed: () {
              // Add selected quantity of this product
              cart.addItem(
                widget.productId,
                name,
                price,
                _quantity,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added $_quantity x $name to cart!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Add to Cart'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
