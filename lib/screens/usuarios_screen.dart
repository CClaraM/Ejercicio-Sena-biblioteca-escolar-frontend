import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'agregar_usuario_screen.dart';
// import 'editar_usuario_screen.dart'; // ✅ cuando lo crees, descomenta

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  static const Color azul = Color(0xFF0B2A4A);

  bool loading = true;
  String query = "";
  List<Map<String, dynamic>> usuarios = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load(); // trae todos
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({String q = ""}) async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getUsuarios(q: q);
      if (!mounted) return;
      setState(() {
        usuarios = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error cargando usuarios: $e")),
      );
    }
  }

  void _onSearchChanged(String v) {
    setState(() => query = v);

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _load(q: query.trim());
    });
  }

  void _showUserModal(Map<String, dynamic> u) {
    final nombre = (u["nombre"] ?? "").toString();
    final apellido = (u["apellido"] ?? "").toString();
    final documento = (u["documento"] ?? "").toString();
    final telefono = (u["telefono"] ?? "").toString();
    final correo = (u["correo"] ?? "").toString();
    final rol = (u["rol"] ?? "").toString();

    final canEdit = (ApiService.rol == "admin");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$nombre $apellido",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text("Documento: $documento"),
              Text("Rol: $rol"),
              Text("Cell: $telefono"),
              Text("Correo: $correo"),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CERRAR"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !canEdit
                          ? null
                          : () async {
                              Navigator.pop(context);

                              // ✅ Cuando tengas EditarUsuarioScreen, conecta aquí:
                              // await Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (_) => EditarUsuarioScreen(usuario: u),
                              //   ),
                              // );
                              // _load(q: query.trim());

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Editar: pendiente de implementar")),
                              );
                            },
                      child: const Text("EDITAR"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ordenar alfabéticamente: apellido, luego nombre
    final sorted = [...usuarios]..sort((a, b) {
        final apA = (a["apellido"] ?? "").toString().toLowerCase();
        final apB = (b["apellido"] ?? "").toString().toLowerCase();
        final cmpAp = apA.compareTo(apB);
        if (cmpAp != 0) return cmpAp;

        final nomA = (a["nombre"] ?? "").toString().toLowerCase();
        final nomB = (b["nombre"] ?? "").toString().toLowerCase();
        return nomA.compareTo(nomB);
      });

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      appBar: AppBar(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        title: const Text("USUARIOS"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(q: query.trim()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgregarUsuarioScreen()),
          );
          _load(q: query.trim());
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
                      hintText: "Buscar por nombre, documento o rol",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: sorted.isEmpty
                        ? const Center(child: Text("No hay usuarios para mostrar"))
                        : ListView.builder(
                            itemCount: sorted.length,
                            itemBuilder: (_, i) {
                              final u = sorted[i];

                              final nombre = (u["nombre"] ?? "").toString();
                              final apellido = (u["apellido"] ?? "").toString();
                              final documento = (u["documento"] ?? "").toString();
                              final rol = (u["rol"] ?? "").toString();

                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(
                                    "$apellido $nombre",
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  subtitle: Text("Doc: $documento • Rol: $rol"),
                                  onTap: () => _showUserModal(u),
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
