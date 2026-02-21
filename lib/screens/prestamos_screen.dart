import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PrestamosScreen extends StatefulWidget {
  const PrestamosScreen({super.key});

  @override
  State<PrestamosScreen> createState() => _PrestamosScreenState();
}

class _PrestamosScreenState extends State<PrestamosScreen> {
  bool loading = true;
  List<Map<String, dynamic>> prestamos = [];
  String query = "";

  String filtro = "activos"; // activos | devueltos | vencidos

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);

    try {
      if (filtro == "devueltos") {
        prestamos = await ApiService.getPrestamos(estado: "devuelto", soloVencidos: false);
      } else if (filtro == "vencidos") {
        prestamos = await ApiService.getPrestamos(estado: "activo", soloVencidos: true);
      } else {
        prestamos = await ApiService.getPrestamos(estado: "activo", soloVencidos: false);
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
      builder: (_) => AlertDialog(
        title: const Text("Registrar devolución"),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Guardar")),
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
    final q = query.toLowerCase();

    final filtered = prestamos.where((p) {
      final usuario = (p["documento"] ?? p["usuario"] ?? p["nombre"] ?? "").toString().toLowerCase();
      final libro = (p["titulo"] ?? p["libro"] ?? "").toString().toLowerCase();
      final inv = (p["codigo_inventario"] ?? p["codigoInventario"] ?? "").toString().toLowerCase();
      return usuario.contains(q) || libro.contains(q) || inv.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("PRÉSTAMOS"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: filtro,
                items: const [
                  DropdownMenuItem(value: "activos", child: Text("Activos")),
                  DropdownMenuItem(value: "devueltos", child: Text("Devueltos")),
                  DropdownMenuItem(value: "vencidos", child: Text("Vencidos")),
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Buscar por título, usuario o inventario",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final p = filtered[i];

                        final int idPrestamo = (p["id_prestamo"] ?? p["id"] ?? 0) is int
                            ? (p["id_prestamo"] ?? p["id"] ?? 0)
                            : int.tryParse((p["id_prestamo"] ?? p["id"] ?? "0").toString()) ?? 0;

                        final titulo = (p["titulo"] ?? p["libro"] ?? "Libro").toString();
                        final usuario = (p["documento"] ?? p["usuario"] ?? "—").toString();
                        final estado = (p["estado"] ?? "").toString().toLowerCase();
                        final activo = estado == "activo";

                        final vencimiento = (p["fecha_vencimiento"] ?? "").toString();
                        final devolucion = (p["fecha_devolucion"] ?? "").toString();
                        final inventario = (p["codigo_inventario"] ?? "").toString();

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.menu_book),
                            title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(
                              "Usuario: $usuario"
                              "${inventario.isNotEmpty ? " • Inv: $inventario" : ""}"
                              "${vencimiento.isNotEmpty ? "\nVence: $vencimiento" : ""}"
                              "${devolucion.isNotEmpty ? "\nDevuelto: $devolucion" : ""}",
                            ),
                            isThreeLine: true,
                            trailing: activo
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: idPrestamo == 0 ? null : () => _devolver(idPrestamo),
                                    child: const Text("DEVOLVER"),
                                  )
                                : Text(
                                    estado,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
