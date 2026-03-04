import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'agregar_usuario_screen.dart';
import 'editar_usuario_screen.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  bool loading = true;
  String query = '';
  List<Map<String, dynamic>> usuarios = [];
  Timer? _debounce;

  // Paleta marca
  static const Color navy = Color(0xFF0F2A44);
  static const Color navy2 = Color(0xFF163A5F);
  static const Color gold = Color(0xFFC8A24A);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE6EAF2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({String q = ''}) async {
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
        SnackBar(content: Text('Error cargando usuarios: $e')),
      );
    }
  }

  void _onSearchChanged(String value) {
    setState(() => query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _load(q: query.trim());
    });
  }

  Color _chipBg(String rol) => gold.withOpacity(0.20);
  Color _chipFg(String rol) => navy;

  void _showUserModal(Map<String, dynamic> user) {
    final nombre = (user['nombre'] ?? '').toString();
    final apellido = (user['apellido'] ?? '').toString();
    final documento = (user['documento'] ?? '').toString();
    final telefono = (user['telefono'] ?? '').toString();
    final correo = (user['correo'] ?? '').toString();
    final rol = (user['rol'] ?? '').toString();
    final canEdit = ApiService.rol == 'admin';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_outline, color: navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$nombre $apellido',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _chipBg(rol),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: navy.withOpacity(0.12)),
                      ),
                      child: Text(
                        rol.isEmpty ? 'Sin rol' : rol,
                        style: TextStyle(
                          color: _chipFg(rol),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _infoRow('Documento', documento),
                _infoRow('Celular', telefono.isEmpty ? '-' : telefono),
                _infoRow('Correo', correo.isEmpty ? '-' : correo),
                const SizedBox(height: 6),
              ],
            ),
          ),
          actions: [
            SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: navy,
                ),
                onPressed: !canEdit
                    ? null
                    : () async {
                        Navigator.pop(dialogContext);
                        final updated =
                            await Navigator.of(context, rootNavigator: true).push<bool?>(
                          MaterialPageRoute(
                            builder: (_) => EditarUsuarioScreen(usuario: user),
                          ),
                        );
                        if (updated == true) {
                          _load(q: query.trim());
                        }
                      },
                child: const Text(
                  'Editar',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
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

  @override
  Widget build(BuildContext context) {
    final sorted = [...usuarios]
      ..sort((a, b) {
        final apA = (a['apellido'] ?? '').toString().toLowerCase();
        final apB = (b['apellido'] ?? '').toString().toLowerCase();
        final byLastName = apA.compareTo(apB);
        if (byLastName != 0) return byLastName;
        final nomA = (a['nombre'] ?? '').toString().toLowerCase();
        final nomB = (b['nombre'] ?? '').toString().toLowerCase();
        return nomA.compareTo(nomB);
      });

    return Scaffold(
      backgroundColor: bg,

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: gold,
        foregroundColor: navy,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgregarUsuarioScreen()),
          );
          _load(q: query.trim());
        },
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text(
          'Nuevo usuario',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),

      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => _load(q: query.trim()),
                child: ListView(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Usuarios',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Administración de cuentas y roles',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          IconButton(
                            tooltip: 'Actualizar',
                            onPressed: () => _load(q: query.trim()),
                            icon: const Icon(Icons.refresh, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Search
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: TextField(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Buscar por nombre, documento o rol',
                                border: InputBorder.none,
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (sorted.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cardBorder),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: navy),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No hay usuarios para mostrar.',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sorted.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final u = sorted[i];
                                final nombre = (u['nombre'] ?? '').toString();
                                final apellido = (u['apellido'] ?? '').toString();
                                final documento = (u['documento'] ?? '').toString();
                                final rol = (u['rol'] ?? '').toString();

                                return Container(
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
                                      child: const Icon(Icons.person_outline, color: navy),
                                    ),
                                    title: Text(
                                      '$apellido $nombre',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: navy,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Doc: $documento',
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: gold.withOpacity(0.20),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: navy.withOpacity(0.12)),
                                      ),
                                      child: Text(
                                        rol.isEmpty ? 'Sin rol' : rol,
                                        style: const TextStyle(
                                          color: navy,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    onTap: () => _showUserModal(u),
                                  ),
                                );
                              },
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
}