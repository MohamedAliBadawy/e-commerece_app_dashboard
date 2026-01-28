import 'package:flutter/material.dart';

class SubPageButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const SubPageButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label, style: TextStyle(color: Colors.black)),
    );
  }
}
