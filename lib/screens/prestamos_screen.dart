import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PrestamosScreen extends StatefulWidget {
  const PrestamosScreen({super.key});

  @override
  State<PrestamosScreen> createState() => _PrestamosScreenState();
}

class _PrestamosScreenState extends State<PrestamosScreen> {
  // Paleta marca
  static const Color navy = Color(0xFF0F2A44);
  static const Color navy2 = Color(0xFF163A5F);
  static const Color gold = Color(0xFFC8A24A);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE6EAF2);

  bool loading = true;
  List<Map<String, dynamic>> prestamos = [];
  String query = "";

  String filtro = "activos"; // activos | devueltos | vencidos

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? "0") ?? 0;
  }

  Future<void> _load() async {
    setState(() => loading = true);

    try {
      if (filtro == "devueltos") {
        prestamos = await ApiService.getPrestamos(
          estado: "devuelto",
          soloVencidos: false,
        );
      } else if (filtro == "vencidos") {
        prestamos = await ApiService.getPrestamos(
          estado: "activo",
          soloVencidos: true,
        );
      } else {
        prestamos = await ApiService.getPrestamos(
          estado: "activo",
          soloVencidos: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cargando préstamos: $e")),
      );
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> _devolver(int idPrestamo) async {
    final obsCtrl = TextEditingController();
    String condicion = "Bueno";

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Registrar devolución",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: condicion,
              items: const [
                DropdownMenuItem(value: "Bueno", child: Text("Bueno")),
                DropdownMenuItem(value: "Regular", child: Text("Regular")),
              ],
              onChanged: (v) => condicion = v ?? "Bueno",
              decoration: const InputDecoration(labelText: "Condición"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: obsCtrl,
              decoration: const InputDecoration(labelText: "Observaciones"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: navy,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              "Guardar",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await ApiService.devolverPrestamo(
          idPrestamo,
          condicion: condicion.toLowerCase(),
          observaciones: obsCtrl.text,
        );
        await _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error devolviendo: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

    final filtered = prestamos.where((p) {
      final usuario = (p["documento"] ?? p["usuario"] ?? p["nombre"] ?? "")
          .toString()
          .toLowerCase();
      final libro =
          (p["titulo"] ?? p["libro"] ?? "").toString().toLowerCase();
      final inv = (p["codigo_inventario"] ??
              p["codigoInventario"] ??
              "")
          .toString()
          .toLowerCase();
      return usuario.contains(q) || libro.contains(q) || inv.contains(q);
    }).toList();

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
                          'Préstamos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Gestión de préstamos y devoluciones',
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
                          // SEARCH + FILTRO
                          _card(
                            child: Column(
                              children: [
                                TextField(
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search),
                                    hintText:
                                        "Buscar por título, usuario o inventario",
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (v) => setState(() => query = v),
                                ),
                                const Divider(height: 14),
                                Row(
                                  children: [
                                    const Icon(Icons.filter_alt_outlined,
                                        color: navy),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Filtro:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: navy,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: filtro,
                                          isExpanded: true,
                                          items: const [
                                            DropdownMenuItem(
                                              value: "activos",
                                              child: Text("Activos"),
                                            ),
                                            DropdownMenuItem(
                                              value: "devueltos",
                                              child: Text("Devueltos"),
                                            ),
                                            DropdownMenuItem(
                                              value: "vencidos",
                                              child: Text("Vencidos"),
                                            ),
                                          ],
                                          onChanged: (v) async {
                                            if (v == null) return;
                                            setState(() => filtro = v);
                                            await _load();
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (filtered.isEmpty) _emptyState() else ...[
                            ...filtered.map((p) {
                              final int idPrestamo = _toInt(
                                p["id_prestamo"] ?? p["id"] ?? 0,
                              );

                              final titulo =
                                  (p["titulo"] ?? p["libro"] ?? "Libro")
                                      .toString();
                              final usuario =
                                  (p["documento"] ?? p["usuario"] ?? "—")
                                      .toString();
                              final estado =
                                  (p["estado"] ?? "").toString().toLowerCase();

                              final vencimiento =
                                  (p["fecha_vencimiento"] ?? "").toString();
                              final devolucion =
                                  (p["fecha_devolucion"] ?? "").toString();
                              final inventario =
                                  (p["codigo_inventario"] ?? "").toString();

                              final activo = estado == "activo";
                              final vencido = filtro == "vencidos" ||
                                  (estado == "activo" &&
                                      (p["vencido"] == true));

                              return _prestamoCard(
                                idPrestamo: idPrestamo,
                                titulo: titulo,
                                usuario: usuario,
                                estado: estado,
                                vencimiento: vencimiento,
                                devolucion: devolucion,
                                inventario: inventario,
                                marcarVencido: vencido,
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prestamoCard({
    required int idPrestamo,
    required String titulo,
    required String usuario,
    required String estado,
    required String vencimiento,
    required String devolucion,
    required String inventario,
    required bool marcarVencido,
  }) {
    final activo = estado == "activo";

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
                child: const Icon(Icons.menu_book_outlined, color: navy),
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
              _estadoBadge(estado, marcarVencido: marcarVencido),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow("Usuario", usuario),
          if (inventario.trim().isNotEmpty) _infoRow("Inv.", inventario),
          if (vencimiento.trim().isNotEmpty) _infoRow("Vence", vencimiento),
          if (devolucion.trim().isNotEmpty) _infoRow("Devuelto", devolucion),

          if (activo) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDE8E8),
                  foregroundColor: const Color(0xFFB42318),
                ),
                onPressed: idPrestamo == 0 ? null : () => _devolver(idPrestamo),
                child: const Text(
                  "REGISTRAR DEVOLUCIÓN",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _estadoBadge(String estado, {required bool marcarVencido}) {
    Color bgColor = gold.withOpacity(0.20);
    Color fgColor = navy;
    String text = estado.isEmpty ? "—" : estado;

    if (estado.contains('devuel')) {
      bgColor = const Color(0xFFE7F6ED);
      fgColor = const Color(0xFF157F3D);
      text = "devuelto";
    } else if (marcarVencido || estado.contains('venc')) {
      bgColor = const Color(0xFFFDE8E8);
      fgColor = const Color(0xFFB42318);
      text = "vencido";
    } else if (estado.contains('activ')) {
      bgColor = gold.withOpacity(0.20);
      fgColor = navy;
      text = "activo";
    }

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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: child,
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
                  'Sin registros',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'No hay préstamos para mostrar con el filtro actual.',
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