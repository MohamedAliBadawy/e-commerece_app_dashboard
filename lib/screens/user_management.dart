import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/user_model.dart';
import 'package:ecommerce_app_dashboard/screens/blocked_users.dart';
import 'package:ecommerce_app_dashboard/screens/reported_users.dart';
import 'package:ecommerce_app_dashboard/services/user_service.dart';
import 'package:ecommerce_app_dashboard/widgets/search_box.dart';
import 'package:ecommerce_app_dashboard/widgets/sub_page_button.dart';
import 'package:flutter/material.dart';

class UserManagementScreen extends StatefulWidget {
  final void Function(Widget subPage)? onSubPageRequested;

  const UserManagementScreen({super.key, this.onSubPageRequested});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<User> _selectedUsers = [];
  Timer? _debounce;
  late final ScrollController _headerScrollController;
  late final ScrollController _bodyScrollController;

  Stream<QuerySnapshot> getUsersStream(String query) {
    if (query.isEmpty) {
      return FirebaseFirestore.instance.collection('users').snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .snapshots();
    }
  }

  void _selectUser(User user) {
    setState(() {
      if (!_selectedUsers.any((u) => u.userId == user.userId)) {
        _selectedUsers.add(user);
      }
    });
  }

  void _clearSelections() {
    setState(() {
      _selectedUsers.clear();
    });
  }

  void _deselectUser(User user) {
    setState(() {
      _selectedUsers.removeWhere((u) => u.userId == user.userId);
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
            '사용자 관리',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),

          MediaQuery.of(context).size.width < 800
              ? Column(
                children: [
                  SearchBox(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SubPageButton(
                        label: '신고된 사용자',
                        onPressed: () {
                          if (widget.onSubPageRequested != null) {
                            widget.onSubPageRequested!(ReportedUsersScreen());
                          }
                        },
                      ),
                      SizedBox(width: 16),
                      SubPageButton(
                        label: '차단된 사용자',
                        onPressed: () {
                          if (widget.onSubPageRequested != null) {
                            widget.onSubPageRequested!(BlockedUsersScreen());
                          }
                        },
                      ),
                    ],
                  ),
                ],
              )
              : Row(
                children: [
                  Expanded(
                    child: SearchBox(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  SizedBox(width: 16),
                  SubPageButton(
                    label: '신고된 사용자',
                    onPressed: () {
                      if (widget.onSubPageRequested != null) {
                        widget.onSubPageRequested!(ReportedUsersScreen());
                      }
                    },
                  ),
                  SizedBox(width: 16),
                  SubPageButton(
                    label: '차단된 사용자',
                    onPressed: () {
                      if (widget.onSubPageRequested != null) {
                        widget.onSubPageRequested!(BlockedUsersScreen());
                      }
                    },
                  ),
                ],
              ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _selectedUsers.length == 1
                        ? () => _showEditProductDialog(
                          context,
                          _selectedUsers.first,
                        )
                        : null,
                child: Text('수정'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      _selectedUsers.length == 1 ? Colors.blue : Colors.grey,
                ),
              ),
              SizedBox(width: 16),
              TextButton(
                onPressed:
                    _selectedUsers.isNotEmpty
                        ? () => _deleteSelectedProducts()
                        : null,
                child: Text('삭제'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      _selectedUsers.isNotEmpty ? Colors.red : Colors.grey,
                ),
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
                  // Table header
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _headerScrollController,
                    child: Container(
                      width: 1600, // adjust to fit all columns

                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTableHeader('사용자 ID', 1),
                          _buildTableHeader('이름', 1),
                          _buildTableHeader('가입 날짜', 1),
                          _buildTableHeader('구독 상태', 1),
                          _buildTableHeader('선택', 1),
                        ],
                      ),
                    ),
                  ),
                  // Table body
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: getUsersStream(_searchQuery),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        // 3. Check for null data
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Center(child: Text('사용자가 없습니다'));
                        }
                        final users = snapshot.data!.docs;

                        if (users.isEmpty) {
                          return Center(child: Text('사용자가 없습니다'));
                        }
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _bodyScrollController,
                          child: SizedBox(
                            width: 1600, // match header width

                            child: ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = User.fromDocument(
                                  users[index].data() as Map<String, dynamic>,
                                );
                                return _buildUserRow(user);
                              },
                            ),
                          ),
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

  Widget _buildUserRow(User user) {
    final bool isSelected = _selectedUsers.any((p) => p.userId == user.userId);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : null,

        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(user.userId),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(user.name),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(user.formattedCreatedAt),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(user.isSub.toString()),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    if (isSelected) {
                      _deselectUser(user);
                    } else {
                      _selectUser(user);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, User user) {
    final _formKey = GlobalKey<FormState>();

    // Initialize with existing product data
    String userId = user.userId;
    String userName = user.name;
    bool isSub = user.isSub;
    String type = user.type;
    bool isBrand = user.type == 'brand';
    // Actually show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('사용자 수정'),
              content: SizedBox(
                width: 600,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: userId,
                              enabled: false,
                              decoration: InputDecoration(labelText: '사용자 ID'),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: userName,
                              decoration: InputDecoration(labelText: '이름'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '이름을 입력하세요';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                userName = value!;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      CheckboxListTile(
                        title: Text('구독 상태'),
                        value: isSub,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            isSub = value ?? false;
                          });
                        },
                        controlAffinity:
                            ListTileControlAffinity
                                .leading, // checkbox on the left
                      ),
                      SizedBox(height: 16),
                      CheckboxListTile(
                        title: Text('brand'),
                        value: isBrand,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            isBrand = value ?? false;

                            isBrand ? type = 'brand' : type = 'user';
                          });
                        },
                        controlAffinity:
                            ListTileControlAffinity
                                .leading, // checkbox on the left
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('취소'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('저장'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

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
                                Text("저장중..."),
                              ],
                            ),
                          );
                        },
                      );

                      try {
                        // Create updated product object
                        User updatedUser = User(
                          userId: userId,
                          name: userName,
                          isSub: isSub,
                          email: user.email,
                          url: user.url,
                          blocked: user.blocked,
                          createdAt: user.createdAt,
                          type: type,
                        );

                        // Update in Firestore
                        await _userService.updateUser(updatedUser);

                        // Close loading dialog
                        Navigator.of(context).pop();

                        // Close form dialog
                        Navigator.of(context).pop();

                        // Show success message
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('사용자 수정 완료')));

                        // Clear selection
                        _clearSelections();
                      } catch (e) {
                        // Close loading dialog
                        Navigator.of(context).pop();

                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Delete Product confirmation
  void _deleteSelectedProducts() {
    if (_selectedUsers.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('삭제 확인'),
          content: Text(
            _selectedUsers.length == 1
                ? '삭제하시겠습니까?'
                : '${_selectedUsers.length}명의 사용자를 삭제하시겠습니까?',
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
                          Text("삭제중..."),
                        ],
                      ),
                    );
                  },
                );

                try {
                  // Delete each selected product
                  for (User user in _selectedUsers) {
                    await _userService.deleteUser(user.userId);
                    await _userService.deleteAuthUserHttp(user.userId);
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
                  ).showSnackBar(SnackBar(content: Text('사용자 삭제 완료')));
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
