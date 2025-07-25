import 'package:ecommerce_app_dashboard/models/category_model.dart';
import 'package:ecommerce_app_dashboard/services/category_service.dart';
import 'package:flutter/material.dart';

class CategoryManagementScreen extends StatefulWidget {
  @override
  _CategoryManagementScreenState createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final CategoryService _categoryService = CategoryService();

  final TextEditingController _searchController = TextEditingController();
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  Set<String> _selectedCategoryIds = {}; // Fixed variable name
  bool _isReorderMode = false; // Add this flag

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    _categoryService.getCategories().listen(
      (categories) {
        print('Loaded categories: ' + categories.length.toString());
        for (var c in categories) {
          print(
            'Category: id=' +
                c.id +
                ', name=' +
                c.name +
                ', order=' +
                c.order.toString(),
          );
        }
        setState(() {
          _categories = categories;
          _filteredCategories = categories; // Initialize filtered list
        });
      },
      onError: (e) {
        print('Error loading categories: ' + e.toString());
      },
    );
  }

  void _filterCategories(String query) {
    // Fixed function name
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories =
            _categories
                .where(
                  (category) =>
                      category.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _toggleCategorySelection(String categoryId) {
    // Fixed function name
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        // Fixed variable name
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  void _clearSelections() {
    setState(() {
      _selectedCategoryIds.clear(); // Fixed variable name
    });
  }

  void _toggleReorderMode() {
    setState(() {
      _isReorderMode = !_isReorderMode;
      if (_isReorderMode) {
        _selectedCategoryIds
            .clear(); // Clear selections when entering reorder mode
        _searchController.clear(); // Clear search
        _filteredCategories = _categories; // Show all categories
      }
    });
  }

  Future<void> _saveOrder() async {
    try {
      await _categoryService.updateCategoryOrder(_filteredCategories);
      setState(() {
        _isReorderMode = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('순서가 저장되었습니다')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  List<Category> get _selectedCategories {
    return _categories
        .where(
          (category) => _selectedCategoryIds.contains(category.id),
        ) // Fixed variable name
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '카테고리 관리',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          MediaQuery.of(context).size.width < 800
              ? Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: _searchController,
                      enabled:
                          !_isReorderMode, // Disable search in reorder mode

                      decoration: InputDecoration(
                        hintText: '검색',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: _filterCategories, // Use the correct function
                    ),
                  ),
                  SizedBox(height: 16),
                  if (!_isReorderMode) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('카테고리 추가'),
                          onPressed: () => _showAddCategoryDialog(context),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: Icon(Icons.reorder),
                          label: Text('순서 변경'),
                          onPressed: _toggleReorderMode,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.save),
                          label: Text('순서 저장'),
                          onPressed: _saveOrder,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            backgroundColor: Colors.green,
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: Icon(Icons.cancel),
                          label: Text('취소'),
                          onPressed: _toggleReorderMode,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            backgroundColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              )
              : Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: TextField(
                        controller: _searchController,
                        enabled:
                            !_isReorderMode, // Disable search in reorder mode

                        decoration: InputDecoration(
                          hintText: '검색',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged:
                            _filterCategories, // Use the correct function
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  if (!_isReorderMode) ...[
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('카테고리 추가'),
                      onPressed: () => _showAddCategoryDialog(context),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: Icon(Icons.reorder),
                      label: Text('순서 변경'),
                      onPressed: _toggleReorderMode,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      label: Text('순서 저장'),
                      onPressed: _saveOrder,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.green,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: Icon(Icons.cancel),
                      label: Text('취소'),
                      onPressed: _toggleReorderMode,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
          SizedBox(height: 24),
          if (!_isReorderMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _selectedCategoryIds.length == 1
                          ? () => _showEditCategoryDialog(
                            context,
                            _selectedCategories.first,
                          )
                          : null,
                  child: Text('수정'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        _selectedCategoryIds.length == 1
                            ? Colors.blue
                            : Colors.grey,
                  ),
                ),
                SizedBox(width: 16),
                TextButton(
                  onPressed:
                      _selectedCategoryIds.isNotEmpty
                          ? () => _deleteSelectedCategories()
                          : null,
                  child: Text('삭제'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        _selectedCategoryIds.isNotEmpty
                            ? Colors.red
                            : Colors.grey,
                  ),
                ),
              ],
            ),
          if (_isReorderMode)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '드래그하여 순서를 변경하세요',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                        _buildTableHeader('카테고리', 3),
                        _buildTableHeader('', 1),
                      ],
                    ),
                  ),
                  // Table body
                  Expanded(
                    child:
                        _isReorderMode
                            ? ReorderableListView.builder(
                              itemCount: _filteredCategories.length,
                              itemBuilder: (context, index) {
                                final category = _filteredCategories[index];
                                return Container(
                                  key: ValueKey(category.id),
                                  child: _buildCategoryRow(category),
                                );
                              },
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) {
                                    newIndex -= 1;
                                  }
                                  final item = _filteredCategories.removeAt(
                                    oldIndex,
                                  );
                                  _filteredCategories.insert(newIndex, item);
                                });
                              },
                            )
                            : ListView.builder(
                              itemCount: _filteredCategories.length,
                              itemBuilder: (context, index) {
                                final category = _filteredCategories[index];
                                return _buildCategoryRow(category);
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

  Widget _buildCategoryRow(Category category) {
    final bool isSelected = _selectedCategoryIds.contains(category.id);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(category.name),
            ),
          ),
          if (!_isReorderMode)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      _toggleCategorySelection(category.id);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String name = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('카테고리 추가'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: '카테고리'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '카테고리명을 입력하세요';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        name = value!;
                      },
                    ),
                  ],
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
                      try {
                        // Create with empty ID - the service will update it
                        Category newCategory = Category(
                          id: '', // Empty ID that will be replaced
                          name: name,
                          order: 0, // This will be updated by the service
                        );
                        await _categoryService.addCategory(newCategory);
                        Navigator.of(context).pop(); // Close dialog after add
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Category added successfully'),
                          ),
                        );
                      } catch (e) {
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

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final _formKey = GlobalKey<FormState>();
    String categoryId = category.id;
    String name = category.name;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Category'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: name,
                      decoration: InputDecoration(labelText: 'Category Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter category name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        name = value!;
                      },
                    ),
                  ],
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
                                Text("Updating category..."),
                              ],
                            ),
                          );
                        },
                      );

                      try {
                        Category updatedCategory = Category(
                          id: categoryId,
                          name: name,
                          order: 0,
                        );

                        await _categoryService.updateCategory(updatedCategory);

                        // Close loading dialog
                        Navigator.of(context).pop();

                        // Close form dialog
                        Navigator.of(context).pop();

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Category updated successfully'),
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

  void _deleteSelectedCategories() {
    if (_selectedCategoryIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text(
            _selectedCategoryIds.length == 1
                ? 'Are you sure you want to delete this category?'
                : 'Are you sure you want to delete ${_selectedCategoryIds.length} categories?',
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
                          Text("Deleting categories..."),
                        ],
                      ),
                    );
                  },
                );

                try {
                  // Delete each selected category
                  for (String categoryId in _selectedCategoryIds) {
                    print(categoryId);

                    await _categoryService.deleteCategory(categoryId);
                  }

                  // Clear selections
                  _clearSelections();

                  // Close loading dialog
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Categories deleted successfully')),
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
