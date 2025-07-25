import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/delivery_manager_model.dart';
import 'package:ecommerce_app_dashboard/services/delivery_manager_service.dart';
import 'package:flutter/material.dart';

class DeliveryManagerManagementScreen extends StatefulWidget {
  const DeliveryManagerManagementScreen({super.key});

  @override
  State<DeliveryManagerManagementScreen> createState() =>
      _DeliveryManagerManagementScreenState();
}

class _DeliveryManagerManagementScreenState
    extends State<DeliveryManagerManagementScreen> {
  final DeliveryManagerService _deliveryManagerService =
      DeliveryManagerService();

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<DeliveryManager> _selectedDeliveryManagers = [];
  Timer? _debounce;
  late final ScrollController _headerScrollController;
  late final ScrollController _bodyScrollController;

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

  Stream<QuerySnapshot> getDeliveryManagersStream(String query) {
    if (query.isEmpty) {
      return FirebaseFirestore.instance
          .collection('deliveryManagers')
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('deliveryManagers')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .snapshots();
    }
  }

  void _selectDeliveryManager(DeliveryManager deliveryManager) {
    setState(() {
      if (!_selectedDeliveryManagers.any(
        (p) => p.userId == deliveryManager.userId,
      )) {
        _selectedDeliveryManagers.add(deliveryManager);
      }
    });
  }

  void _clearSelections() {
    setState(() {
      _selectedDeliveryManagers.clear();
    });
  }

  void _deselectDeliveryManager(DeliveryManager deliveryManager) {
    setState(() {
      _selectedDeliveryManagers.removeWhere(
        (p) => p.userId == deliveryManager.userId,
      );
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
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
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
            '배송 관리자 관리',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
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
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('관리자 추가'),
                onPressed: () => _showAddDeliveryManagerDialog(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    _selectedDeliveryManagers.length == 1
                        ? () => _showEditDeliveryManagerDialog(
                          context,
                          _selectedDeliveryManagers.first,
                        )
                        : null, // Disable if not exactly one product selected
                child: Text('수정'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      _selectedDeliveryManagers.length == 1
                          ? Colors.blue
                          : Colors.grey,
                ),
              ),
              SizedBox(width: 16),
              TextButton(
                onPressed:
                    _selectedDeliveryManagers.isNotEmpty
                        ? () => _deleteSelectedDeliveryManagers()
                        : null, // Disable if no products selected
                child: Text('삭제'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      _selectedDeliveryManagers.isNotEmpty
                          ? Colors.red
                          : Colors.grey,
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
                          _buildTableHeader('이름', 1),
                          _buildTableHeader('이메일', 2),
                          _buildTableHeader('전화번호', 2),
                          _buildTableHeader('카톡/이메일', 2),
                          _buildTableHeader('', 1),
                        ],
                      ),
                    ),
                  ),
                  // Table body
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: getDeliveryManagersStream(_searchQuery),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        // 3. Check for null data
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Center(child: Text('배송 관리자가 없습니다'));
                        }
                        final deliveryManagers = snapshot.data!.docs;

                        if (deliveryManagers.isEmpty) {
                          return Center(child: Text('배송 관리자가 없습니다'));
                        }
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _bodyScrollController,
                          child: SizedBox(
                            width: 1600,
                            child: ListView.builder(
                              itemCount: deliveryManagers.length,
                              itemBuilder: (context, index) {
                                final deliveryManager =
                                    DeliveryManager.fromDocument(
                                      deliveryManagers[index].data()
                                          as Map<String, dynamic>,
                                    );
                                return _buildDeliveryManagerRow(
                                  deliveryManager,
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

  Widget _buildDeliveryManagerRow(DeliveryManager deliveryManager) {
    final bool isSelected = _selectedDeliveryManagers.any(
      (p) => p.userId == deliveryManager.userId,
    );

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : null,

        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(deliveryManager.name),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(deliveryManager.email),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(deliveryManager.phone),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(deliveryManager.preferences),
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
                      _deselectDeliveryManager(deliveryManager);
                    } else {
                      _selectDeliveryManager(deliveryManager);
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

  void _showAddDeliveryManagerDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    String userId = DateTime.now().millisecondsSinceEpoch.toString();
    String name = '';
    String email = '';
    String phone = '';
    String preferences = '카톡';

    // Actually show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('배송 관리자 추가'),
              content: Container(
                width: 600,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(labelText: '이름'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '이름을 입력하세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  name = value!;
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(labelText: '이메일'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '이메일을 입력하세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  email = value!;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(labelText: '전화번호'),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '전화번호를 입력하세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  phone = value!;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        DropdownButton<String>(
                          value: preferences,
                          items:
                              ['카톡', '이메일'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              preferences = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
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
                        // Create product object
                        DeliveryManager newDeliveryManager = DeliveryManager(
                          userId: userId,
                          name: name,
                          email: email,
                          phone: phone,
                          preferences: preferences,
                        );

                        // Save to Firestore
                        await _deliveryManagerService.addDeliveryManager(
                          newDeliveryManager,
                        );

                        // Close loading dialog
                        Navigator.of(context).pop();

                        // Close form dialog
                        Navigator.of(context).pop();

                        // Show success message
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('배송 관리자 추가 성공')));
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

  // Edit Delivery Manager Dialog
  void _showEditDeliveryManagerDialog(
    BuildContext context,
    DeliveryManager deliveryManager,
  ) {
    final _formKey = GlobalKey<FormState>();

    // Initialize with existing product data
    String userId = deliveryManager.userId;
    String name = deliveryManager.name;
    String email = deliveryManager.email;
    String phone = deliveryManager.phone;
    String preferences = deliveryManager.preferences;

    // Actually show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('수정'),
              content: Container(
                width: 600,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: name,
                                decoration: InputDecoration(labelText: '이름'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '이름을 입력하세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  name = value!;
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: email,
                                decoration: InputDecoration(labelText: '이메일'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '이메일을 입력하세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  email = value!;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: phone,
                                decoration: InputDecoration(labelText: '전화번호'),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '전화번호를 입력하세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  phone = value!;
                                },
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),
                        DropdownButton<String>(
                          value: preferences,
                          items:
                              ['카톡', '이메일'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              preferences = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
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
                        DeliveryManager updatedDeliveryManager =
                            DeliveryManager(
                              userId: userId,
                              name: name,
                              email: email,
                              phone: phone,
                              preferences: preferences,
                            );

                        // Update in Firestore
                        await _deliveryManagerService.updateDeliveryManager(
                          updatedDeliveryManager,
                        );

                        // Close loading dialog
                        Navigator.of(context).pop();

                        // Close form dialog
                        Navigator.of(context).pop();

                        // Show success message
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('배송 관리자 수정 성공')));

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
  void _deleteSelectedDeliveryManagers() {
    if (_selectedDeliveryManagers.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('삭제 확인'),
          content: Text(
            _selectedDeliveryManagers.length == 1
                ? '삭제하시겠습니까?'
                : '${_selectedDeliveryManagers.length}명의 배송 관리자를 삭제하시겠습니까?',
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
                  // Delete each selected delivery manager
                  for (DeliveryManager deliveryManager
                      in _selectedDeliveryManagers) {
                    await _deliveryManagerService.deleteDeliveryManager(
                      deliveryManager.userId,
                    );
                  }

                  // Clear selections
                  _clearSelections();

                  // Close loading dialog
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

                  // Show success message
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('배송 관리자 삭제 성공')));
                } catch (e) {
                  // Close loading dialog
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
