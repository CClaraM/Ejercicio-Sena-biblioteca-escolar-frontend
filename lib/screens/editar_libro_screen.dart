import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';

class EditarLibroScreen extends StatefulWidget {
  final Map<String, dynamic> libro;
  const EditarLibroScreen({super.key, required this.libro});

  @override
  State<EditarLibroScreen> createState() => _EditarLibroScreenState();
}

class _EditarLibroScreenState extends State<EditarLibroScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController titulo;
  late final TextEditingController autor;
  late final TextEditingController anio;
  late final TextEditingController isbn;

  late String genero;

  @override
  void initState() {
    super.initState();
    titulo = TextEditingController(text: (widget.libro["titulo"] ?? "").toString());
    autor = TextEditingController(text: (widget.libro["autor"] ?? "").toString());
    anio = TextEditingController(text: (widget.libro["anio"] ?? "").toString());
    isbn = TextEditingController(text: (widget.libro["isbn"] ?? "").toString());
    genero = (widget.libro["genero"] ?? "General").toString();
  }

  @override
  void dispose() {
    titulo.dispose();
    autor.dispose();
    anio.dispose();
    isbn.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    await ApiService.editarLibro(widget.libro["id"] as int, {
      "titulo": titulo.text.trim(),
      "autor": autor.text.trim(),
      "anio": anio.text.trim(),
      "genero": genero,
      "isbn": isbn.text.trim(),
      //"portadaUrl": portadaUrl.text.trim(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Libro actualizado")));
    Navigator.pop(context);
  }

  Future<void> _agregarPortada() async {
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

    final int idLibro = widget.libro["id"] as int;

    // ✅ Subir portada (usa el endpoint POST /libros/:id/portada)
    final nuevaUrl = await ApiService.uploadPortada(idLibro, bytes, file.name);

    // ✅ Actualiza el estado local para que se vea la portada nueva (opcional pero recomendado)
    setState(() {
      widget.libro["portadaUrl"] = nuevaUrl; // tu UI usa portadaUrl
      // si tu UI usa widget.libro["portada_url"], cámbialo aquí
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
    return Scaffold(
      appBar: AppBar(title: const Text("EDITAR LIBRO")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _input("Título", titulo, required: true),
              const SizedBox(height: 12),
              _input("Autor", autor, required: true),
              const SizedBox(height: 12),
              _input("Año", anio),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: genero,
                decoration: const InputDecoration(labelText: "Género", border: OutlineInputBorder()),
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
                onChanged: (v) => setState(() => genero = v ?? "General"),
              ),
              const SizedBox(height: 12),
              _input("ISBN", isbn),
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _agregarPortada,
                  child: const Text("AGREGAR/ACTUALIZAR PORTADA")
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                child: ElevatedButton(onPressed: _guardar, child: const Text("GUARDAR CAMBIOS")),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController c, {bool required = false}) {
    return TextFormField(
      controller: c,
      validator: (v) {
        if (!required) return null;
        if (v == null || v.trim().isEmpty) return "Obligatorio";
        return null;
      },
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}
