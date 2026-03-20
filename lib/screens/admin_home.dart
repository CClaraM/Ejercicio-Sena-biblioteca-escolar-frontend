import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'agregar_usuario_screen.dart';
import 'libros_screen.dart';
import 'login_screen.dart';
import 'prestamos_screen.dart';
import 'solicitudes_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  bool loading = true;
  List<Map<String, dynamic>> ultSolicitudes = [];
  int pendientes = 0;
  int activos = 0;
  int libros = 0;

  // Paleta fija (marca)
  static const Color navy = Color(0xFF0F2A44);
  //static const Color navy2 = Color(0xFF163A5F);
  static const Color gold = Color(0xFFC8A24A);
  //static const Color bg = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE6EAF2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final counts = await ApiService.getDashboardCounts();
      final s = await ApiService.getSolicitudesPendientes();
      if (!mounted) return;
      setState(() {
        pendientes = counts['pendientes'] ?? 0;
        activos = counts['activos'] ?? 0;
        libros = counts['libros'] ?? 0;
        ultSolicitudes = s.take(3).toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando dashboard: $e')),
      );
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFFF4F6FA),
      
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              children: [

                // HEADER SUPERIOR
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 44, 20, 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0F2A44),
                        Color(0xFF163A5F),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Dashboard Administrador",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Gestión de préstamos, libros y solicitudes",
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      )
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [

                      _sectionTitle(context, 'Métricas'),
                      const SizedBox(height: 10),

                      LayoutBuilder(
                        builder: (context, c) {
                          final isWide = c.maxWidth >= 760;

                          final items = [
                            _metricCard(
                              label: 'Préstamos activos',
                              value: activos.toString(),
                              icon: Icons.assignment_turned_in_outlined,
                            ),
                            _metricCard(
                              label: 'Solicitudes pendientes',
                              value: pendientes.toString(),
                              icon: Icons.inbox_outlined,
                            ),
                            _metricCard(
                              label: 'Títulos',
                              value: libros.toString(),
                              icon: Icons.menu_book_outlined,
                            ),
                          ];

                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(child: items[0]),
                                const SizedBox(width: 12),
                                Expanded(child: items[1]),
                                const SizedBox(width: 12),
                                Expanded(child: items[2]),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              items[0],
                              const SizedBox(height: 12),
                              items[1],
                              const SizedBox(height: 12),
                              items[2],
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      _sectionTitle(context, 'Acciones rápidas'),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _actionBtn(
                            'Préstamos',
                            Icons.bookmark_outline,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrestamosScreen(),
                                ),
                              );
                            },
                          ),
                          _actionBtn(
                            'Solicitudes',
                            Icons.how_to_reg_outlined,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SolicitudesScreen(),
                                ),
                              );
                            },
                          ),
                          _actionBtn(
                            'Libros',
                            Icons.library_books_outlined,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LibrosScreen(),
                                ),
                              );
                            },
                          ),
                          _actionBtn(
                            'Añadir usuario',
                            Icons.person_add_alt_1_outlined,
                            () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AgregarUsuarioScreen(),
                                ),
                              );
                              _load();
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      _sectionTitle(context, 'Últimas solicitudes'),
                      const SizedBox(height: 10),

                      if (ultSolicitudes.isEmpty)
                        _emptyState(
                          icon: Icons.inbox_outlined,
                          title: 'Sin solicitudes recientes',
                          subtitle:
                              'Cuando existan solicitudes, aparecerán aquí.',
                        )
                      else
                        ...ultSolicitudes.map((s) {
                          final titulo =
                              (s['titulo'] ?? s['libro'] ?? 'Libro').toString();
                          final usuario =
                              (s['documento'] ?? s['usuario'] ?? '-').toString();
                          final fecha =
                              (s['fecha_solicitud'] ?? s['fecha'] ?? '')
                                  .toString();
                          final estado =
                              (s['estado'] ?? 'pendiente')
                                  .toString()
                                  .toLowerCase();

                          return _solicitudCard(
                            titulo: titulo,
                            usuario: usuario,
                            fecha: fecha,
                            estado: estado,
                          );
                        }),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text(
                            'Cerrar sesión',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w900,
        color: navy,
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String text, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 176,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: navy,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: navy.withOpacity(0.18)),
          ),
        ),
      ),
    );
  }

  Widget _solicitudCard({
    required String titulo,
    required String usuario,
    required String fecha,
    required String estado,
  }) {
    final badge = _estadoBadge(estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: navy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.description_outlined, color: navy),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: navy,
          ),
        ),
        subtitle: Text(
          'Usuario: $usuario\nFecha: $fecha',
          style: const TextStyle(color: Colors.black54, height: 1.25),
        ),
        isThreeLine: true,
        trailing: badge,
      ),
    );
  }

  Widget _estadoBadge(String estado) {
    // Colores simples por estado (sin depender del theme global)
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

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
            child: Icon(icon, color: navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
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
            ),
          ),
        ],
      ),
    );
  }
}