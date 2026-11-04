import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/order_details_screen.dart';
import 'package:ecommerce_app/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const orderData = <String, dynamic>{
    'items': [
      {'name': 'Wireless Headphones', 'price': 1995.0, 'quantity': 1},
    ],
    'itemCount': 1,
    'subtotal': 1995.0,
    'vat': 239.4,
    'totalPrice': 2234.4,
    'status': 'Shipped',
  };

  testWidgets('order card shows the order summary and opens on tap',
      (tester) async {
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: OrderCard(
            orderData: orderData,
            onTap: () => opened = true,
          ),
        ),
      ),
    );

    expect(find.text('Wireless Headphones'), findsOneWidget);
    expect(find.text('Shipped · Date not available'), findsOneWidget);
    expect(find.text('1 item · ₱2234.40'), findsOneWidget);

    await tester.tap(find.byType(OrderCard));
    expect(opened, isTrue);
  });

  testWidgets('order details show progress, items, and totals', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: OrderDetailsScreen(
          orderId: 'order-123',
          orderData: {
            ...orderData,
            'createdAt': Timestamp.fromDate(DateTime(2026)),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Order summary'), 300);
    await tester.pumpAndSettle();

    expect(find.text('Order progress'), findsOneWidget);
    expect(find.text('Shipped'), findsWidgets);
    expect(find.text('Wireless Headphones'), findsOneWidget);
    expect(find.text('Order summary'), findsOneWidget);
    expect(find.text('₱2234.40'), findsOneWidget);
    expect(find.textContaining('order-123'), findsOneWidget);
  });
}
