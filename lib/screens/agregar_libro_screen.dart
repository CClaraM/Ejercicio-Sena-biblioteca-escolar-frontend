import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AgregarLibroScreen extends StatefulWidget {
  const AgregarLibroScreen({super.key});

  @override
  State<AgregarLibroScreen> createState() => _AgregarLibroScreenState();
}

class _AgregarLibroScreenState extends State<AgregarLibroScreen> {
  static const Color azul = Color(0xFF0B2A4A);
  static const Color dorado = Color(0xFFC8A33A);

  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _autorCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();
  final _isbnCtrl = TextEditingController();
  final _ejemplares = TextEditingController(); // ✅ URL portada

  String genero = "General";
  bool _guardando = false;

  List<int>? _portadaBytes;
  String? _portadaFilename;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _autorCtrl.dispose();
    _anioCtrl.dispose();
    _isbnCtrl.dispose();
    _ejemplares.dispose();
    super.dispose();
  }

  Future<void> _seleccionarPortada() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["jpg", "jpeg", "png", "webp"],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) throw Exception("No se pudo leer la imagen");

      setState(() {
        _portadaBytes = bytes;
        _portadaFilename = file.name;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Portada seleccionada: ${file.name}")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error seleccionando portada: $e")),
      );
    }
  }
  
  Future<void> _guardarLibro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final int idLibro = await ApiService.agregarLibro({
        "titulo": _tituloCtrl.text.trim(),
        "autor": _autorCtrl.text.trim(),
        "anio": _anioCtrl.text.trim(),
        "genero": genero,
        "isbn": _isbnCtrl.text.trim(),
        "ejemplares": _ejemplares.text.trim(),
      });

      // subir portada si existe
      if (_portadaBytes != null && _portadaFilename != null) {
        await ApiService.uploadPortada(
          idLibro,
          _portadaBytes!,
          _portadaFilename!,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Libro guardado")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  
  // ✅ Importar desde Excel (.xlsx)

  Future<void> _importarExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) throw Exception("No se pudo leer el archivo.");

      // ✅ 10 MB
      if (bytes.length > 10 * 1024 * 1024) {
        throw Exception("El archivo supera 10MB.");
      }

      final inserted = await ApiService.importarLibrosExcel(bytes, file.name);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Libros importados desde Excel: $inserted")),
      );

      // vuelve a la pantalla anterior para refrescar lista
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
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
        title: const Text("AÑADIR LIBRO"),
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
                  SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: dorado),
                        foregroundColor: azul,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _guardando ? null : _importarExcel,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("IMPORTAR DESDE ARCHIVO (XLSX)"),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _input(
                    label: "Título",
                    controller: _tituloCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Obligatorio" : null,
                  ),
                  const SizedBox(height: 12),

                  _input(
                    label: "Autor",
                    controller: _autorCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Obligatorio" : null,
                  ),
                  const SizedBox(height: 12),

                  _input(
                    label: "Año (opcional)",
                    controller: _anioCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v.trim());
                      if (n == null) return "Año inválido";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: genero,
                    decoration: const InputDecoration(
                      labelText: "Género",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "General", child: Text("General")),
                      DropdownMenuItem(value: "Literatura", child: Text("Literatura")),
                      DropdownMenuItem(value: "Ciencia", child: Text("Ciencia")),
                      DropdownMenuItem(value: "Matemáticas", child: Text("Matemáticas")),
                      DropdownMenuItem(value: "Historia", child: Text("Historia")),
                      DropdownMenuItem(value: "Programación", child: Text("Programación")),
                      DropdownMenuItem(value: "Bases de Datos", child: Text("Bases de Datos")),
                      DropdownMenuItem(value: "Física", child: Text("Física")),
                      DropdownMenuItem(value: "Química", child: Text("Química")),
                      DropdownMenuItem(value: "Biología", child: Text("Biología")),
                      DropdownMenuItem(value: "Sistemas", child: Text("Sistemas")),
                      DropdownMenuItem(value: "Desarrollo Móvil", child: Text("Desarrollo Móvil")),
                      DropdownMenuItem(value: "Inteligencia Artificial", child: Text("Inteligencia Artificial")),
                      DropdownMenuItem(value: "Redes", child: Text("Redes")),
                      DropdownMenuItem(value: "Electrónica", child: Text("Electrónica"))
                    ],
                    onChanged: _guardando ? null : (v) => setState(() => genero = v ?? "General"),
                  ),
                  const SizedBox(height: 12),

                  _input(
                    label: "ISBN",
                    controller: _isbnCtrl,
                  ),
                  const SizedBox(height: 12),

                  _input(
                    label: "Ejemplares",
                    controller: _ejemplares,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _seleccionarPortada,
                      child: const Text("AGREGAR PORTADA")
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ BOTONES: CANCELAR + GUARDAR
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            side: const BorderSide(color: dorado),
                            foregroundColor: azul,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: _guardando ? null : () => Navigator.pop(context),
                          child: const Text(
                            "CANCELAR",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            backgroundColor: dorado,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: _guardando ? null : _guardarLibro,
                          child: Text(
                            _guardando ? "GUARDANDO..." : "GUARDAR",
                            style: const TextStyle(fontWeight: FontWeight.w800),
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
