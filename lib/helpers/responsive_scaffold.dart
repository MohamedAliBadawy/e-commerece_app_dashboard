// widgets/responsive_scaffold.dart
import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final AppBar? appBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;
    final isDesktop = screenWidth >= 1100;

    // Wrap the body with responsive padding and constraints
    Widget responsiveBody = Container(
      child: Container(
        constraints: BoxConstraints(maxWidth: double.infinity),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 0 : (isTablet ? 24 : 0),
        ),
        child: body,
      ),
    );

    // If mobile, wrap content in SingleChildScrollView for better experience
    if (isMobile) {
      responsiveBody = SingleChildScrollView(child: responsiveBody);
    }

    return Scaffold(
      appBar: appBar,
      body: responsiveBody,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
    );
  }
}
