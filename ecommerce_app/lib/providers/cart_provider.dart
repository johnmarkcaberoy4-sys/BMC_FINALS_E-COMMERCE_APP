import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  bool selected;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.selected = true,
  });

  // Convert CartItem to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'selected': selected,
    };
  }

  // Create CartItem from Map (from Firestore)
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      // Default to true for older saved carts that don't have this field
      selected: (json['selected'] as bool?) ?? true,
    );
  }
}

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  String? _userId;
  StreamSubscription? _authSubscription;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- THIS IS THE FIX (PART 1) ---
  // 1. DELETE the entire CartProvider() constructor.
  // We moved the auth-listening logic out of the constructor and into a new, separate function.
  // This fixes the "Stuck Splash Screen" bug by preventing a deadlock during initialization.
  
  // 2. ADD this new EMPTY constructor.
  CartProvider() {
    print('CartProvider created.');
  }

  // 3. ADD this new PUBLIC method. We moved all the logic here.
  // This method is called from main.dart before runApp() to ensure all logic is ready.
  void initializeAuthListener() {
    print('CartProvider auth listener initialized');
    // Listen to authentication changes
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // User is logged out
        print('User logged out, clearing cart.');
        _userId = null;
        _items = [];
      } else {
        // User is logged in
        print('User logged in: ${user.uid}. Fetching cart...');
        _userId = user.uid;
        _fetchCart();
      }
      notifyListeners();
    });
  }
  // --- END OF FIX ---

  List<CartItem> get items => _items;

  // --- THIS IS THE GETTERS SECTION ---
  
  // 1. RENAME 'totalPrice' to 'subtotal'
  //    This is the total price *before* tax.
  //    This represents the sum of all item prices multiplied by their quantities
  double get subtotal {
    double total = 0.0;
    for (var item in _items.where((i) => i.selected)) {
      total += (item.price * item.quantity);
    }
    return total;
  }

  // 2. ADD this new getter for VAT (12%)
  //    VAT (Value Added Tax) is calculated as 12% of the subtotal
  //    This is the standard VAT rate in the Philippines
  double get vat {
    return subtotal * 0.12; // 12% of the subtotal
  }
  
  // 3. ADD this new getter for the FINAL total
  //    This is the total price including VAT (subtotal + vat)
  double get totalPriceWithVat {
    return subtotal + vat;
  }
  
  // 4. We can leave the old 'totalPrice' getter for backward compatibility
  //    But we'll update 'itemCount' to be cleaner:
  //    This calculates the total number of items in the cart (sum of all quantities)
  int get itemCount {
    // This 'fold' is a cleaner way to sum a list.
    return _items.fold(0, (total, item) => total + item.quantity);
  }

  // Whether there is at least one selected item
  bool get hasSelectedItems => _items.any((i) => i.selected);

  // Keep old totalPrice for backward compatibility (deprecated - use totalPriceWithVat instead)
  @Deprecated('Use totalPriceWithVat instead')
  double get totalPrice {
    return totalPriceWithVat;
  }

  Future<void> _fetchCart() async {
    if (_userId == null) return;
    try {
      final doc = await _firestore.collection('userCarts').doc(_userId).get();

      if (doc.exists && doc.data()!['cartItems'] != null) {
        final List<dynamic> cartData = doc.data()!['cartItems'];
        _items = cartData.map((item) => CartItem.fromJson(item)).toList();
        print('Cart fetched successfully: ${_items.length} items');
      } else {
        _items = [];
      }
    } catch (e) {
      print('Error fetching cart: $e');
      _items = [];
    }
    notifyListeners();
  }

  Future<void> _saveCart() async {
    if (_userId == null) return;
    try {
      final List<Map<String, dynamic>> cartData =
          _items.map((item) => item.toJson()).toList();

      await _firestore.collection('userCarts').doc(_userId).set({
        'cartItems': cartData,
      });
      print('Cart saved to Firestore');
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // 1. THIS IS THE OLD FUNCTION:
  // void addItem(String id, String name, double price) { ... }

  // 2. THIS IS THE NEW, UPDATED FUNCTION:
  // This function now accepts a quantity parameter, allowing users to add multiple items at once
  void addItem(String id, String name, double price, int quantity) {
    // 3. Check if the item is already in the cart
    var index = _items.indexWhere((item) => item.id == id);

    if (index != -1) {
      // 4. If YES: Add the new quantity to the existing quantity
      //    For example, if user already has 2 items and adds 5 more, they'll have 7 total
      _items[index].quantity += quantity;
    } else {
      // 5. If NO: Add the item with the specified quantity
      //    Use the quantity from the parameter (e.g., if user selected 5, add 5)
      _items.add(CartItem(
        id: id,
        name: name,
        price: price,
        quantity: quantity, // Use the quantity from the parameter
      ));
    }

    _saveCart(); // Save the updated cart to Firestore
    notifyListeners(); // Notify all listeners that the cart has changed
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _saveCart();
    notifyListeners();
  }

  // Select or deselect a specific item
  void setItemSelected(String id, bool selected) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _items[index].selected = selected;
    _saveCart();
    notifyListeners();
  }

  // Select or deselect all items
  void setAllSelected(bool selected) {
    for (final item in _items) {
      item.selected = selected;
    }
    _saveCart();
    notifyListeners();
  }

  Future<void> placeOrder() async {
    // Only place order for selected items
    final selectedItems = _items.where((i) => i.selected).toList();
    if (_userId == null || selectedItems.isEmpty) {
      throw Exception('No selected items or user is not logged in.');
    }

    try {
      final List<Map<String, dynamic>> cartData = 
          selectedItems.map((item) => item.toJson()).toList();
      
      // 1. --- THIS IS THE CHANGE ---
      //    Get all our new calculated values
      //    We calculate subtotal, VAT, and final total for the order
      final double sub = subtotal;
      final double v = vat;
      final double total = totalPriceWithVat;
      final int count = itemCount;

      // 2. Update the data we save to Firestore
      //    We now save the price breakdown (subtotal, vat, totalPrice) for receipts and admin panel
      await _firestore.collection('orders').add({
        'userId': _userId,
        'items': cartData,
        'subtotal': sub,       // 3. ADD THIS - Price before VAT
        'vat': v,            // 4. ADD THIS - VAT amount (12% of subtotal)
        'totalPrice': total,   // 5. This is now the VAT-inclusive price (final total)
        'itemCount': count, // count of all items in cart (kept as-is)
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      // --- END OF CHANGE ---

    } catch (e) {
      print('Error placing order: $e');
      throw e; 
    }
  }

  Future<void> clearCart() async {
    _items = [];

    if (_userId != null) {
      try {
        await _firestore.collection('userCarts').doc(_userId).set({
          'cartItems': [],
        });
        print('Firestore cart cleared.');
      } catch (e) {
        print('Error clearing Firestore cart: $e');
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
