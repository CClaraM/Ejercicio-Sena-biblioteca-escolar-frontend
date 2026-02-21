import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
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
      appBar: AppBar(title: const Text("SOLICITUDES")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: solicitudes.length,
              itemBuilder: (_, i) {
                final s = solicitudes[i];

                final int id = _toInt(s["id_solicitud"] ?? s["id"]);
                final String titulo = (s["titulo"] ?? s["libro"] ?? s["libro_titulo"] ?? "Libro").toString();
                final String usuario = (s["documento"] ?? s["usuario"] ?? s["nombre"] ?? "—").toString();
                final String estado = (s["estado"] ?? "pendiente").toString().toLowerCase();
                final String fecha = (s["fecha_solicitud"] ?? s["fecha"] ?? "").toString();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("TÍTULO: $titulo", style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text("USUARIO: $usuario"),
                              const SizedBox(height: 4),
                              Text(fecha.isEmpty ? "Fecha: —" : "Fecha: $fecha"),
                            ],
                          ),
                        ),
                        if (estado == "pendiente")
                          Column(
                            children: [
                              SizedBox(
                                height: 30,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: id == 0 ? null : () => _aprobar(id),
                                  child: const Text("ACEPTAR"),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 30,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                                  onPressed: id == 0 ? null : () => _rechazar(id),
                                  child: const Text("RECHAZAR"),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(estado, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
