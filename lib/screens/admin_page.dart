import 'package:ecommerce_app_dashboard/screens/category_management.dart';
import 'package:ecommerce_app_dashboard/screens/delivery_manager_management.dart';
import 'package:ecommerce_app_dashboard/screens/order_management.dart';
import 'package:ecommerce_app_dashboard/screens/placeholder_editor_screen.dart';
import 'package:ecommerce_app_dashboard/screens/post_management.dart';
import 'package:ecommerce_app_dashboard/screens/user_management.dart';
import 'package:flutter/material.dart';
import 'product_management.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  Widget? _currentSubPage;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      UserManagementScreen(
        onSubPageRequested: (subPage) {
          setState(() {
            _currentSubPage = subPage;
          });
        },
      ),
      DeliveryManagerManagementScreen(),
      OrderManagementScreen(),
      PostManagementScreen(),
      ProductManagementScreen(),
      CategoryManagementScreen(),
      PlaceholderEditorScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('관리자 페이지'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _currentSubPage = null;
            });
          },
        ),
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Color(0xFFF2F2F2),
            child: ListView(
              children: [
                SidebarItem(
                  title: '사용자 관리',
                  isSelected: _selectedIndex == 0,
                  onTap:
                      () => setState(() {
                        _selectedIndex = 0;
                        _currentSubPage = null;
                      }),
                ),
                SidebarItem(
                  title: '배송 관리자 관리',
                  isSelected: _selectedIndex == 1,
                  onTap:
                      () => setState(() {
                        _selectedIndex = 1;
                        _currentSubPage = null;
                      }),
                ),
                SidebarItem(
                  title: '주문 관리',
                  isSelected: _selectedIndex == 2,
                  onTap:
                      () => setState(() {
                        _selectedIndex = 2;
                        _currentSubPage = null;
                      }),
                ),
                SidebarItem(
                  title: '게시물 관리',
                  isSelected: _selectedIndex == 3,
                  onTap:
                      () => setState(() {
                        _selectedIndex = 3;
                        _currentSubPage = null;
                      }),
                ),
                SidebarItem(
                  title: '상품 관리',
                  isSelected: _selectedIndex == 4,
                  onTap:
                      () => setState(() {
                        _selectedIndex = 4;
                        _currentSubPage = null;
                      }),
                ),
                SidebarItem(
                  title: '카테고리 관리',
                  isSelected: _selectedIndex == 5,
                  onTap:
                      () => setState(() {
                        _selectedIndex = 5;
                        _currentSubPage = null;
                      }),
                ),
                SidebarItem(
                  title: '플레이스홀더 편집',
                  isSelected: _selectedIndex == 6,
                  onTap:
                      () => setState(() {
                        _selectedIndex = 6;
                        _currentSubPage = null;
                      }),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(child: _currentSubPage ?? _pages[_selectedIndex]),
        ],
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const SidebarItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        color: isSelected ? Colors.white : Colors.transparent,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
