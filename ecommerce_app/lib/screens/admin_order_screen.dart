import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. MODIFY this function to accept userId
  //    This allows us to know which user to send the notification to
  Future<void> _updateOrderStatus(String orderId, String newStatus, String userId) async {
    try {
      // 2. This part is the same (update the order)
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
      });

      // 3. --- ADD THIS NEW LOGIC ---
      //    Create a new notification document
      //    This notifies the user that their order status has been updated
      await _firestore.collection('notifications').add({
        'userId': userId, // 4. The user this notification is for
        'title': 'Order Status Updated',
        'body': 'Your order ($orderId) has been updated to "$newStatus".',
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false, // 5. Mark it as unread so the badge appears
      });
      // --- END OF NEW LOGIC ---

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  // 1. MODIFY this function to accept userId
  //    We need to pass the userId to _updateOrderStatus so it can create the notification
  // --- THIS IS THE FIXED FUNCTION ---
  // It now uses 'dialogContext' to pop, fixing the crash
  // This fixes the "Admin Panel Crash" bug caused by using the wrong BuildContext.
  void _showStatusDialog(String orderId, String currentStatus, String userId) {
    showDialog(
      context: context, // This is the main screen's context
      
      // 1. RENAME this variable to 'dialogContext'
      // The showDialog's builder function gives you a new, special context just for the dialog.
      // You were accidentally re-using the screen's context, which confuses Flutter.
      builder: (dialogContext) {
        const statuses = ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

        return AlertDialog(
          title: const Text('Update Order Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses.map((status) {
              return ListTile(
                title: Text(status),
                trailing: currentStatus == status ? const Icon(Icons.check) : null,
                onTap: () {
                  // 2. PASS userId to our update function
                  //    This allows the notification to be sent to the correct user
                  _updateOrderStatus(orderId, status, userId);
                  // 2. FIX: Use 'dialogContext' to pop
                  Navigator.of(dialogContext).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              // 3. FIX: Use 'dialogContext' to pop here too
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }
  // --- END OF FIX ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('orders')
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
            return const Center(child: Text('No orders found.'));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderData = order.data() as Map<String, dynamic>;

              final Timestamp? timestamp = orderData['createdAt'];
              final String formattedDate;
              if (timestamp != null) {
                formattedDate = DateFormat('MM/dd/yyyy hh:mm a')
                    .format(timestamp.toDate());
              } else {
                formattedDate = 'Date not available';
              }

              final String status = orderData['status'] ?? 'Pending';
              // 3. Extract userId from orderData so we can pass it to the dialog
              final String userId = orderData['userId'] ?? 'Unknown User';

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(
                    'Order ID: ${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  subtitle: Text(
                    'User: ${orderData['userId'] ?? 'Unknown'}\n'
                    'Total: ₱${(orderData['totalPrice'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'} | Date: $formattedDate',
                  ),
                  isThreeLine: true,
                  trailing: Chip(
                    label: Text(
                      status,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: status == 'Pending'
                        ? Colors.orange
                        : status == 'Processing'
                            ? Theme.of(context).colorScheme.primary
                            : status == 'Shipped'
                                ? Colors.deepPurple
                                : status == 'Delivered'
                                    ? Colors.green
                                    : Colors.red,
                  ),
                  onTap: () {
                    // 3. PASS userId from the order data to our dialog
                    //    This allows the notification to be created for the correct user
                    _showStatusDialog(order.id, status, userId);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
