import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AgregarUsuarioScreen extends StatefulWidget {
  const AgregarUsuarioScreen({super.key});

  @override
  State<AgregarUsuarioScreen> createState() => _AgregarUsuarioScreenState();
}

class _AgregarUsuarioScreenState extends State<AgregarUsuarioScreen> {
  // Colores tipo Figma (azul + dorado)
  static const Color azul = Color(0xFF0B2A4A);
  static const Color dorado = Color(0xFFC8A33A);

  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
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
    _correoCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  bool _emailValido(String email) {
    final e = email.trim();
    // Simple pero más robusto que solo contains("@")
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  void _limpiar() {
    _nombreCtrl.clear();
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

    await ApiService.agregarUsuario({
      "nombre": _nombreCtrl.text.trim(),
      "correo": _correoCtrl.text.trim(),
      "genero": genero,
      "tipo_usuario": tipoUsuario,
      // Nota: password no la guardamos en ApiService porque es front demo.
      // Si quieren, se puede incluir en memoria también.
    });

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Usuario guardado")),
    );

    _limpiar();
    Navigator.pop(context);
  }

  Future<void> _importarExcel() async {
    if (_saving) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["xlsx"],
        withData: true, // ✅ para tener bytes sin depender de path
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      final name = file.name;

      if (bytes == null) {
        throw Exception("No se pudieron leer los bytes del archivo");
      }

      // ✅ Validación 10MB
      if (bytes.length > 10 * 1024 * 1024) {
        throw Exception("El archivo supera 10MB");
      }

      setState(() => _saving = true);

      final inserted = await ApiService.importarUsuariosExcel(bytes, name);

      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Importados $inserted usuarios desde Excel")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error importando Excel: $e")),
      );
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        title: const Text("AÑADIR USUARIO"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // IMPORTAR
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _importarExcel,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("IMPORTAR DESDE ARCHIVO (excel)"),
                  ),
                  const SizedBox(height: 14),

                  _input(
                    label: "Nombre Completo",
                    controller: _nombreCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? "Obligatorio" : null,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: genero,
                    decoration: const InputDecoration(
                      labelText: "Género",
                      border: OutlineInputBorder(),
                    ),
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
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: _saving ? null : () => setState(() => _showPass = !_showPass),
                        icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility),
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
                      labelText: "Confirmar Contraseña",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: _saving ? null : () => setState(() => _showPass2 = !_showPass2),
                        icon: Icon(_showPass2 ? Icons.visibility_off : Icons.visibility),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: tipoUsuario,
                    decoration: const InputDecoration(
                      labelText: "Tipo de usuario",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "estudiante", child: Text("Estudiante")),
                      DropdownMenuItem(value: "profesor", child: Text("Profesor")),
                      DropdownMenuItem(value: "administrativo", child: Text("Administrativo (Bibliotecario)")),
                      DropdownMenuItem(value: "administrador", child: Text("Administrador")),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => tipoUsuario = v ?? "estudiante"),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: _saving ? null : () => Navigator.pop(context),
                            child: const Text("CANCELAR"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dorado,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
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
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
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
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
