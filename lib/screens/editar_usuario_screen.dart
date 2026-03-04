import 'package:flutter/material.dart';

import '../services/api_service.dart';

class EditarUsuarioScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const EditarUsuarioScreen({super.key, required this.usuario});

  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {
  // Paleta marca (igual que editar libro)
  static const Color navy = Color(0xFF0F2A44);
  static const Color navy2 = Color(0xFF163A5F);
  static const Color gold = Color(0xFFC8A24A);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE6EAF2);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _correo;
  late final TextEditingController _telefono;

  String _rol = 'estudiante';
  bool _saving = false;

  int? _id;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;

    _nombre = TextEditingController(text: (u['nombre'] ?? '').toString());
    _apellido = TextEditingController(text: (u['apellido'] ?? '').toString());
    _correo = TextEditingController(text: (u['correo'] ?? '').toString());
    _telefono = TextEditingController(text: (u['telefono'] ?? '').toString());
    _rol = (u['rol'] ?? 'estudiante').toString();

    final idRaw = u['id'] ?? u['id_usuario'] ?? u['idUsuario'];
    _id = idRaw is int ? idRaw : int.tryParse((idRaw ?? '').toString());
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _correo.dispose();
    _telefono.dispose();
    super.dispose();
  }

  bool _emailValido(String email) {
    final e = email.trim();
    if (e.isEmpty) return true;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_id == null || _id == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ ID inválido')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ApiService.adminUpdateUsuario(_id!, {
        'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(),
        'correo': _correo.text.trim(),
        'telefono': _telefono.text.trim(),
        'rol': _rol,
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando usuario: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          children: [
            // HEADER (igual que editar libro)
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
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Volver',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Editar usuario',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _id == null ? 'ID inválido' : 'ID: $_id',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // DATOS (card)
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Datos del usuario',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: navy,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),

                              _input(
                                label: 'Nombre',
                                controller: _nombre,
                                required: true,
                              ),
                              const SizedBox(height: 12),

                              _input(
                                label: 'Apellido',
                                controller: _apellido,
                                required: true,
                              ),
                              const SizedBox(height: 12),

                              _input(
                                label: 'Correo (opcional)',
                                controller: _correo,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  final val = (v ?? '').trim();
                                  if (val.isEmpty) return null;
                                  if (!_emailValido(val)) return 'Correo inválido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              _input(
                                label: 'Teléfono (opcional)',
                                controller: _telefono,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),

                              DropdownButtonFormField<String>(
                                value: _rol,
                                decoration: const InputDecoration(labelText: 'Rol'),
                                items: const [
                                  DropdownMenuItem(value: 'estudiante', child: Text('Estudiante')),
                                  DropdownMenuItem(value: 'profesor', child: Text('Profesor')),
                                  DropdownMenuItem(value: 'bibliotecario', child: Text('Bibliotecario')),
                                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                                ],
                                onChanged: _saving
                                    ? null
                                    : (v) => setState(() => _rol = v ?? 'estudiante'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // BOTONES (igual patrón)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving ? null : () => Navigator.pop(context),
                                child: const Text(
                                  'CANCELAR',
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
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text(
                                        'GUARDAR CAMBIOS',
                                        style: TextStyle(fontWeight: FontWeight.w900),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _input({
    required String label,
    required TextEditingController controller,
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (v) {
        if (validator != null) return validator(v);
        if (!required) return null;
        if (v == null || v.trim().isEmpty) return 'Obligatorio';
        return null;
      },
      decoration: InputDecoration(labelText: label),
    );
  }
}