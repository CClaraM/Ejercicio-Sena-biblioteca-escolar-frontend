import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class EditarLibroScreen extends StatefulWidget {
  final Map<String, dynamic> libro;
  const EditarLibroScreen({super.key, required this.libro});

  @override
  State<EditarLibroScreen> createState() => _EditarLibroScreenState();
}

class _EditarLibroScreenState extends State<EditarLibroScreen> {
  // Paleta marca
  static const Color navy = Color(0xFF0F2A44);
  static const Color navy2 = Color(0xFF163A5F);
  static const Color gold = Color(0xFFC8A24A);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE6EAF2);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController titulo;
  late final TextEditingController autor;
  late final TextEditingController anio;
  late final TextEditingController isbn;

  late String genero;

  bool _guardando = false;

  Uint8List? _portadaBytes;
  String? _portadaFilename;

  int? _idLibro;

  @override
  void initState() {
    super.initState();

    titulo = TextEditingController(text: (widget.libro["titulo"] ?? "").toString());
    autor = TextEditingController(text: (widget.libro["autor"] ?? "").toString());
    anio = TextEditingController(text: (widget.libro["anio"] ?? "").toString());
    isbn = TextEditingController(text: (widget.libro["isbn"] ?? "").toString());
    genero = (widget.libro["genero"] ?? "General").toString();

    final rawId = widget.libro["id"];
    _idLibro = rawId is int ? rawId : int.tryParse((rawId ?? "").toString());
  }

  @override
  void dispose() {
    titulo.dispose();
    autor.dispose();
    anio.dispose();
    isbn.dispose();
    super.dispose();
  }

  String _getPortadaActual() {
    return (widget.libro['portadaUrl'] ??
            widget.libro['portada_url'] ??
            widget.libro['portada'] ??
            widget.libro['coverUrl'] ??
            widget.libro['cover_url'] ??
            widget.libro['cover'] ??
            '')
        .toString()
        .trim();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idLibro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ ID del libro inválido")),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      await ApiService.editarLibro(_idLibro!, {
        "titulo": titulo.text.trim(),
        "autor": autor.text.trim(),
        "anio": anio.text.trim(),
        "genero": genero,
        "isbn": isbn.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Libro actualizado")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error guardando: $e")),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _seleccionarYSubirPortada() async {
    if (_idLibro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ ID del libro inválido")),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["jpg", "jpeg", "png", "webp"],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception("No se pudieron leer los bytes del archivo");
      }

      setState(() {
        _portadaBytes = bytes;
        _portadaFilename = file.name;
      });

      // Subir portada
      final nuevaUrl = await ApiService.uploadPortada(_idLibro!, bytes, file.name);

      // Actualiza estado local (por si tu UI usa cualquiera de estas keys)
      setState(() {
        widget.libro["portadaUrl"] = nuevaUrl;
        widget.libro["portada_url"] = nuevaUrl;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Portada actualizada")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error subiendo portada: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final portadaActual = _getPortadaActual();

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
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Volver',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Editar libro",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _idLibro == null ? "ID inválido" : "ID: $_idLibro",
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
                        // Datos
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

                              _input("Título", titulo, required: true),
                              const SizedBox(height: 12),
                              _input("Autor", autor, required: true),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: _input(
                                      "Año (opcional)",
                                      anio,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _input(
                                      "ISBN (opcional)",
                                      isbn,
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
                                onChanged: _guardando ? null : (v) => setState(() => genero = v ?? "General"),
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
                                    child: _portadaBytes != null
                                        ? Image.memory(_portadaBytes!, fit: BoxFit.cover)
                                        : (portadaActual.isNotEmpty
                                            ? Image.network(
                                                portadaActual,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => const Icon(
                                                  Icons.broken_image_outlined,
                                                  color: navy,
                                                  size: 34,
                                                ),
                                              )
                                            : const Icon(Icons.menu_book, color: navy, size: 34)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _portadaFilename ??
                                              (portadaActual.isNotEmpty ? "Portada actual" : "Sin portada"),
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
                                            onPressed: _guardando ? null : _seleccionarYSubirPortada,
                                            icon: const Icon(Icons.image_outlined),
                                            label: const Text(
                                              "AGREGAR / ACTUALIZAR PORTADA",
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
                                onPressed: _guardando ? null : _guardar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: gold,
                                  foregroundColor: navy,
                                ),
                                child: Text(
                                  _guardando ? "GUARDANDO..." : "GUARDAR CAMBIOS",
                                  style: const TextStyle(fontWeight: FontWeight.w900),
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

  Widget _input(
    String label,
    TextEditingController c, {
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      validator: (v) {
        if (!required) return null;
        if (v == null || v.trim().isEmpty) return "Obligatorio";
        return null;
      },
      decoration: InputDecoration(labelText: label),
    );
  }
}