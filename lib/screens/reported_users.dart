import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReportedUsersScreen extends StatefulWidget {
  const ReportedUsersScreen({super.key});

  @override
  State<ReportedUsersScreen> createState() => _ReportedUsersScreenState();
}

class _ReportedUsersScreenState extends State<ReportedUsersScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            'Reported Users',
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('reports').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return Center(child: Text('No reported users found'));
              }
              final reportedUsers = snapshot.data!.docs;
              return Text('${reportedUsers.length}');
            },
          ),
        ],
      ),
    );
  }
}
