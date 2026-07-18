import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/user_model.dart';
import 'package:ecommerce_app_dashboard/screens/blocked_users.dart';
import 'package:ecommerce_app_dashboard/screens/reported_users.dart';
import 'package:ecommerce_app_dashboard/services/user_service.dart';
import 'package:ecommerce_app_dashboard/widgets/search_box.dart';
import 'package:ecommerce_app_dashboard/widgets/sub_page_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/hover_scrollbar.dart';

class UserPageState {
  final List<User> users;
  final bool hasMore;
  final bool isLoading;
  final bool isError;
  final String errorMessage;
  final String searchQuery;
  final String sortColumn;
  final bool sortAscending;

  UserPageState({
    required this.users,
    required this.hasMore,
    required this.isLoading,
    required this.isError,
    this.errorMessage = '',
    required this.searchQuery,
    required this.sortColumn,
    required this.sortAscending,
  });

  UserPageState copyWith({
    List<User>? users,
    bool? hasMore,
    bool? isLoading,
    bool? isError,
    String? errorMessage,
    String? searchQuery,
    String? sortColumn,
    bool? sortAscending,
  }) {
    return UserPageState(
      users: users ?? this.users,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      sortColumn: sortColumn ?? this.sortColumn,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

final userPaginationProvider =
    NotifierProvider.autoDispose<UserPaginationNotifier, UserPageState>(
  UserPaginationNotifier.new,
);

class UserPaginationNotifier extends Notifier<UserPageState> {
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 20;

  @override
  UserPageState build() {
    _lastDocument = null;

    Future.microtask(() => fetchNextPage(reset: true));

    return UserPageState(
      users: [],
      hasMore: true,
      isLoading: true,
      isError: false,
      searchQuery: '',
      sortColumn: 'createdAt',
      sortAscending: false,
    );
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(
      searchQuery: query,
      users: [],
      hasMore: true,
      isLoading: true,
      isError: false,
    );
    _lastDocument = null;
    fetchNextPage(reset: true);
  }

  void toggleSort(String column) {
    final nextAscending = state.sortColumn == column ? !state.sortAscending : true;
    state = state.copyWith(
      sortColumn: column,
      sortAscending: nextAscending,
      users: [],
      hasMore: true,
      isLoading: true,
      isError: false,
    );
    _lastDocument = null;
    fetchNextPage(reset: true);
  }

  Future<void> fetchNextPage({bool reset = false}) async {
    if (!reset && (!state.hasMore || (state.users.isNotEmpty && state.isLoading))) return;

    if (!reset) {
      state = state.copyWith(isLoading: true);
    }

    try {
      final query = state.searchQuery;
      final sortColumn = state.sortColumn;
      final sortAscending = state.sortAscending;

      Query firestoreQuery = FirebaseFirestore.instance.collection('users');

      if (query.isNotEmpty) {
        firestoreQuery = firestoreQuery
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThan: query + 'z');
      } else {
        firestoreQuery = firestoreQuery.orderBy(sortColumn, descending: !sortAscending);
      }

      if (_lastDocument != null && query.isEmpty) {
        firestoreQuery = firestoreQuery.startAfterDocument(_lastDocument!);
      }

      final limitValue = query.isNotEmpty ? 100 : _pageSize;
      final snapshot = await firestoreQuery.limit(limitValue).get();

      final fetchedUsers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return User.fromDocument(data);
      }).toList();

      if (query.isNotEmpty) {
        fetchedUsers.sort((a, b) {
          if (sortColumn == 'createdAt') {
            final aTime = a.createdAt;
            final bTime = b.createdAt;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return sortAscending ? aTime.compareTo(bTime) : bTime.compareTo(aTime);
          } else if (sortColumn == 'userId') {
            return sortAscending ? a.userId.compareTo(b.userId) : b.userId.compareTo(a.userId);
          } else if (sortColumn == 'name') {
            return sortAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name);
          } else if (sortColumn == 'isSub') {
            final aVal = a.isSub ? 1 : 0;
            final bVal = b.isSub ? 1 : 0;
            return sortAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
          }
          return 0;
        });
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      final hasMore = query.isNotEmpty ? false : (snapshot.docs.length == _pageSize);

      state = state.copyWith(
        users: reset ? fetchedUsers : [...state.users, ...fetchedUsers],
        hasMore: hasMore,
        isLoading: false,
        isError: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: e.toString(),
      );
    }
  }
}

class UserManagementScreen extends ConsumerStatefulWidget {
  final void Function(Widget subPage)? onSubPageRequested;

  const UserManagementScreen({super.key, this.onSubPageRequested});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  final List<User> _selectedUsers = [];
  Timer? _debounce;
  late final ScrollController _headerScrollController;
  late final ScrollController _bodyScrollController;
  late final ScrollController _verticalScrollController;

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
      ref.read(userPaginationProvider.notifier).setSearchQuery(query);
    });
  }

  void _toggleSort(String column) {
    ref.read(userPaginationProvider.notifier).toggleSort(column);
  }

  @override
  void initState() {
    super.initState();
    _headerScrollController = ScrollController();
    _bodyScrollController = ScrollController();
    _verticalScrollController = ScrollController();

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
    _verticalScrollController.addListener(() {
      // Pagination trigger
      if (_verticalScrollController.position.pixels >=
          _verticalScrollController.position.maxScrollExtent - 200) {
        ref.read(userPaginationProvider.notifier).fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paginationState = ref.watch(userPaginationProvider);
    final sortColumn = paginationState.sortColumn;
    final sortAscending = paginationState.sortAscending;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '사용자 관리',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          MediaQuery.of(context).size.width < 800
              ? Column(
                  children: [
                    SearchBox(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SubPageButton(
                          label: '신고된 사용자',
                          onPressed: () {
                            if (widget.onSubPageRequested != null) {
                              widget.onSubPageRequested!(const ReportedUsersScreen());
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        SubPageButton(
                          label: '차단된 사용자',
                          onPressed: () {
                            if (widget.onSubPageRequested != null) {
                              widget.onSubPageRequested!(const BlockedUsersScreen());
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
                    const SizedBox(width: 16),
                    SubPageButton(
                      label: '신고된 사용자',
                      onPressed: () {
                        if (widget.onSubPageRequested != null) {
                          widget.onSubPageRequested!(const ReportedUsersScreen());
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    SubPageButton(
                      label: '차단된 사용자',
                      onPressed: () {
                        if (widget.onSubPageRequested != null) {
                          widget.onSubPageRequested!(const BlockedUsersScreen());
                        }
                      },
                    ),
                  ],
                ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _selectedUsers.length == 1
                    ? () => _showEditProductDialog(
                          context,
                          _selectedUsers.first,
                        )
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor:
                      _selectedUsers.length == 1 ? Colors.black : Colors.grey,
                ),
                child: const Text('수정'),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: _selectedUsers.isNotEmpty
                    ? () => _deleteSelectedProducts()
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor:
                      _selectedUsers.isNotEmpty ? Colors.red : Colors.grey,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                          _buildTableHeader(
                            '사용자 ID',
                            1,
                            onTap: () => _toggleSort('userId'),
                            showArrow: sortColumn == 'userId',
                            sortAscending: sortAscending,
                          ),
                          _buildTableHeader(
                            '이름',
                            1,
                            onTap: () => _toggleSort('name'),
                            showArrow: sortColumn == 'name',
                            sortAscending: sortAscending,
                          ),
                          _buildTableHeader(
                            '가입 날짜',
                            1,
                            onTap: () => _toggleSort('createdAt'),
                            showArrow: sortColumn == 'createdAt',
                            sortAscending: sortAscending,
                          ),
                          _buildTableHeader(
                            '구독 상태',
                            1,
                            onTap: () => _toggleSort('isSub'),
                            showArrow: sortColumn == 'isSub',
                            sortAscending: sortAscending,
                          ),
                          _buildTableHeader('선택', 1),
                        ],
                      ),
                    ),
                  ),
                  // Table body
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final paginationState = ref.watch(userPaginationProvider);
                        final users = paginationState.users;

                        if (users.isEmpty && paginationState.isLoading) {
                          return const Center(child: SizedBox.shrink());
                        }

                        if (users.isEmpty) {
                          return const Center(child: Text('사용자가 없습니다'));
                        }

                        return HoverScrollbar(
                          controller: _bodyScrollController,
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: _bodyScrollController,
                            child: SizedBox(
                              width: 1600, // match header width
                            child: ListView.builder(
                              controller: _verticalScrollController,
                              itemCount: users.length + (paginationState.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == users.length) {
                                  if (paginationState.isError) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('Error: ${paginationState.errorMessage}'),
                                      ),
                                    );
                                  }
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: SizedBox.shrink(),
                                    ),
                                  );
                                }
                                final user = users[index];
                                return _buildUserRow(user);
                              },
                            ),
                          ),
                        ),);
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

  Widget _buildTableHeader(
    String title,
    int flex, {
    VoidCallback? onTap,
    bool showArrow = false,
    bool sortAscending = false,
  }) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (showArrow) ...[
                const SizedBox(width: 4),
                Icon(
                  sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: Colors.black,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserRow(User user) {
    final bool isSelected = _selectedUsers.any((p) => p.userId == user.userId);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey.shade100 : null,
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
    final formKey = GlobalKey<FormState>();

    String userId = user.userId;
    String userName = user.name;
    bool isSub = user.isSub;
    String type = user.type;
    bool isBrand = user.type == 'brand';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('사용자 수정'),
              content: SizedBox(
                width: 600,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: userId,
                              enabled: false,
                              decoration: const InputDecoration(labelText: '사용자 ID'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: userName,
                              decoration: const InputDecoration(labelText: '이름'),
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
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('구독 상태'),
                        value: isSub,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            isSub = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('brand'),
                        value: isBrand,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            isBrand = value ?? false;
                            isBrand ? type = 'brand' : type = 'user';
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('취소'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('저장'),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const AlertDialog(
                            content: Row(
                              children: [
                                SizedBox.shrink(),
                                SizedBox(width: 16),
                                Text("저장중..."),
                              ],
                            ),
                          );
                        },
                      );

                      try {
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

                        await _userService.updateUser(updatedUser);

                        if (!mounted) return;
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('사용자 수정 완료')),
                        );

                        _clearSelections();
                      } catch (e) {
                        if (!mounted) return;
                        Navigator.of(context).pop();

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

  void _deleteSelectedProducts() {
    if (_selectedUsers.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: Text(
            _selectedUsers.length == 1
                ? '삭제하시겠습니까?'
                : '${_selectedUsers.length}명의 사용자를 삭제하시겠습니까?',
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('삭제'),
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      content: Row(
                        children: [
                          SizedBox.shrink(),
                          SizedBox(width: 16),
                          Text("삭제중..."),
                        ],
                      ),
                    );
                  },
                );

                try {
                  for (User user in _selectedUsers) {
                    await _userService.deleteUser(user.userId);
                    await _userService.deleteAuthUserHttp(user.userId);
                  }
                  _clearSelections();

                  if (!mounted) return;
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('사용자 삭제 완료')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

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
