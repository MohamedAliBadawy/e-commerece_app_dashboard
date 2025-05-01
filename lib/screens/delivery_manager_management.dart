import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/models/delivery_manager_model.dart';
import 'package:ecommerce_app_dashboard/services/delivery_manager_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
            'Delivery Manager Management',
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
              SizedBox(width: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Add Delivery Manager'),
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
                child: Text('Edit'),
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
                child: Text('Delete'),
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTableHeader('Name', 1),
                        _buildTableHeader('Email', 2),
                        _buildTableHeader('Phone Number', 2),
                        _buildTableHeader('Preferences (KT/Email)', 2),
                        _buildTableHeader('', 1),
                      ],
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
                          return Center(
                            child: Text('No delivery managers available'),
                          );
                        }
                        final deliveryManagers = snapshot.data!.docs;

                        if (deliveryManagers.isEmpty) {
                          return Center(
                            child: Text('No delivery managers found'),
                          );
                        }
                        return ListView.builder(
                          itemCount: deliveryManagers.length,
                          itemBuilder: (context, index) {
                            final deliveryManager =
                                DeliveryManager.fromDocument(
                                  deliveryManagers[index].data()
                                      as Map<String, dynamic>,
                                );
                            return _buildDeliveryManagerRow(deliveryManager);
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
    String preferences = '';

    // Actually show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add New Delivery Manager'),
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
                                decoration: InputDecoration(labelText: 'Name'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter name';
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
                                decoration: InputDecoration(labelText: 'Email'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter email';
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
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter phone number';
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
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Preferences'),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter preferences';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            preferences = value!;
                          },
                        ),
                      ],
                    ),
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
                  child: Text('Save'),
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
                                Text("Saving product..."),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Delivery manager added successfully',
                            ),
                          ),
                        );
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
              title: Text('Edit Product'),
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
                                decoration: InputDecoration(labelText: 'Name'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter name';
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
                                decoration: InputDecoration(labelText: 'Email'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter email';
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
                                decoration: InputDecoration(labelText: 'Phone'),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter phone number';
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
                        TextFormField(
                          initialValue: preferences,
                          decoration: InputDecoration(labelText: 'Preferences'),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter preferences';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            preferences = value!;
                          },
                        ),
                      ],
                    ),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Delivery Manager updated successfully',
                            ),
                          ),
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
  void _deleteSelectedDeliveryManagers() {
    if (_selectedDeliveryManagers.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text(
            _selectedDeliveryManagers.length == 1
                ? 'Are you sure you want to delete this delivery manager?'
                : 'Are you sure you want to delete ${_selectedDeliveryManagers.length} delivery managers?',
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
                          Text("Deleting products..."),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Products deleted successfully')),
                  );
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
