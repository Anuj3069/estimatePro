import 'package:flutter/material.dart';

class AppBottomNav extends StatefulWidget {
  final Function(int) onTap;
  const AppBottomNav({super.key, required this.onTap});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0,-1))]),
      child: BottomNavigationBar(
        currentIndex: _current,
        onTap: (i) {
          setState(() => _current = i);
          widget.onTap(i);
        },
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 26), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.call, size: 26), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard, size: 26), label: 'Offers'),
          BottomNavigationBarItem(icon: Icon(Icons.share, size: 26), label: 'RShare'),
        ],
      ),
    );
  }
}
