import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_dashboard/helpers/responsive_scaffold.dart';
import 'package:ecommerce_app_dashboard/models/chat_room_model.dart';
import 'package:ecommerce_app_dashboard/screens/category_management.dart';
import 'package:ecommerce_app_dashboard/screens/delivery_manager_management.dart';
import 'package:ecommerce_app_dashboard/screens/direct_chats_screen.dart';
import 'package:ecommerce_app_dashboard/screens/order_management.dart';
import 'package:ecommerce_app_dashboard/screens/payment_history_screen.dart';
import 'package:ecommerce_app_dashboard/screens/placeholder_editor_screen.dart';
import 'package:ecommerce_app_dashboard/screens/post_management.dart';
import 'package:ecommerce_app_dashboard/screens/user_management.dart';
import 'package:flutter/material.dart';
import 'product_management.dart';
import 'product_edit_requests_screen.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

Widget buildMessagesIcon() {
  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection('chatRooms')
        .where('participants', arrayContains: "Admin")
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatRoomModel.fromMap(doc.data()))
                  .toList(),
        ),
    builder: (context, snapshot) {
      final currentUserId = "Admin";
      bool hasUnread = false;
      if (snapshot.hasData) {
        final chatRooms = snapshot.data!;
        hasUnread = chatRooms.any(
          (room) => (room.unreadCount[currentUserId] ?? 0) > 0,
        );
      }
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DirectChatsScreen()),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ImageIcon(AssetImage('assets/005 3.png'), size: 24),
            if (hasUnread)
              Positioned(
                left: -10,
                top: -5,
                child: Image.asset(
                  'assets/notification.png',
                  width: 18,
                  height: 18,
                ),
              ),
          ],
        ),
      );
    },
  );
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
    NavigationItem(
      title: '상품 수정 요청',
      icon: Icons.playlist_add_check,
      mobileTitle: '수정요청',
    ),
    NavigationItem(title: '카테고리 관리', icon: Icons.category, mobileTitle: '카테고리'),
    NavigationItem(
      title: '플레이스홀더 편집',
      icon: Icons.edit_note,
      mobileTitle: '편집',
    ),
    NavigationItem(title: '결제 내역', icon: Icons.payment, mobileTitle: '파이머'),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
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
      PostManagementScreen(
        onSubPageRequested: (subPage) {
          setState(() {
            _currentSubPage = subPage;
          });
        },
      ),
      ProductManagementScreen(),
      ProductEditRequestsScreen(),
      CategoryManagementScreen(),
      PlaceholderEditorScreen(),
      PaymentHistoryScreen(),
    ];
    if (isMobile) {
      // Mobile Layout with Bottom Navigation
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Row(
            children: [
              buildMessagesIcon(),
              SizedBox(width: 10),
              Text(
                _currentSubPage != null
                    ? '뒤로'
                    : _navigationItems[_selectedIndex].title,
              ),
            ],
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
          title: Row(
            children: [
              buildMessagesIcon(),
              SizedBox(width: 10),
              Text('관리자 페이지'),
            ],
          ),
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
                    title: '상품 수정 요청',
                    isSelected: _selectedIndex == 5,
                    onTap:
                        () => setState(() {
                          _selectedIndex = 5;
                          _currentSubPage = null;
                        }),
                  ),
                  SidebarItem(
                    title: '카테고리 관리',
                    isSelected: _selectedIndex == 6,
                    onTap:
                        () => setState(() {
                          _selectedIndex = 6;
                          _currentSubPage = null;
                        }),
                  ),
                  SidebarItem(
                    title: '플레이스홀더 편집',
                    isSelected: _selectedIndex == 7,
                    onTap:
                        () => setState(() {
                          _selectedIndex = 7;
                          _currentSubPage = null;
                        }),
                  ),
                  SidebarItem(
                    title: '결제 내역',
                    isSelected: _selectedIndex == 8,
                    onTap:
                        () => setState(() {
                          _selectedIndex = 8;
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
            decoration: BoxDecoration(color: Colors.black),
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
