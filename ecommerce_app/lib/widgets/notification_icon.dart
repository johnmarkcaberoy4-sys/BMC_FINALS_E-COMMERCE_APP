import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screens/notifications_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    // 1. If no user, show an empty box
    //    This prevents errors when the user is not logged in
    if (user == null) {
      return const SizedBox();
    }

    // 2. This StreamBuilder's only job is to check for unread notifications
    //    It efficiently listens to Firestore for any unread notifications for this user
    return StreamBuilder<QuerySnapshot>(
      // 3. The Query:
      //    Get documents from 'notifications' collection where:
      //    - userId matches the current user
      //    - isRead is false (unread notifications)
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false) // 4. Only get UNREAD
          .snapshots(),
      
      builder: (context, snapshot) {
        // 5. We don't care about loading/error, just the data
        //    If we have data and there are documents, we have unread notifications
        bool hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        // 6. The Badge widget
        //    This shows a red dot indicator when there are unread notifications
        return Badge(
          // 7. Show a small red dot if 'hasUnread' is true
          //    The Badge widget automatically shows a red dot when isLabelVisible is true
          isLabelVisible: hasUnread,
          // 8. The icon button itself
          //    This is the bell icon that users tap to see their notifications
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              // 9. Navigate to the new NotificationsScreen
              //    When the user taps the bell, they go to see all their notifications
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

