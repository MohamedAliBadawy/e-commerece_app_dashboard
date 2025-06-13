import 'package:ecommerce_app_dashboard/helpers/responsive_scaffold.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<NavigationItem> _navigationItems = [
    NavigationItem(title: '사용자 관리', icon: Icons.people, mobileTitle: '사용자'),
    NavigationItem(
      title: '배송 관리자 관리',
      icon: Icons.local_shipping,
      mobileTitle: '배송',
    ),
    NavigationItem(
      title: '주문 관리',
      icon: Icons.shopping_cart,
      mobileTitle: '주문',
    ),
    NavigationItem(title: '게시물 관리', icon: Icons.article, mobileTitle: '게시물'),
    NavigationItem(title: '상품 관리', icon: Icons.inventory, mobileTitle: '상품'),
    NavigationItem(title: '카테고리 관리', icon: Icons.category, mobileTitle: '카테고리'),
    NavigationItem(
      title: '플레이스홀더 편집',
      icon: Icons.edit_note,
      mobileTitle: '편집',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650;
    final isTablet = MediaQuery.of(context).size.width < 1100;
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
    if (isMobile) {
      // Mobile Layout with Bottom Navigation
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            _currentSubPage != null
                ? '뒤로'
                : _navigationItems[_selectedIndex].title,
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading:
              _currentSubPage != null
                  ? IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _currentSubPage = null;
                      });
                    },
                  )
                  : IconButton(
                    icon: Icon(Icons.menu),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
        ),
        drawer: _buildMobileDrawer(),
        body: _currentSubPage ?? _pages[_selectedIndex],
      );
    } else {
      return ResponsiveScaffold(
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

  Widget _buildMobileDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Center(
              child: Text(
                '관리자 메뉴',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children:
                  _navigationItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.title),
                      selected: _selectedIndex == index,
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                          _currentSubPage = null;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final String title;
  final IconData icon;
  final String mobileTitle;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.mobileTitle,
  });
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
