import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/post_model.dart';
import 'package:flutter/material.dart';

class ReportedPostsScreen extends StatefulWidget {
  const ReportedPostsScreen({super.key});

  @override
  State<ReportedPostsScreen> createState() => _ReportedPostsScreenState();
}

class _ReportedPostsScreenState extends State<ReportedPostsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<Post> _selectedPosts = [];
  Timer? _debounce;
  late final ScrollController _headerScrollController;
  late final ScrollController _bodyScrollController;
  void _selectPost(Post post) {
    setState(() {
      if (!_selectedPosts.any((p) => p.postId == post.postId)) {
        _selectedPosts.add(post);
      }
    });
  }

  void _clearSelections() {
    setState(() {
      _selectedPosts.clear();
    });
  }

  void _deselectPost(Post post) {
    setState(() {
      _selectedPosts.removeWhere((p) => p.postId == post.postId);
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  void _deleteSelectedPosts() {
    if (_selectedPosts.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('게시글 삭제'),
          content: Text(
            _selectedPosts.length == 1
                ? '게시글을 삭제하시겠습니까?'
                : '${_selectedPosts.length}개의 게시글을 삭제하시겠습니까?',
          ),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('삭제'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text("게시글 삭제중..."),
                        ],
                      ),
                    );
                  },
                );

                try {
                  final CollectionReference postsCollection = FirebaseFirestore
                      .instance
                      .collection('posts');
                  for (Post post in _selectedPosts) {
                    await postsCollection.doc(post.postId).delete();
                  }
                  // Clear selections
                  _clearSelections();

                  if (!mounted) return;
                  Navigator.of(context).pop();

                  Navigator.of(context).pop();

                  // Close loading dialog
                  // Show success message
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('게시글이 삭제되었습니다')));
                } catch (e) {
                  // Close loading dialog
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _headerScrollController = ScrollController();
    _bodyScrollController = ScrollController();

    _headerScrollController.addListener(() {
      if (_bodyScrollController.hasClients &&
          _bodyScrollController.offset != _headerScrollController.offset) {
        _bodyScrollController.jumpTo(_headerScrollController.offset);
      }
    });
    _bodyScrollController.addListener(() {
      if (_headerScrollController.hasClients &&
          _headerScrollController.offset != _bodyScrollController.offset) {
        _headerScrollController.jumpTo(_bodyScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reported Posts',
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
                  return Center(child: Text('No reported posts found'));
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
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _selectedPosts.isNotEmpty
                        ? () => _deleteSelectedPosts()
                        : null,
                style: TextButton.styleFrom(
                  foregroundColor:
                      _selectedPosts.isNotEmpty ? Colors.red : Colors.grey,
                ),
                child: Text('삭제'),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _headerScrollController,
            child: Container(
              width: 1600,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  _buildTableHeader('이미지', 1),
                  _buildTableHeader('내용', 1),
                  _buildTableHeader('사용자', 1),
                  _buildTableHeader('날짜', 1),
                  _buildTableHeader('reported by', 1),
                  _buildTableHeader('', 1),
                ],
              ),
            ),
          ),
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
                  controller: _bodyScrollController,
                  child: SizedBox(
                    width: 1600,
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
                            FirebaseFirestore.instance
                                .collection('posts')
                                .doc(report['postId'])
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
                            final post = Post.fromDocument(
                              snapshot.data![2].data()!,
                            );
                            final isSelected = _selectedPosts.any(
                              (p) => p.postId == post.postId,
                            );
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
                                        .contains(_searchQuery) ||
                                    post.text.toLowerCase().contains(
                                      _searchQuery,
                                    ))) {
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
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child:
                                          post.imgUrl.isNotEmpty
                                              ? Container(
                                                width: 100,
                                                height: 55,
                                                decoration: ShapeDecoration(
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                      post.imgUrl,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          0,
                                                        ),
                                                  ),
                                                ),
                                              )
                                              : Text('이미지 없음'),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: Text(post.text),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
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
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: Text(post.formattedCreatedAt),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
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
                                  ),
                                  Expanded(
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        if (isSelected) {
                                          _deselectPost(post);
                                        } else {
                                          _selectPost(post);
                                        }
                                      },
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

Widget _buildTableHeader(String title, int flex) {
  return Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
    ),
  );
}
