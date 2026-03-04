import 'dart:async';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'book_detail_screen.dart';

class CatalogoLibrosScreen extends StatefulWidget {
  const CatalogoLibrosScreen({super.key});

  @override
  State<CatalogoLibrosScreen> createState() => _CatalogoLibrosScreenState();
}

class _CatalogoLibrosScreenState extends State<CatalogoLibrosScreen> {
  // Paleta marca
  static const Color navy = Color(0xFF0F2A44);
  static const Color navy2 = Color(0xFF163A5F);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE6EAF2);

  bool loading = true;
  List<Map<String, dynamic>> libros = [];
  String query = '';
  Timer? _debounce;

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
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando catálogo: $e')),
      );
    }
  }

  void _onSearchChanged(String v) {
    setState(() => query = v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _load(q: query.trim());
    });
  }

  Widget _cover(String url) {
    final u = url.trim();
    Widget box(Widget child) => SizedBox(width: 44, height: 60, child: child);

    if (u.isEmpty) {
      return box(
        Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: navy.withOpacity(0.08),
          ),
          child: const Icon(Icons.menu_book_outlined, color: navy),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: box(
        Image.network(
          u,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            alignment: Alignment.center,
            color: navy.withOpacity(0.08),
            child: const Icon(Icons.broken_image_outlined, color: navy),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              alignment: Alignment.center,
              color: navy.withOpacity(0.08),
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(92),
        child: AppBar(
          toolbarHeight: 92,
          elevation: 0,
          foregroundColor: Colors.white,
          titleSpacing: 16,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catálogo',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
              ),
              SizedBox(height: 2),
              Text(
                'Todos los libros disponibles',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [navy, navy2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed: () => _load(q: query.trim()),
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(q: query.trim()),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            // Search
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por título o autor',
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (libros.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    constraints: const BoxConstraints(maxWidth: 520),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.inbox_outlined, color: navy),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No hay libros para mostrar.',
                            style: TextStyle(fontWeight: FontWeight.w800, color: navy),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...libros.map((b) {
                final titulo = (b['titulo'] ?? 'Sin título').toString();
                final autor = (b['autor'] ?? '—').toString();
                final genero = (b['genero'] ?? b['area'] ?? 'General').toString();
                final anio = (b['anio'] ?? '').toString().trim();
                final portada = (b['portadaUrl'] ?? b['portada_url'] ?? '').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    leading: _cover(portada),
                    title: Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: navy),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Autor: $autor\n$genero${anio.isEmpty ? '' : ' • $anio'}',
                        style: const TextStyle(color: Colors.black54, height: 1.2),
                      ),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BookDetailScreen(libro: b)),
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}