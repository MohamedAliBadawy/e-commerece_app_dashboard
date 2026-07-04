import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
            '차단된 사용자',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Flexible(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('blocks').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: SizedBox.shrink());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(child: Text('차단된 사용자가 없습니다'));
                }
                final blockedUsers = snapshot.data!.docs;
                return Padding(
                  padding: EdgeInsets.only(left: 70),
                  child: Text(
                    '${blockedUsers.length}',
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
                  hintText: '검색',
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
                  FirebaseFirestore.instance.collection('blocks').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: SizedBox.shrink());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(child: Text('차단된 사용자가 없습니다'));
                }
                final blockedUsers = snapshot.data!.docs;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1600,
                    child: ListView.builder(
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
                              return Center(child: SizedBox.shrink());
                            }
                            if (!snapshot.hasData || snapshot.data == null) {
                              return Center(child: Text('차단된 사용자가 없습니다'));
                            }
                            final blockedUserDoc = snapshot.data![0];
                            final blockingUserDoc = snapshot.data![1];
                            if (!blockedUserDoc.exists ||
                                !blockingUserDoc.exists ||
                                blockedUserDoc.data() == null ||
                                blockingUserDoc.data() == null) {
                              return const SizedBox.shrink();
                            }
                            final blockedUser =
                                blockedUserDoc.data() as Map<String, dynamic>;
                            final blockingUser =
                                blockingUserDoc.data() as Map<String, dynamic>;
                            if (_searchQuery.isNotEmpty &&
                                !( (blockedUser['name'] ?? '')
                                        .toString()
                                        .toLowerCase()
                                        .contains(_searchQuery) ||
                                    (blockedUser['userId'] ?? '')
                                        .toString()
                                        .toLowerCase()
                                        .contains(_searchQuery) ||
                                    (blockingUser['name'] ?? '')
                                        .toString()
                                        .toLowerCase()
                                        .contains(_searchQuery) ||
                                    (blockingUser['userId'] ?? '')
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: ListTile(
                                      leading: Container(
                                        width: 56,
                                        height: 55,
                                        decoration: ShapeDecoration(
                                          image:
                                              blockedUser['url'] != null &&
                                                      blockedUser['url']
                                                          .toString()
                                                          .isNotEmpty
                                                  ? DecorationImage(
                                                    image: NetworkImage(
                                                      blockedUser['url']
                                                          .toString(),
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                  : null,
                                          shape: OvalBorder(),
                                          color: Colors.grey.shade300,
                                        ),
                                        child:
                                            blockedUser['url'] == null ||
                                                    blockedUser['url']
                                                        .toString()
                                                        .isEmpty
                                                ? Icon(
                                                  Icons.person,
                                                  color: Colors.grey,
                                                )
                                                : null,
                                      ),
                                      subtitle: Text(
                                        '${blockedUser['userId'] ?? ''}',
                                      ),
                                      title: Text('${blockedUser['name'] ?? ''}'),
                                    ),
                                  ),
                                  Expanded(child: Text('Blocked by')),
                                  Expanded(
                                    child: ListTile(
                                      leading: Container(
                                        width: 56,
                                        height: 55,
                                        decoration: ShapeDecoration(
                                          image:
                                              blockingUser['url'] != null &&
                                                      blockingUser['url']
                                                          .toString()
                                                          .isNotEmpty
                                                  ? DecorationImage(
                                                    image: NetworkImage(
                                                      blockingUser['url']
                                                          .toString(),
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                  : null,
                                          shape: OvalBorder(),
                                          color: Colors.grey.shade300,
                                        ),
                                        child:
                                            blockingUser['url'] == null ||
                                                    blockingUser['url']
                                                        .toString()
                                                        .isEmpty
                                                ? Icon(
                                                  Icons.person,
                                                  color: Colors.grey,
                                                )
                                                : null,
                                      ),
                                      subtitle: Text(
                                        '${blockingUser['userId'] ?? ''}',
                                      ),
                                      title: Text('${blockingUser['name'] ?? ''}'),
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
