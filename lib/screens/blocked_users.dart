import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blocked Users',
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24.h),
          Flexible(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('blocks').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(child: Text('No blocked users found'));
                }
                final blockedUsers = snapshot.data!.docs;
                return Padding(
                  padding: EdgeInsets.only(left: 70.w),
                  child: Text(
                    '${blockedUsers.length}',
                    style: TextStyle(
                      fontSize: 50.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 24.h),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SizedBox(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('blocks').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(child: Text('No blocked users found'));
                }
                final blockedUsers = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: blockedUsers.length,
                  itemBuilder: (context, index) {
                    final block = blockedUsers[index];
                    return FutureBuilder(
                      future: Future.wait([
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(block['blockedUserId'])
                            .get(),
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(block['blockedBy'])
                            .get(),
                      ]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Center(child: Text('No blocked users found'));
                        }
                        final blockedUser = snapshot.data![0].data()!;
                        final blockingUser = snapshot.data![1].data()!;
                        if (_searchQuery.isNotEmpty &&
                            !(blockedUser['name']
                                    .toString()
                                    .toLowerCase()
                                    .contains(_searchQuery) ||
                                blockedUser['userId']
                                    .toString()
                                    .toLowerCase()
                                    .contains(_searchQuery) ||
                                blockingUser['name']
                                    .toString()
                                    .toLowerCase()
                                    .contains(_searchQuery) ||
                                blockingUser['userId']
                                    .toString()
                                    .toLowerCase()
                                    .contains(_searchQuery))) {
                          return SizedBox.shrink();
                        }
                        return Container(
                          width: double.infinity,
                          height: 100.h,
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Colors.grey.shade300),
                              right: BorderSide(color: Colors.grey.shade300),
                              top: BorderSide(color: Colors.grey.shade300),
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ListTile(
                                  leading: Container(
                                    width: 56.w,
                                    height: 55.h,
                                    decoration: ShapeDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(blockedUser['url']),
                                        fit: BoxFit.cover,
                                      ),
                                      shape: OvalBorder(),
                                    ),
                                  ),
                                  subtitle: Text('${blockedUser['userId']}'),
                                  title: Text('${blockedUser['name']}'),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Flexible(child: Text('Blocked by')),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: ListTile(
                                  leading: Container(
                                    width: 56.w,
                                    height: 55.h,
                                    decoration: ShapeDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          blockingUser['url'],
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                      shape: OvalBorder(),
                                    ),
                                  ),
                                  subtitle: Text('${blockingUser['userId']}'),
                                  title: Text('${blockingUser['name']}'),
                                ),
                              ),
                            ],
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
    );
  }
}
