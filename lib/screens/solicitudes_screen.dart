import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  // Paleta marca
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

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getSolicitudesPendientes();
      if (!mounted) return;
      setState(() {
        solicitudes = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cargando solicitudes: $e")),
      );
    }
  }

  Future<void> _aprobar(int id) async {
    try {
      await ApiService.aprobarSolicitud(id, diasPrestamo: 10);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Solicitud aprobada")),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error aprobando: $e")),
      );
    }
  }

  Future<void> _rechazar(int id) async {
    try {
      await ApiService.rechazarSolicitud(id, observacion: "No disponible");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Solicitud rechazada")),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error rechazando: $e")),
      );
    }
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? "0") ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [navy, navy2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      tooltip: 'Volver',
                    ),
                  if (Navigator.canPop(context)) const SizedBox(width: 6),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solicitudes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Aprobación y rechazo de solicitudes',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
            ),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (solicitudes.isEmpty)
                            _emptyState()
                          else
                            ...solicitudes.map((s) {
                              final int id = _toInt(s["id_solicitud"] ?? s["id"]);
                              final String titulo = (s["titulo"] ??
                                      s["libro"] ??
                                      s["libro_titulo"] ??
                                      "Libro")
                                  .toString();
                              final String usuario =
                                  (s["documento"] ?? s["usuario"] ?? s["nombre"] ?? "—")
                                      .toString();
                              final String estado =
                                  (s["estado"] ?? "pendiente").toString().toLowerCase();
                              final String fecha =
                                  (s["fecha_solicitud"] ?? s["fecha"] ?? "").toString();

                              return _solicitudCard(
                                id: id,
                                titulo: titulo,
                                usuario: usuario,
                                fecha: fecha,
                                estado: estado,
                              );
                            }),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _solicitudCard({
    required int id,
    required String titulo,
    required String usuario,
    required String fecha,
    required String estado,
  }) {
    final isPendiente = estado.contains('pend');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.description_outlined, color: navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: navy,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              _estadoBadge(estado),
            ],
          ),
          const SizedBox(height: 10),

          _infoRow('Usuario', usuario),
          _infoRow('Fecha', fecha.trim().isEmpty ? '—' : fecha),

          if (isPendiente) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: id == 0 ? null : () => _rechazar(id),
                    child: const Text(
                      'RECHAZAR',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: navy,
                    ),
                    onPressed: id == 0 ? null : () => _aprobar(id),
                    child: const Text(
                      'APROBAR',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: navy,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoBadge(String estado) {
    Color bgColor = gold.withOpacity(0.20);
    Color fgColor = navy;

    if (estado.contains('aprob') || estado.contains('acept')) {
      bgColor = const Color(0xFFE7F6ED);
      fgColor = const Color(0xFF157F3D);
    } else if (estado.contains('rech') || estado.contains('deneg')) {
      bgColor = const Color(0xFFFDE8E8);
      fgColor = const Color(0xFFB42318);
    } else if (estado.contains('pend')) {
      bgColor = gold.withOpacity(0.20);
      fgColor = navy;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fgColor.withOpacity(0.18)),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: navy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.inbox_outlined, color: navy),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sin solicitudes pendientes',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Cuando existan solicitudes, aparecerán aquí.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}