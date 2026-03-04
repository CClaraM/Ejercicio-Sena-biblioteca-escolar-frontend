import 'dart:async';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'book_detail_screen.dart';
import 'catalogo_libros_screen.dart';
import 'login_screen.dart';
import 'mis_solicitudes_screen.dart';
import 'perfil_usuario.dart';
import 'mis_prestamos_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Paleta marca (igual que admin)
  static const Color navy = Color(0xFF0F2A44);
  static const Color navy2 = Color(0xFF163A5F);
  static const Color gold = Color(0xFFC8A24A);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE6EAF2);

  bool loading = true;
  List<Map<String, dynamic>> libros = [];

  Timer? _debounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({String q = ''}) async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getLibros(search: q);
      if (!mounted) return;
      setState(() {
        libros = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar los libros')),
      );
    }
  }

  void _onSearchChanged(String v) {
    _searchQuery = v;
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _load(q: _searchQuery.trim()),
    );
  }

  List<Map<String, dynamic>> _nuevos(List<Map<String, dynamic>> all) {
    final copy = List<Map<String, dynamic>>.from(all);
    copy.sort((a, b) {
      final ai = int.tryParse((a['id'] ?? '').toString()) ?? 0;
      final bi = int.tryParse((b['id'] ?? '').toString()) ?? 0;
      return bi.compareTo(ai);
    });
    return copy.take(10).toList();
  }

  List<Map<String, dynamic>> _recomendados(List<Map<String, dynamic>> all) {
    return all.take(10).toList();
  }

  // ---- Navegaciones
  void _goMisSolicitudes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MisSolicitudesScreen()),
    );
  }

  void _goMisPrestamos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MisPrestamosScreen()),
    );
  }

  void _goPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _goCatalogo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CatalogoLibrosScreen()),
    );
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final recomendados = _recomendados(libros);
    final nuevos = _nuevos(libros);

    final VoidCallback? onMoreRec = recomendados.isEmpty ? null : _goCatalogo;
    final VoidCallback? onMoreNew = nuevos.isEmpty ? null : _goCatalogo;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(q: _searchQuery.trim()),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              _header(),
              const SizedBox(height: 14),

              // BUSCADOR + PERFIL
              Row(
                children: [
                  Expanded(
                    child: _card(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Buscar por título o autor',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: FilledButton.tonal(
                      onPressed: _goPerfil,
                      style: FilledButton.styleFrom(
                        backgroundColor: navy.withOpacity(0.08),
                        foregroundColor: navy,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: navy.withOpacity(0.12)),
                        ),
                      ),
                      child: const Icon(Icons.person_outline),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // RESUMEN
              _card(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu biblioteca hoy',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _miniStat(
                            icon: Icons.menu_book_outlined,
                            title: 'Mis préstamos',
                            subtitle: 'Ver activos',
                            onTap: _goMisPrestamos,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _miniStat(
                            icon: Icons.assignment_outlined,
                            title: 'Mis solicitudes',
                            subtitle: 'Ver historial',
                            onTap: _goMisSolicitudes,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _miniStat(
                            icon: Icons.new_releases_outlined,
                            title: 'Nuevos',
                            subtitle: '${nuevos.length} ingresos',
                            onTap: _goCatalogo,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              _sectionHeader(
                title: 'Recomendados',
                subtitle: 'Seleccionados para ti',
                onMore: onMoreRec,
              ),
              const SizedBox(height: 8),
              loading
                  ? const SizedBox(
                      height: 210,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _horizontalBooks(recomendados),

              const SizedBox(height: 14),

              _sectionHeader(
                title: 'Nuevos',
                subtitle: 'Últimos ingresos',
                onMore: onMoreNew,
              ),
              const SizedBox(height: 8),
              loading
                  ? const SizedBox(
                      height: 210,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _horizontalBooks(nuevos),

              const SizedBox(height: 16),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: navy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _goMisSolicitudes,
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text(
                    'Ver mis solicitudes',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, navy2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_library, color: Colors.white),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biblioteca IER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Explora, solicita y gestiona tus libros',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mis solicitudes',
            onPressed: _goMisSolicitudes,
            icon: const Icon(Icons.history, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => _load(q: _searchQuery.trim()),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Salir',
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    VoidCallback? onMore,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
        if (onMore != null)
          TextButton(
            onPressed: onMore,
            child: const Text(
              'Ver todo',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
      ],
    );
  }

  Widget _horizontalBooks(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return _emptyState('No hay libros disponibles');

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 6),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final b = items[i];
          final portada = (b['portadaUrl'] ?? b['portada_url'] ?? '').toString();
          final titulo = (b['titulo'] ?? 'Sin título').toString();
          final autor = (b['autor'] ?? 'Autor no disponible').toString();

          return SizedBox(
            width: 160,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BookDetailScreen(libro: b)),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: portada.trim().isEmpty
                          ? Container(
                              width: double.infinity,
                              color: navy.withOpacity(0.08),
                              child: const Icon(Icons.menu_book, size: 42, color: navy),
                            )
                          : Image.network(
                              portada,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: navy.withOpacity(0.08),
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image_outlined, color: navy),
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                      child: Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: navy),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: Text(
                        autor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: navy.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: navy.withOpacity(0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: navy),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, color: navy),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: child,
    );
  }

  Widget _emptyState(String text) {
    return Container(
      height: 210,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black54)),
    );
  }
}