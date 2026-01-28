import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportedUsersScreen extends StatefulWidget {
  const ReportedUsersScreen({super.key});

  @override
  State<ReportedUsersScreen> createState() => _ReportedUsersScreenState();
}

class _ReportedUsersScreenState extends State<ReportedUsersScreen> {
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
            'Reported Users',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Flexible(
            child: StreamBuilder<QuerySnapshot>(
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
                return Padding(
                  padding: EdgeInsets.only(left: 70),
                  child: Text(
                    '${reportedUsers.length}',
                    style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 24),
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
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,

                  child: SizedBox(
                    width: 1600, // match header width
                    child: ListView.builder(
                      itemCount: reportedUsers.length,
                      itemBuilder: (context, index) {
                        final report = reportedUsers[index];
                        return FutureBuilder(
                          future: Future.wait([
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(report['reportedUserId'])
                                .get(),
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(report['reportingUserId'])
                                .get(),
                          ]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData || snapshot.data == null) {
                              return Center(
                                child: Text('No reported users found'),
                              );
                            }
                            final reportedUser = snapshot.data![0].data()!;
                            final reportingUser = snapshot.data![1].data()!;
                            if (_searchQuery.isNotEmpty &&
                                !(reportedUser['name']
                                        .toString()
                                        .toLowerCase()
                                        .contains(_searchQuery) ||
                                    reportedUser['userId']
                                        .toString()
                                        .toLowerCase()
                                        .contains(_searchQuery) ||
                                    reportingUser['name']
                                        .toString()
                                        .toLowerCase()
                                        .contains(_searchQuery) ||
                                    reportingUser['userId']
                                        .toString()
                                        .toLowerCase()
                                        .contains(_searchQuery))) {
                              return SizedBox.shrink();
                            }
                            return Container(
                              width: double.infinity,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Colors.grey.shade300),
                                  right: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  top: BorderSide(color: Colors.grey.shade300),
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ListTile(
                                      leading: Container(
                                        width: 56,
                                        height: 55,
                                        decoration: ShapeDecoration(
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              reportedUser['url'],
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                          shape: OvalBorder(),
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${reportedUser['userId']}',
                                      ),
                                      title: Text('${reportedUser['name']}'),
                                    ),
                                  ),
                                  Expanded(child: Text('Reported by')),
                                  Expanded(
                                    child: ListTile(
                                      leading: Container(
                                        width: 56,
                                        height: 55,
                                        decoration: ShapeDecoration(
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              reportingUser['url'],
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                          shape: OvalBorder(),
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${reportingUser['userId']}',
                                      ),
                                      title: Text('${reportingUser['name']}'),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
