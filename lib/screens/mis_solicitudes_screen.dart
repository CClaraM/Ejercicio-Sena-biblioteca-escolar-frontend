import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MisSolicitudesScreen extends StatefulWidget {
  const MisSolicitudesScreen({super.key});

  @override
  State<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends State<MisSolicitudesScreen> {
  // Paleta marca (igual que las otras pantallas)
  static const Color navy = Color(0xFF0F2A44);
  static const Color navy2 = Color(0xFF163A5F);
  static const Color gold = Color(0xFFC8A24A);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE6EAF2);

  bool loading = true;
  List<Map<String, dynamic>> solicitudes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _norm(String s) => s.trim().toLowerCase();

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getMisSolicitudes();
      if (!mounted) return;
      setState(() {
        solicitudes = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar solicitudes: $e')),
      );
    }
  }

  (Color bg, Color fg, IconData icon, String label) _estadoUI(String estadoRaw) {
    final estado = _norm(estadoRaw);

    // Aprobada / aceptada
    if (estado.contains('aprob') || estado.contains('acept')) {
      return (
        const Color(0xFFE7F6ED),
        const Color(0xFF157F3D),
        Icons.check_circle_outline,
        estadoRaw.isEmpty ? 'aprobada' : estadoRaw
      );
    }

    // Rechazada / denegada
    if (estado.contains('rech') || estado.contains('deneg')) {
      return (
        const Color(0xFFFDE8E8),
        const Color(0xFFB42318),
        Icons.cancel_outlined,
        estadoRaw.isEmpty ? 'rechazada' : estadoRaw
      );
    }

    // Cancelada
    if (estado.contains('cancel')) {
      return (
        const Color(0xFFF3F4F6),
        const Color(0xFF6B7280),
        Icons.remove_circle_outline,
        estadoRaw.isEmpty ? 'cancelada' : estadoRaw
      );
    }

    // Pendiente / default
    return (
      gold.withOpacity(0.20),
      navy,
      Icons.hourglass_bottom_rounded,
      estadoRaw.isEmpty ? 'pendiente' : estadoRaw
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: navy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
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
                child: const Icon(Icons.assignment_outlined, color: navy),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sin solicitudes',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cuando solicites un libro, aparecerá aquí tu historial.',
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

  Widget _estadoBadge(String estadoRaw) {
    final (bgc, fgc, icon, label) = _estadoUI(estadoRaw);

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

  @override
  Widget build(BuildContext context) {
    // Ordena por “más reciente primero” si llega un id o fecha; si no, respeta el orden del backend
    final sorted = [...solicitudes];
    sorted.sort((a, b) {
      final ai = int.tryParse((a['id'] ?? a['id_solicitud'] ?? '').toString()) ?? 0;
      final bi = int.tryParse((b['id'] ?? b['id_solicitud'] ?? '').toString()) ?? 0;
      return bi.compareTo(ai);
    });

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
                'Mis solicitudes',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Estado y seguimiento de tus solicitudes',
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
          : solicitudes.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    children: [
                      _sectionTitle('Historial', 'Tus solicitudes más recientes primero'),
                      const SizedBox(height: 10),
                      ...sorted.map((s) {
                        final titulo = (s['titulo'] ??
                                s['libro'] ??
                                s['libro_titulo'] ??
                                'Sin título')
                            .toString();

                        final fecha = (s['fecha_solicitud'] ??
                                s['fecha'] ??
                                s['created_at'] ??
                                '')
                            .toString();

                        final estado = (s['estado'] ?? 'pendiente').toString();
                        final observ = (s['observacion'] ?? s['observaciones'] ?? '').toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cardBorder),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: navy.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.menu_book_outlined,
                                color: navy,
                              ),
                            ),
                            title: Text(
                              titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: navy,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fecha.isEmpty ? 'Fecha: —' : 'Fecha: $fecha',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  if (observ.trim().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Observación: $observ',
                                      style: const TextStyle(color: Colors.black54, height: 1.2),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            isThreeLine: observ.trim().isNotEmpty,
                            trailing: _estadoBadge(estado),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}