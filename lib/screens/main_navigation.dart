import 'package:flutter/material.dart';

import 'admin_home.dart';
import 'libros_screen.dart';
import 'usuarios_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;

  static const pages = [
    AdminHome(),
    LibrosScreen(),
    UsuariosScreen(),
  ];

  // Paleta marca
  static const Color navy = Color(0xFF0F2A44);
  static const Color gold = Color(0xFFC8A24A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],

      // Barra inferior estilo mockup
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navy,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => setState(() => index = i),

            backgroundColor: navy,
            type: BottomNavigationBarType.fixed,
            elevation: 0,

            selectedItemColor: gold,
            unselectedItemColor: Colors.white70,

            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),

            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Admin',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book),
                label: 'Libros',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Usuarios',
              ),
            ],
          ),
        ),
      ),
    );
  }
}