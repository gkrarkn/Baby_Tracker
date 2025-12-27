import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PageAppBarTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const PageAppBarTitle({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
