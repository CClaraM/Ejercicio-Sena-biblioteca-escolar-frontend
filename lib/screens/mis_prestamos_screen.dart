import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MisPrestamosScreen extends StatefulWidget {
  const MisPrestamosScreen({super.key});

  @override
  State<MisPrestamosScreen> createState() => _MisPrestamosScreenState();
}

class _MisPrestamosScreenState extends State<MisPrestamosScreen> {
  // Paleta marca (igual que el resto)
  static const Color navy = Color(0xFF0F2A44);
  static const Color navy2 = Color(0xFF163A5F);
  static const Color gold = Color(0xFFC8A24A);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE6EAF2);

  bool loading = true;
  List<Map<String, dynamic>> prestamos = [];

  String filtro = 'todos'; // todos | activos | vencidos | devueltos

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _norm(String s) => s.trim().toLowerCase();

  Future<void> _load() async {
    setState(() => loading = true);
    try {

      final data = await ApiService.getMisPrestamos();
      if (!mounted) return;
      setState(() {
        prestamos = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando préstamos: $e')),
      );
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    // Soporta "2026-03-03" o ISO "2026-02-10T05:00:00.000Z"
    return DateTime.tryParse(s);
  }

  bool _isVencido(Map<String, dynamic> p) {
    final estado = _norm((p['estado'] ?? '').toString());
    if (estado == 'devuelto') return false;
    final fv = _parseDate(p['fecha_vencimiento']);
    if (fv == null) return false;
    final now = DateTime.now();
    return fv.isBefore(DateTime(now.year, now.month, now.day));
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    final local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }

  (Color bg, Color fg, IconData icon, String label) _estadoUI(String estadoRaw, bool vencido) {
    final e = _norm(estadoRaw);

    if (e.contains('devuelt')) {
      return (
        const Color(0xFFE7F6ED),
        const Color(0xFF157F3D),
        Icons.check_circle_outline,
        'Devuelto'
      );
    }

    if (vencido) {
      return (
        const Color(0xFFFDE8E8),
        const Color(0xFFB42318),
        Icons.warning_amber_rounded,
        'Vencido'
      );
    }

    // Activo / default
    return (
      gold.withOpacity(0.20),
      navy,
      Icons.bookmark_added_outlined,
      e.isEmpty ? 'Activo' : estadoRaw
    );
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> list) {
    final out = <Map<String, dynamic>>[];
    for (final p in list) {
      final estado = _norm((p['estado'] ?? '').toString());
      final vencido = _isVencido(p);

      if (filtro == 'todos') out.add(p);
      else if (filtro == 'devueltos' && estado == 'devuelto') out.add(p);
      else if (filtro == 'vencidos' && vencido) out.add(p);
      else if (filtro == 'activos' && estado != 'devuelto' && !vencido) out.add(p);
    }

    // más reciente primero
    out.sort((a, b) {
      final ad = _parseDate(a['fecha_prestamo']);
      final bd = _parseDate(b['fecha_prestamo']);
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    return out;
  }

  Widget _estadoBadge(String estadoRaw, bool vencido) {
    final (bgc, fgc, icon, label) = _estadoUI(estadoRaw, vencido);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgc,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fgc.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fgc),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fgc,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bookmark_outline, color: navy),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sin préstamos',
                      style: TextStyle(fontWeight: FontWeight.w900, color: navy),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cuando te presten libros, los verás aquí con su estado y fechas.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilter(prestamos);

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
                'Mis préstamos',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
              ),
              SizedBox(height: 2),
              Text(
                'Activos, vencidos y devueltos',
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
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    children: [
                      // Filtros
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tune, color: navy),
                            const SizedBox(width: 10),
                            const Text(
                              'Filtrar:',
                              style: TextStyle(fontWeight: FontWeight.w900, color: navy),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: filtro,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                                    DropdownMenuItem(value: 'activos', child: Text('Activos')),
                                    DropdownMenuItem(value: 'vencidos', child: Text('Vencidos')),
                                    DropdownMenuItem(value: 'devueltos', child: Text('Devueltos')),
                                  ],
                                  onChanged: (v) => setState(() => filtro = v ?? 'todos'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Lista
                      ...filtered.map((p) {
                        final titulo = (p['titulo'] ?? 'Libro').toString();
                        final autor = (p['autor'] ?? '—').toString();
                        final inv = (p['codigo_inventario'] ?? '—').toString();
                        final estadoRaw = (p['estado'] ?? '').toString();

                        final fPrestamo = _fmtDate(_parseDate(p['fecha_prestamo']));
                        final fVence = _fmtDate(_parseDate(p['fecha_vencimiento']));
                        final fDevuelto = _fmtDate(_parseDate(p['fecha_devolucion'])); // solo si existe
                        final vencido = _isVencido(p);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cardBorder),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: navy.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.menu_book_outlined, color: navy),
                            ),
                            title: Text(
                              titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: navy),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Autor: $autor', style: const TextStyle(color: Colors.black54)),
                                  const SizedBox(height: 4),
                                  Text('Inventario: $inv', style: const TextStyle(color: Colors.black54)),
                                  const SizedBox(height: 6),
                                  Text('Préstamo: $fPrestamo', style: const TextStyle(color: Colors.black54)),
                                  Text(
                                    vencido ? 'Venció: $fVence' : 'Vence: $fVence',
                                    style: TextStyle(
                                      color: vencido ? const Color(0xFFB42318) : Colors.black54,
                                      fontWeight: vencido ? FontWeight.w800 : FontWeight.w400,
                                    ),
                                  ),

                                  // Si ya fue devuelto, muestra fecha real de devolución
                                  if (_norm((p['estado'] ?? '').toString()) == 'devuelto' &&
                                      fDevuelto != '—')
                                    Text(
                                      'Devuelto: $fDevuelto',
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                ],
                              ),
                            ),
                            isThreeLine: true,
                            trailing: _estadoBadge(estadoRaw, vencido),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}