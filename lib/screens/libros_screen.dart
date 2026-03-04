import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'agregar_libro_screen.dart';
import 'editar_libro_screen.dart';

class LibrosScreen extends StatefulWidget {
  const LibrosScreen({super.key});

  @override
  State<LibrosScreen> createState() => _LibrosScreenState();
}

class _LibrosScreenState extends State<LibrosScreen> {
  bool loading = true;
  List<Map<String, dynamic>> libros = [];
  String query = '';

  // Paleta marca
  static const Color navy = Color(0xFF0F2A44);
  static const Color navy2 = Color(0xFF163A5F);
  static const Color gold = Color(0xFFC8A24A);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE6EAF2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getLibros();
      if (!mounted) return;
      setState(() {
        libros = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando libros: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

    final filtered = libros.where((b) {
      final t = (b['titulo'] ?? '').toString().toLowerCase();
      final a = (b['autor'] ?? '').toString().toLowerCase();
      return t.contains(q) || a.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: bg,

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: gold,
        foregroundColor: navy,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgregarLibroScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Nuevo libro',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 44, 20, 22),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [navy, navy2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Libros',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Catálogo y administración',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        IconButton(
                          tooltip: 'Actualizar',
                          onPressed: _load,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Buscador en card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cardBorder),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: TextField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Buscar por título o autor',
                              border: InputBorder.none,
                            ),
                            onChanged: (v) => setState(() => query = v),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Lista
                        if (filtered.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: navy),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No hay libros para mostrar.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final b = filtered[i];

                              final dynamic rawId = b['id'];
                              final int? id = rawId is int
                                  ? rawId
                                  : int.tryParse((rawId ?? '').toString());

                              final portada = (b['portadaUrl'] ??
                                      b['portada_url'] ??
                                      b['portada'] ??
                                      b['cover'] ??
                                      b['coverUrl'] ??
                                      b['cover_url'] ??
                                      b['imageUrl'] ??
                                      b['imagenUrl'] ??
                                      '')
                                  .toString();

                              final titulo =
                                  (b['titulo'] ?? 'Sin título').toString();
                              final autor =
                                  (b['autor'] ?? 'Sin autor').toString();
                              final genero =
                                  (b['genero'] ?? 'General').toString();
                              final anio =
                                  (b['anio'] ?? '').toString().trim();
                              final anioText = anio.isEmpty ? '-' : anio;

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    _mostrarDetalleLibro(
                                      libro: b,
                                      id: id,
                                      titulo: titulo,
                                      autor: autor,
                                      genero: genero,
                                      anio: anioText,
                                      portadaUrl: portada,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _cover(portada),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                titulo,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: navy,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Autor: $autor',
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Género: $genero • Año: $anioText',
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Editar',
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: navy,
                                          ),
                                          onPressed: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    EditarLibroScreen(libro: b),
                                              ),
                                            );
                                            _load();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _cover(String url) {
    final u = url.trim();

    Widget box(Widget child) => SizedBox(
          width: 46,
          height: 64,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: child,
          ),
        );

    if (u.isEmpty) {
      return box(
        Container(
          alignment: Alignment.center,
          color: gold.withOpacity(0.18),
          child: const Icon(Icons.menu_book, color: navy),
        ),
      );
    }

    return box(
      Image.network(
        u,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            alignment: Alignment.center,
            color: gold.withOpacity(0.18),
            child: const Icon(Icons.broken_image_outlined, color: navy),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            alignment: Alignment.center,
            color: gold.withOpacity(0.18),
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }

  void _mostrarDetalleLibro({
    required Map<String, dynamic> libro,
    required int? id,
    required String titulo,
    required String autor,
    required String genero,
    required String anio,
    required String portadaUrl,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.w900, color: navy),
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (portadaUrl.trim().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      portadaUrl.trim(),
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 220,
                        alignment: Alignment.center,
                        child:
                            const Icon(Icons.broken_image_outlined, size: 44),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 220,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE1E6F0)),
                    ),
                    child: const Icon(Icons.menu_book_outlined, size: 48),
                  ),
                const SizedBox(height: 12),
                Text('Autor: $autor'),
                Text('Género: $genero'),
                Text('Año: $anio'),
                if (id != null) Text('ID: $id'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditarLibroScreen(libro: libro),
                  ),
                );
                _load();
              },
            ),
          ],
        );
      },
    );
  }
}