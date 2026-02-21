import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'prestamos_screen.dart';
import 'solicitudes_screen.dart';
import 'libros_screen.dart';
import 'agregar_usuario_screen.dart';
import 'login_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  static const Color azul = Color(0xFF0B2A4A);
  static const Color dorado = Color(0xFFC8A33A);

  bool loading = true;
  List<Map<String, dynamic>> ultSolicitudes = [];
  int pendientes = 0;
  int activos = 0;
  int libros = 0;

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

      setState(() {
        pendientes = counts["pendientes"] ?? 0;
        activos = counts["activos"] ?? 0;
        libros = counts["libros"] ?? 0;

        ultSolicitudes = s.take(3).toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cargando dashboard: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      appBar: AppBar(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(color: Color(0xFFF7F4FB)),
        title: const Text("DASHBOARD ADMINISTRADOR"),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: "Actualizar",
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text("MÉTRICAS IMPORTANTES", style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),

                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metric("PRÉSTAMOS\nACTIVOS", activos.toString(), Icons.assignment_turned_in),
                        _metric("SOLICITUDES\nPENDIENTES", pendientes.toString(), Icons.inbox),
                        _metric("TITULOS\nDISPONIBLES", libros.toString(), Icons.menu_book),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                const Text("ACCIONES RÁPIDAS", style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _actionBtn("Préstamos", Icons.bookmark, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrestamosScreen()));
                    }),
                    _actionBtn("Solicitudes", Icons.how_to_reg, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SolicitudesScreen()));
                    }),
                    _actionBtn("Libros", Icons.library_books, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LibrosScreen()));
                    }),
                    _actionBtn("Añadir usuario", Icons.person_add, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AgregarUsuarioScreen()))
                          .then((_) => _load());
                    }),
                  ],
                ),

                const SizedBox(height: 18),
                const Text("ÚLTIMAS SOLICITUDES", style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),

                ...ultSolicitudes.map((s) {
                  final titulo = (s["titulo"] ?? s["libro"] ?? "Libro").toString();
                  final usuario = (s["documento"] ?? s["usuario"] ?? "—").toString();
                  final fecha = (s["fecha_solicitud"] ?? s["fecha"] ?? "").toString();
                  final estado = (s["estado"] ?? "pendiente").toString();

                  return Card(
                    child: ListTile(
                      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text("Usuario: $usuario • Fecha: $fecha"),
                      trailing: Text(estado, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  );
                }),

                const SizedBox(height: 18),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dorado,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () async {
                      await ApiService.logout();
                      if (!mounted) return;
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: const Text("SALIR", style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                )
              ],
            ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _actionBtn(String text, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 170,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }
}