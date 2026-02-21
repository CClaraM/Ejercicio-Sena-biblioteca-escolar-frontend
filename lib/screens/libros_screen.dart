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
  // Colores tipo Figma (azul + dorado)
  static const Color azul = Color(0xFF0B2A4A);
  static const Color dorado = Color(0xFFC8A33A);

  bool loading = true;
  List<Map<String, dynamic>> libros = [];
  String query = "";

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
        SnackBar(content: Text("❌ Error cargando libros: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

    final filtered = libros.where((b) {
      final t = (b["titulo"] ?? "").toString().toLowerCase();
      final a = (b["autor"] ?? "").toString().toLowerCase();
      return t.contains(q) || a.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        title: const Text("LIBROS"),
        actions: [
          IconButton(
            tooltip: "Recargar",
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgregarLibroScreen()),
          ).then((_) => _load());
        },
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Buscar por título o autor",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: filtered.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 120),
                                Center(child: Text("No hay libros para mostrar")),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final b = filtered[i];

                                // id puede venir int o String, lo normalizamos
                                final dynamic rawId = b["id"];
                                final int? id = rawId is int ? rawId : int.tryParse((rawId ?? "").toString());

                                // ✅ PROBAMOS VARIAS CLAVES POSIBLES
                                final portada = (b["portadaUrl"] ??
                                        b["portada_url"] ??
                                        b["portada"] ??
                                        b["cover"] ??
                                        b["coverUrl"] ??
                                        b["cover_url"] ??
                                        b["imageUrl"] ??
                                        b["imagenUrl"] ??
                                        "")
                                    .toString();

                                final titulo = (b["titulo"] ?? "Sin título").toString();
                                final autor = (b["autor"] ?? "Sin autor").toString();
                                final genero = (b["genero"] ?? "General").toString();
                                final anio = (b["anio"] ?? "").toString().trim();
                                final anioText = anio.isEmpty ? "—" : anio;

                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
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
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      leading: _cover(portada),
                                      title: Text(
                                        titulo,
                                        style: const TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                      subtitle: Text(
                                        "Autor: $autor\nGénero: $genero • Año: $anioText",
                                      ),
                                      isThreeLine: true,
                                      trailing: IconButton(
                                        tooltip: "Editar",
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => EditarLibroScreen(libro: b)),
                                          ).then((_) => _load());
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// ✅ Portada: tamaño fijo, placeholder, loading y error
  Widget _cover(String url) {
    final u = url.trim();

    // contenedor fijo para que el leading no “salte”
    Widget box(Widget child) => SizedBox(width: 44, height: 60, child: child);

    if (u.isEmpty) {
      return box(Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black12,
        ),
        child: const Icon(Icons.menu_book),
      ));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: box(
        Image.network(
          u,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              alignment: Alignment.center,
              color: Colors.black12,
              child: const Icon(Icons.broken_image),
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              alignment: Alignment.center,
              color: Colors.black12,
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

  /// ✅ Detalle del libro al tocar la tarjeta
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
      builder: (_) {
        return AlertDialog(
          title: Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (portadaUrl.trim().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      portadaUrl.trim(),
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 220,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 44),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 220,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Icon(Icons.menu_book, size: 48),
                  ),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: Text("Autor: $autor")),
                Align(alignment: Alignment.centerLeft, child: Text("Género: $genero")),
                Align(alignment: Alignment.centerLeft, child: Text("Año: $anio")),
                if (id != null) Align(alignment: Alignment.centerLeft, child: Text("ID: $id")),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CERRAR"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("EDITAR"),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditarLibroScreen(libro: libro)),
                ).then((_) => _load());
              },
            ),
          ],
        );
      },
    );
  }
}
