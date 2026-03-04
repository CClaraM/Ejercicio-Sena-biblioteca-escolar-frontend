import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AgregarUsuarioScreen extends StatefulWidget {
  const AgregarUsuarioScreen({super.key});

  @override
  State<AgregarUsuarioScreen> createState() => _AgregarUsuarioScreenState();
}

class _AgregarUsuarioScreenState extends State<AgregarUsuarioScreen> {
  // Paleta marca
  static const Color navy = Color(0xFF0F2A44);
  static const Color navy2 = Color(0xFF163A5F);
  static const Color gold = Color(0xFFC8A24A);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE6EAF2);

  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _documentoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  String genero = "Femenino";
  String tipoUsuario = "estudiante";

  bool _showPass = false;
  bool _showPass2 = false;
  bool _saving = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _documentoCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  bool _emailValido(String email) {
    final e = email.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  void _limpiar() {
    _nombreCtrl.clear();
    _apellidoCtrl.clear();
    _documentoCtrl.clear();
    _telefonoCtrl.clear();
    _correoCtrl.clear();
    _passCtrl.clear();
    _pass2Ctrl.clear();
    setState(() {
      genero = "Femenino";
      tipoUsuario = "estudiante";
      _showPass = false;
      _showPass2 = false;
    });
  }

  Future<void> _guardarUsuario() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await ApiService.agregarUsuario({
        "nombre": _nombreCtrl.text.trim(),
        "apellido": _apellidoCtrl.text.trim(),
        "documento": _documentoCtrl.text.trim(),
        "telefono": _telefonoCtrl.text.trim(),
        "correo": _correoCtrl.text.trim(),
        "rol": tipoUsuario,
        "contrasena": _passCtrl.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Usuario guardado")),
      );

      _limpiar();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error guardando usuario: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _importarExcel() async {
    if (_saving) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["xlsx"],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      final name = file.name;

      if (bytes == null) {
        throw Exception("No se pudieron leer los bytes del archivo");
      }

      // 10MB
      if (bytes.length > 10 * 1024 * 1024) {
        throw Exception("El archivo supera 10MB");
      }

      setState(() => _saving = true);

      final inserted = await ApiService.importarUsuariosExcel(bytes, name);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Importados $inserted usuarios desde Excel")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error importando Excel: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
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
                children: [
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Volver',
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Añadir usuario',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Registro manual o importación por Excel',
                          style: TextStyle(color: Colors.white70),
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
                        // IMPORTAR
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Importar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: navy,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: _saving ? null : _importarExcel,
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text(
                                    "IMPORTAR DESDE ARCHIVO (XLSX)",
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tip: El archivo debe ser .xlsx y máximo 10MB.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // DATOS PERSONALES
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
                                label: "Nombre",
                                controller: _nombreCtrl,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? "Obligatorio"
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              _input(
                                label: "Apellido",
                                controller: _apellidoCtrl,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? "Obligatorio"
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              _input(
                                label: "Documento",
                                controller: _documentoCtrl,
                                keyboardType: TextInputType.text,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? "Obligatorio"
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              _input(
                                label: "Teléfono (opcional)",
                                controller: _telefonoCtrl,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),

                              DropdownButtonFormField<String>(
                                value: genero,
                                decoration: const InputDecoration(labelText: "Género"),
                                items: const [
                                  DropdownMenuItem(value: "Femenino", child: Text("Femenino")),
                                  DropdownMenuItem(value: "Masculino", child: Text("Masculino")),
                                  DropdownMenuItem(value: "Otro", child: Text("Otro")),
                                ],
                                onChanged: _saving ? null : (v) => setState(() => genero = v ?? "Femenino"),
                              ),
                              const SizedBox(height: 12),

                              _input(
                                label: "Correo Electrónico",
                                controller: _correoCtrl,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return "Obligatorio";
                                  if (!_emailValido(v)) return "Correo inválido";
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // SEGURIDAD + ROL
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Seguridad y rol',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: navy,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _passCtrl,
                                obscureText: !_showPass,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return "Obligatorio";
                                  if (v.length < 4) return "Mínimo 4 caracteres";
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: "Contraseña",
                                  suffixIcon: IconButton(
                                    onPressed: _saving
                                        ? null
                                        : () => setState(() => _showPass = !_showPass),
                                    icon: Icon(
                                      _showPass ? Icons.visibility_off : Icons.visibility,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _pass2Ctrl,
                                obscureText: !_showPass2,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return "Obligatorio";
                                  if (v != _passCtrl.text) return "No coincide";
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: "Confirmar contraseña",
                                  suffixIcon: IconButton(
                                    onPressed: _saving
                                        ? null
                                        : () => setState(() => _showPass2 = !_showPass2),
                                    icon: Icon(
                                      _showPass2 ? Icons.visibility_off : Icons.visibility,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              DropdownButtonFormField<String>(
                                value: tipoUsuario,
                                decoration: const InputDecoration(labelText: "Rol"),
                                items: const [
                                  DropdownMenuItem(value: "estudiante", child: Text("Estudiante")),
                                  DropdownMenuItem(value: "profesor", child: Text("Profesor")),
                                  DropdownMenuItem(value: "bibliotecario", child: Text("Bibliotecario")),
                                  DropdownMenuItem(value: "admin", child: Text("Administrador")),
                                ],
                                onChanged: _saving
                                    ? null
                                    : (v) => setState(() => tipoUsuario = v ?? "estudiante"),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // BOTONES
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving ? null : () => Navigator.pop(context),
                                child: const Text(
                                  "CANCELAR",
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
                                onPressed: _saving ? null : _guardarUsuario,
                                child: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text(
                                        "GUARDAR",
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
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }
}