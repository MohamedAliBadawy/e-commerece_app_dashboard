import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/user_model.dart';
import 'package:ecommerce_app_dashboard/screens/reported_users.dart';
import 'package:ecommerce_app_dashboard/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  List<User> _users = [];
  List<User> _filteredUsers = [];
  final List<User> _selectedUsers = [];
  Timer? _debounce;

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
            'User Management',
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
                        hintText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              TextButton(
                onPressed: () {
                  if (widget.onSubPageRequested != null) {
                    widget.onSubPageRequested!(ReportedUsersScreen());
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(
                  'Reported Users',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              SizedBox(width: 16.w),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(
                  'Blocked Users',
                  style: TextStyle(color: Colors.black),
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
                    _selectedUsers.length == 1
                        ? () => _showEditProductDialog(
                          context,
                          _selectedUsers.first,
                        )
                        : null,
                child: Text('Edit'),
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
                child: Text('Delete'),
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTableHeader('User ID', 1),
                        _buildTableHeader('Full name', 1),
                        _buildTableHeader('Registered Date', 1),
                        _buildTableHeader('Subscription Status', 1),
                        _buildTableHeader('', 1),
                      ],
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
                          return Center(child: Text('No users available'));
                        }
                        final users = snapshot.data!.docs;

                        if (users.isEmpty) {
                          return Center(child: Text('No users found'));
                        }
                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = User.fromDocument(
                              users[index].data() as Map<String, dynamic>,
                            );
                            return _buildUserRow(user);
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

    // Actually show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Product'),
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
                              decoration: InputDecoration(labelText: 'User ID'),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: userName,
                              decoration: InputDecoration(
                                labelText: 'User Name',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter User name';
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
                        title: Text('Is Subscribed'),
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
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Save Changes'),
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
                                Text("Updating product..."),
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
                        );

                        // Update in Firestore
                        await _userService.updateUser(updatedUser);

                        // Close loading dialog
                        Navigator.of(context).pop();

                        // Close form dialog
                        Navigator.of(context).pop();

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('User updated successfully')),
                        );

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
          title: Text('Confirm Delete'),
          content: Text(
            _selectedUsers.length == 1
                ? 'Are you sure you want to delete this user?'
                : 'Are you sure you want to delete ${_selectedUsers.length} users?',
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Delete'),
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
                          Text("Deleting users..."),
                        ],
                      ),
                    );
                  },
                );

                try {
                  // Delete each selected product
                  for (User user in _selectedUsers) {
                    await _userService.deleteUser(user.userId);
                  }
                  // Clear selections
                  _clearSelections();

                  if (!mounted) return;
                  Navigator.of(context).pop();

                  Navigator.of(context).pop();

                  // Close loading dialog
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Users deleted successfully')),
                  );
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
