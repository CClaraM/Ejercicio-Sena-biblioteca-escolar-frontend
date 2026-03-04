import 'package:flutter/material.dart';

import '../services/api_service.dart';

class BookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> libro;
  const BookDetailScreen({super.key, required this.libro});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  // Paleta marca (igual que admin/user)
  static const Color navy = Color(0xFF0F2A44);
  static const Color navy2 = Color(0xFF163A5F);
  static const Color gold = Color(0xFFC8A24A);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE6EAF2);

  bool _loading = true;
  Map<String, dynamic> _detalle = {};
  bool _solicitando = false;

  @override
  void initState() {
    super.initState();
    _loadDetalle();
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '0') ?? 0;
  }

  String _pick(Map<String, dynamic> m, List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final val = m[k];
      if (val != null) {
        final s = val.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return fallback;
  }

  Future<void> _loadDetalle() async {
    setState(() => _loading = true);
    try {
      final rawId =
          widget.libro['id'] ?? widget.libro['id_libro'] ?? widget.libro['idLibro'];
      final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
      if (id == 0) throw Exception('ID inválido');

      final detalle = await ApiService.getLibroDetalle(id);
      if (!mounted) return;
      setState(() {
        _detalle = detalle;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando detalle: $e')),
      );
    }
  }

  Future<void> _solicitar() async {
    final rawId =
        _detalle['id'] ?? _detalle['id_libro'] ?? widget.libro['id'] ?? 0;
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
    if (id == 0) return;

    setState(() => _solicitando = true);
    try {
      final idSolicitud = await ApiService.solicitarLibro(id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Solicitud creada (#$idSolicitud)')),
      );

      await _loadDetalle(); // refresca disponibles
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error solicitando libro: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _solicitando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titulo = _pick(_detalle, ['titulo'], _pick(widget.libro, ['titulo'], 'Sin título'));
    final autor = _pick(_detalle, ['autor'], _pick(widget.libro, ['autor'], 'Sin autor'));
    final genero = _pick(_detalle, ['genero', 'area'], _pick(widget.libro, ['genero'], 'General'));
    final anio = _pick(_detalle, ['anio', 'anio_publicacion'], _pick(widget.libro, ['anio'], ''));
    final portadaRaw = _pick(
      _detalle,
      ['portadaUrl', 'portada_url', 'portada', 'coverUrl', 'cover_url'],
      _pick(widget.libro, ['portadaUrl', 'portada_url', 'portada'], ''),
    ).toString().trim();

    final portada = portadaRaw.isEmpty
        ? ''
        : (portadaRaw.startsWith('http://') || portadaRaw.startsWith('https://'))
            ? portadaRaw
            : '${ApiService.baseUrl}${portadaRaw.startsWith('/') ? '' : '/'}$portadaRaw';

    final descripcion = _pick(
      _detalle,
      ['descripcion', 'sinopsis'],
      _pick(widget.libro, ['descripcion', 'sinopsis'], ''),
    );

    final disponibles = _toInt(
      _detalle['ejemplares_disponibles'] ??
          _detalle['ejemplaresDisponibles'] ??
          _detalle['disponibles'] ??
          0,
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(92),
        child: AppBar(
          toolbarHeight: 92,
          elevation: 0,
          foregroundColor: Colors.white,
          titleSpacing: 8,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                autor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
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
              onPressed: _loadDetalle,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDetalle,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                children: [
                  // Portada
                  _card(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: 260,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: portada.trim().isEmpty
                            ? Container(
                                color: navy.withOpacity(0.08),
                                alignment: Alignment.center,
                                child: const Icon(Icons.menu_book, size: 64, color: navy),
                              )
                            : Image.network(
                                portada.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: navy.withOpacity(0.08),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image_outlined, size: 48, color: navy),
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Título + chips
                  _card(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _chip(Icons.person_outline, autor),
                            _chip(Icons.category_outlined, genero),
                            _chip(Icons.event_outlined, anio.isEmpty ? '—' : anio),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Descripción / sinopsis
                  if (descripcion.trim().isNotEmpty)
                    _card(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sinopsis',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: navy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            descripcion.trim(),
                            style: const TextStyle(color: Colors.black87, height: 1.35),
                          ),
                        ],
                      ),
                    ),

                  if (descripcion.trim().isNotEmpty) const SizedBox(height: 12),

                  // Disponibilidad + botón
                  _card(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: navy.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: navy),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Disponibilidad',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: navy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ejemplares disponibles: $disponibles',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        _badgeDisponibles(disponibles),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (disponibles <= 0 || _solicitando) ? null : _solicitar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: navy,
                        disabledBackgroundColor: Colors.black12,
                        disabledForegroundColor: Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _solicitando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.assignment_outlined),
                      label: Text(
                        disponibles <= 0
                            ? 'No disponible'
                            : (_solicitando ? 'Solicitando...' : 'Solicitar'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: Text(
                      'Desliza hacia abajo para actualizar',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.black45),
                    ),
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

  Widget _chip(IconData icon, String text) {
    final t = text.trim().isEmpty ? '—' : text.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: navy.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: navy.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: navy),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              t,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeDisponibles(int disponibles) {
    final bool ok = disponibles > 0;
    final Color bgColor = ok ? const Color(0xFFE7F6ED) : const Color(0xFFFDE8E8);
    final Color fgColor = ok ? const Color(0xFF157F3D) : const Color(0xFFB42318);
    final String text = ok ? 'Disponible' : 'Agotado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fgColor.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}