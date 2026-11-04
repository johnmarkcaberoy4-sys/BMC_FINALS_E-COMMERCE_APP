import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/admin_panel_screen.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'package:ecommerce_app/screens/product_detail_screen.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/cart_screen.dart';
import 'package:ecommerce_app/screens/order_history_screen.dart';
import 'package:ecommerce_app/screens/profile_screen.dart'; // 1. ADD THIS - Import ProfileScreen
import 'package:ecommerce_app/widgets/notification_icon.dart'; // 2. ADD THIS - Import NotificationIcon
import 'package:ecommerce_app/screens/chat_screen.dart'; // 3. ADD THIS - Import ChatScreen
import 'package:provider/provider.dart';
import 'package:ecommerce_app/models/shop_category.dart';

// Sorting options must be top-level in Dart
enum SortOption { newest, oldest, priceHigh, priceLow }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  ShopCategory? _selectedCategory;
  // 1. Add state variable for the role
  String _userRole = 'user'; // Default to 'user'
  // 2. Get the current user
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  SortOption _sortOption = SortOption.newest;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _fetchUserRole() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _userRole = doc.data()!['role'] ?? 'user';
        });
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }

  // The _signOut function has been removed
  // Logout functionality is now in ProfileScreen

  Widget _buildCategoriesContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text(
          'Categories',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Text(
          'Browse the tech you’re looking for.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: const Color(0xFFC9BED8)),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shopCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final category = shopCategories[index];
            final isSelected = _selectedCategory == category;
            return Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedCategory = isSelected ? null : category;
                    _selectedTab = 0;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category.icon,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 30,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        category.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Explore products',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFC9BED8),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedTab == 0
          ? AppBar(
              // 1. --- THIS IS THE CHANGE ---
              //    DELETE your old title:
              /*
        title: Text(_currentUser != null ? 'Welcome, ${_currentUser!.email}' : 'Home'),
        */

              title: Image.asset(
                'asset/image/aetherix_logo.png',
                width: 210,
                height: 44,
                fit: BoxFit.contain,
              ),
              // 5. 'centerTitle' is now handled by our global AppBarTheme

              // --- END OF CHANGE ---
              actions: [
                const NotificationIcon(),
                if (_userRole == 'admin')
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    tooltip: 'Admin Panel',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdminPanelScreen(),
                        ),
                      );
                    },
                  ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          Column(
            children: [
              if (_selectedCategory != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Chip(
                        avatar: Icon(
                          _selectedCategory!.icon,
                          size: 18,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        label: Text(_selectedCategory!.name),
                        onDeleted: () {
                          setState(() => _selectedCategory = null);
                        },
                      ),
                    ],
                  ),
                ),
              // Search + Sort row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    // Search bar
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _searchController.clear(),
                                ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort dropdown
                    DropdownButton<SortOption>(
                      value: _sortOption,
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _sortOption = val;
                        });
                      },
                      items: const [
                        DropdownMenuItem(
                          value: SortOption.newest,
                          child: Text('Newest → Oldest'),
                        ),
                        DropdownMenuItem(
                          value: SortOption.oldest,
                          child: Text('Oldest → Newest'),
                        ),
                        DropdownMenuItem(
                          value: SortOption.priceHigh,
                          child: Text('Price: High → Low'),
                        ),
                        DropdownMenuItem(
                          value: SortOption.priceLow,
                          child: Text('Price: Low → High'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                            'No products found. Add some in the Admin Panel!'),
                      );
                    }

                    // Client-side filter by name and category
                    final products = snapshot.data!.docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final name =
                          (data['name'] as String? ?? '').toLowerCase();
                      final category = (data['category'] as String? ??
                              data['categoryName'] as String? ??
                              '')
                          .toLowerCase();
                      final matchesQuery =
                          _query.isEmpty || name.contains(_query);
                      final selectedCategory = _selectedCategory;
                      final matchesCategory = selectedCategory == null ||
                          category == selectedCategory.name.toLowerCase() ||
                          selectedCategory.keywords.any(
                            (keyword) =>
                                name.contains(keyword) ||
                                category.contains(keyword),
                          );
                      return matchesQuery && matchesCategory;
                    }).toList();

                    // Client-side sorting based on selected option
                    products.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aCreated = (aData['createdAt'] as Timestamp?);
                      final bCreated = (bData['createdAt'] as Timestamp?);
                      final aCreatedMs = aCreated?.millisecondsSinceEpoch ?? 0;
                      final bCreatedMs = bCreated?.millisecondsSinceEpoch ?? 0;
                      final aPrice =
                          (aData['price'] as num?)?.toDouble() ?? 0.0;
                      final bPrice =
                          (bData['price'] as num?)?.toDouble() ?? 0.0;

                      switch (_sortOption) {
                        case SortOption.newest:
                          return bCreatedMs
                              .compareTo(aCreatedMs); // newest first
                        case SortOption.oldest:
                          return aCreatedMs
                              .compareTo(bCreatedMs); // oldest first
                        case SortOption.priceHigh:
                          return bPrice.compareTo(aPrice); // high to low
                        case SortOption.priceLow:
                          return aPrice.compareTo(bPrice); // low to high
                      }
                    });

                    return GridView.builder(
                      padding: const EdgeInsets.all(10.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 3 / 4,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final productDoc = products[index];
                        final productData =
                            productDoc.data() as Map<String, dynamic>;

                        return ProductCard(
                          productName: productData['name'] ?? '',
                          price:
                              (productData['price'] as num?)?.toDouble() ?? 0.0,
                          imageUrl: productData['imageUrl'] ?? '',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  productData: productData,
                                  productId: productDoc.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          _buildCategoriesContent(),
          const CartScreen(),
          const OrderHistoryScreen(),
          const ProfileScreen(),
        ],
      ),

      // 1. --- REPLACE YOUR 'floatingActionButton:' ---
      //    This adds a "Contact Admin" button for regular users with an unread message badge
      floatingActionButton: _selectedTab == 0 && _userRole == 'user'
          ? StreamBuilder<DocumentSnapshot>(
              // 2. A new StreamBuilder
              // 3. Listen to *this user's* chat document
              //    This stream listens to the user's chat document to get unread count
              stream: _firestore
                  .collection('chats')
                  .doc(_currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadCount = 0;
                // 4. Check if the doc exists and has our count field
                //    Extract the unreadByUserCount from the document
                if (snapshot.hasData && snapshot.data!.exists) {
                  // Ensure data is not null before casting
                  final data = snapshot.data!.data();
                  if (data != null) {
                    unreadCount =
                        (data as Map<String, dynamic>)['unreadByUserCount'] ??
                            0;
                  }
                }

                // 5. --- THE FIX for "trailing not defined" ---
                //    We wrap the FAB in the Badge widget
                //    This shows a red badge with the unread count
                return Badge(
                  // 6. Show the count in the badge
                  label: Text('$unreadCount'),
                  // 7. Only show the badge if the count is > 0
                  isLabelVisible: unreadCount > 0,
                  // 8. The FAB is now the *child* of the Badge
                  child: FloatingActionButton.extended(
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Contact Admin'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatRoomId: _currentUser!.uid,
                          ),
                        ),
                      );
                    },
                  ),
                );
                // --- END OF FIX ---
              },
            )
          : null, // 9. If admin, don't show the FAB
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTab = index;
            if (index != 0) _selectedCategory = null;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Consumer<CartProvider>(
              builder: (context, cart, child) => Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
            selectedIcon: Consumer<CartProvider>(
              builder: (context, cart, child) => Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_bag),
              ),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
