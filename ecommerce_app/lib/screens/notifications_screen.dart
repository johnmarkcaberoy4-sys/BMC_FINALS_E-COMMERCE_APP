import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _hasMarkedAsRead =
      false; // Track if we've already marked notifications as read

  // 1. This function will mark all unread notifications as "read"
  //    This is called when the user opens the notifications screen
  //    It uses a WriteBatch to efficiently update multiple documents at once
  void _markNotificationsAsRead(List<QueryDocumentSnapshot> docs) {
    // Only mark as read once, not on every rebuild
    if (_hasMarkedAsRead) return;

    // 2. Use a "WriteBatch" to update multiple documents at once
    //    This is much more efficient than updating each document individually
    final batch = _firestore.batch();
    bool hasUnread = false;

    for (var doc in docs) {
      if (doc['isRead'] == false) {
        hasUnread = true;
        // 3. If it's unread, add an "update" operation to the batch
        //    We mark each unread notification as read
        batch.update(doc.reference, {'isRead': true});
      }
    }

    // Only commit if there are unread notifications
    if (hasUnread) {
      // 4. "Commit" the batch, sending all updates to Firestore
      //    All updates happen in a single transaction, which is fast and atomic
      batch.commit().then((_) {
        // Mark that we've already processed the notifications
        if (mounted) {
          setState(() {
            _hasMarkedAsRead = true;
          });
        }
      });
    } else {
      // No unread notifications, just mark as processed
      _hasMarkedAsRead = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _user == null
          ? const Center(child: Text('Please log in.'))
          : StreamBuilder<QuerySnapshot>(
              // 5. Get ALL notifications for this user.
              //    We avoid a compound index requirement on web by not using orderBy here.
              //    We'll sort by createdAt on the client instead.
              stream: _firestore
                  .collection('notifications')
                  .where('userId', isEqualTo: _user!.uid)
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading notifications'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('You have no notifications.'));
                }

                // 6. Sort notifications by createdAt (newest first) on the client.
                final docs = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final aTs = (a.data() as Map<String, dynamic>)['createdAt']
                        as Timestamp?;
                    final bTs = (b.data() as Map<String, dynamic>)['createdAt']
                        as Timestamp?;
                    final aMillis = aTs?.millisecondsSinceEpoch ?? 0;
                    final bMillis = bTs?.millisecondsSinceEpoch ?? 0;
                    return bMillis.compareTo(aMillis);
                  });

                // 6. --- IMPORTANT ---
                //    As soon as we have the notifications,
                //    we call our function to mark them as read.
                //    This happens immediately when the screen loads
                //    But we only do it once to prevent notifications from disappearing
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markNotificationsAsRead(docs);
                });

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    // Format the timestamp to a readable date
                    final timestamp = (data['createdAt'] as Timestamp?);
                    final formattedDate = timestamp != null
                        ? DateFormat('MM/dd/yy hh:mm a')
                            .format(timestamp.toDate())
                        : '';

                    // 7. Check if this notification was *just* read
                    //    We check the isRead status before it gets updated
                    //    This allows us to show special styling for newly read notifications
                    final bool wasUnread = data['isRead'] == false;

                    return ListTile(
                      // 8. Show a "new" icon if it was unread
                      //    Solid purple circle for unread, outlined grey circle for read
                      leading: wasUnread
                          ? Icon(
                              Icons.circle,
                              color: Theme.of(context).colorScheme.primary,
                              size: 12,
                            )
                          : const Icon(Icons.circle_outlined,
                              color: Colors.grey, size: 12),
                      title: Text(
                        data['title'] ?? 'No Title',
                        // Bold text for unread notifications
                        style: TextStyle(
                          fontWeight:
                              wasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${data['body'] ?? ''}\n$formattedDate',
                      ),
                      isThreeLine: true,
                    );
                  },
                );
              },
            ),
    );
  }
}
