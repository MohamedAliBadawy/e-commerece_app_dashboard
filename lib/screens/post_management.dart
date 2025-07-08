import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/post_model.dart';
import 'package:ecommerce_app_dashboard/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PostManagementScreen extends StatefulWidget {
  const PostManagementScreen({super.key});

  @override
  State<PostManagementScreen> createState() => _PostManagementScreenState();
}

class _PostManagementScreenState extends State<PostManagementScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<Post> _selectedPosts = [];
  Timer? _debounce;

  Stream<QuerySnapshot> getPostsStream(String query) {
    if (query.isEmpty) {
      return FirebaseFirestore.instance.collection('posts').snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('posts')
          .where('text', isGreaterThanOrEqualTo: query)
          .where('text', isLessThan: query + 'z')
          .snapshots();
    }
  }

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

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
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
            '게시글 관리',
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: Container(
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
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
          SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTableHeader('이미지', 1),
                        _buildTableHeader('내용', 1),
                        _buildTableHeader('사용자', 1),
                        _buildTableHeader('날짜', 1),
                        _buildTableHeader('선택', 1),
                      ],
                    ),
                  ),

                  // Table body
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: getPostsStream(_searchQuery),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        // 3. Check for null data
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Center(child: Text('게시글이 없습니다'));
                        }
                        final posts = snapshot.data!.docs;

                        if (posts.isEmpty) {
                          return Center(child: Text('게시글이 없습니다'));
                        }
                        return ListView.builder(
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = Post.fromDocument(
                              posts[index].data() as Map<String, dynamic>,
                            );
                            final isSelected = _selectedPosts.any(
                              (p) => p.postId == post.postId,
                            );
                            return Container(
                              width: double.infinity,
                              height: 100.h,
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
                                        horizontal: 16.0.w,
                                      ),
                                      child:
                                          post.imgUrl.isNotEmpty
                                              ? Container(
                                                width: 100.w,
                                                height: 55.h,
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
                                        horizontal: 16.0.w,
                                      ),
                                      child: Text(post.text),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.0.w,
                                      ),
                                      child: FutureBuilder(
                                        future:
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(post.userId)
                                                .get(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData ||
                                              snapshot.data == null) {
                                            return Center(
                                              child: Text('유저를 찾을 수 없습니다'),
                                            );
                                          }

                                          final user = User.fromDocument(
                                            snapshot.data!.data()
                                                as Map<String, dynamic>,
                                          );
                                          return Text(user.name);
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.0.w,
                                      ),
                                      child: Text(post.formattedCreatedAt),
                                    ),
                                  ),

                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (value) {
                                            if (isSelected) {
                                              _deselectPost(post);
                                            } else {
                                              _selectPost(post);
                                            }
                                          },
                                        ),
                                      ],
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
}
