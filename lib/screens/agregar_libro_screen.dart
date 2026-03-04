import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AgregarLibroScreen extends StatefulWidget {
  const AgregarLibroScreen({super.key});

  @override
  State<AgregarLibroScreen> createState() => _AgregarLibroScreenState();
}

class _AgregarLibroScreenState extends State<AgregarLibroScreen> {
  // Paleta marca (coherente con todo)
  static const Color navy = Color(0xFF0F2A44);
  static const Color navy2 = Color(0xFF163A5F);
  static const Color gold = Color(0xFFC8A24A);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE6EAF2);

  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _autorCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();
  final _isbnCtrl = TextEditingController();
  final _ejemplaresCtrl = TextEditingController();

  String genero = "General";
  bool _guardando = false;

  Uint8List? _portadaBytes;
  String? _portadaFilename;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _autorCtrl.dispose();
    _anioCtrl.dispose();
    _isbnCtrl.dispose();
    _ejemplaresCtrl.dispose();
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
        "ejemplares": _ejemplaresCtrl.text.trim(),
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
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            children: [
              // HEADER (sin AppBar)
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
                      onPressed: _guardando ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      tooltip: 'Volver',
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Añadir libro',
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
                          // Importar Excel
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
                                    onPressed: _guardando ? null : _importarExcel,
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

                          // Datos del libro
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Datos del libro',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: navy,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                _input(
                                  label: "Título",
                                  controller: _tituloCtrl,
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? "Obligatorio"
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                _input(
                                  label: "Autor",
                                  controller: _autorCtrl,
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? "Obligatorio"
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _input(
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
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _input(
                                        label: "Ejemplares",
                                        controller: _ejemplaresCtrl,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                DropdownButtonFormField<String>(
                                  value: genero,
                                  decoration: const InputDecoration(
                                    labelText: "Género",
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
                                    DropdownMenuItem(value: "Electrónica", child: Text("Electrónica")),
                                  ],
                                  onChanged: _guardando
                                      ? null
                                      : (v) => setState(() => genero = v ?? "General"),
                                ),
                                const SizedBox(height: 12),

                                _input(
                                  label: "ISBN (opcional)",
                                  controller: _isbnCtrl,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Portada
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Portada',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: navy,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Container(
                                      width: 74,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: cardBorder),
                                        color: gold.withOpacity(0.16),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: _portadaBytes == null
                                          ? const Icon(Icons.menu_book, color: navy, size: 34)
                                          : Image.memory(_portadaBytes!, fit: BoxFit.cover),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _portadaFilename == null
                                                ? 'Sin portada seleccionada'
                                                : _portadaFilename!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: navy,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 46,
                                            child: OutlinedButton.icon(
                                              onPressed: _guardando ? null : _seleccionarPortada,
                                              icon: const Icon(Icons.image_outlined),
                                              label: const Text(
                                                "SELECCIONAR PORTADA",
                                                style: TextStyle(fontWeight: FontWeight.w900),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Botones
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _guardando ? null : () => Navigator.pop(context),
                                  child: const Text(
                                    "CANCELAR",
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _guardando ? null : _guardarLibro,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: gold,
                                    foregroundColor: navy,
                                  ),
                                  child: Text(
                                    _guardando ? "GUARDANDO..." : "GUARDAR",
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}