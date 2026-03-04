import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Paleta marca (coherente con admin)
  static const Color navy = Color(0xFF0F2A44);
  static const Color navy2 = Color(0xFF163A5F);
  static const Color gold = Color(0xFFC8A24A);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE6EAF2);

  bool _isEditing = false;
  bool _loading = true;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _correoController;
  late final TextEditingController _documentoController;
  late final TextEditingController _tipoUsuarioController;
  late final TextEditingController _celularController;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController();
    _apellidoController = TextEditingController();
    _correoController = TextEditingController();
    _documentoController = TextEditingController();
    _tipoUsuarioController = TextEditingController();
    _celularController = TextEditingController();

    _loadProfile();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _documentoController.dispose();
    _tipoUsuarioController.dispose();
    _celularController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final perfil = await ApiService.getMiPerfil();
      if (!mounted) return;

      setState(() {
        _nombreController.text = (perfil['nombre'] ?? '').toString();
        _apellidoController.text = (perfil['apellido'] ?? '').toString();
        _correoController.text = (perfil['correo'] ?? '').toString();
        _documentoController.text = (perfil['documento'] ?? '').toString();
        _tipoUsuarioController.text = (perfil['rol'] ?? '').toString();
        _celularController.text = (perfil['telefono'] ?? '').toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando perfil: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() => _profileImage = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _toggleOrSave() async {
    if (_isEditing) {
      // Guardar
      try {
        await ApiService.updateMiPerfil(
          nombre: _nombreController.text.trim(),
          apellido: _apellidoController.text.trim(),
          correo: _correoController.text.trim(),
          telefono: _celularController.text.trim(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Perfil actualizado')),
        );

        setState(() => _isEditing = false);
        await _loadProfile();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando perfil: $e')),
        );
      }
    } else {
      setState(() => _isEditing = true);
    }
  }

  String _fullName() {
    final n = _nombreController.text.trim();
    final a = _apellidoController.text.trim();
    final full = ('$n $a').trim();
    return full.isEmpty ? 'Mi perfil' : full;
    }

  String _rol() {
    final r = _tipoUsuarioController.text.trim();
    return r.isEmpty ? 'usuario' : r;
  }

  Color _chipBg(String rol) {
    final r = rol.trim().toLowerCase();
    if (r.contains('admin')) return const Color(0xFFE7F6ED);
    if (r.contains('bibliotec')) return gold.withOpacity(0.20);
    if (r.contains('prof')) return const Color(0xFFEAF2FF);
    return const Color(0xFFF3F4F6);
  }

  Color _chipFg(String rol) {
    final r = rol.trim().toLowerCase();
    if (r.contains('admin')) return const Color(0xFF157F3D);
    if (r.contains('bibliotec')) return navy;
    if (r.contains('prof')) return const Color(0xFF1D4ED8);
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(92),
        child: AppBar(
          toolbarHeight: 92,
          elevation: 0,
          foregroundColor: Colors.white,
          titleSpacing: 16,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mi perfil',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Datos de cuenta y contacto',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [navy, navy2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                children: [
                  _headerCard(),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Información personal',
                    children: [
                      _isEditing
                          ? _editField(
                              icon: Icons.person_outline,
                              label: 'Nombre',
                              controller: _nombreController,
                            )
                          : _infoRow(
                              icon: Icons.person_outline,
                              label: 'Nombre',
                              value: _nombreController.text.trim().isEmpty
                                  ? '—'
                                  : _nombreController.text.trim(),
                            ),
                      const SizedBox(height: 10),
                      _isEditing
                          ? _editField(
                              icon: Icons.person_outline,
                              label: 'Apellido',
                              controller: _apellidoController,
                            )
                          : _infoRow(
                              icon: Icons.person_outline,
                              label: 'Apellido',
                              value: _apellidoController.text.trim().isEmpty
                                  ? '—'
                                  : _apellidoController.text.trim(),
                            ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Contacto',
                    children: [
                      _isEditing
                          ? _editField(
                              icon: Icons.email_outlined,
                              label: 'Correo',
                              controller: _correoController,
                              keyboardType: TextInputType.emailAddress,
                            )
                          : _infoRow(
                              icon: Icons.email_outlined,
                              label: 'Correo',
                              value: _correoController.text.trim().isEmpty
                                  ? '—'
                                  : _correoController.text.trim(),
                            ),
                      const SizedBox(height: 10),
                      _isEditing
                          ? _editField(
                              icon: Icons.phone_outlined,
                              label: 'Celular',
                              controller: _celularController,
                              keyboardType: TextInputType.phone,
                            )
                          : _infoRow(
                              icon: Icons.phone_outlined,
                              label: 'Celular',
                              value: _celularController.text.trim().isEmpty
                                  ? '—'
                                  : _celularController.text.trim(),
                            ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Cuenta',
                    children: [
                      _infoRow(
                        icon: Icons.badge_outlined,
                        label: 'Documento',
                        value: _documentoController.text.trim().isEmpty
                            ? '—'
                            : _documentoController.text.trim(),
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        icon: Icons.verified_user_outlined,
                        label: 'Rol',
                        value: _rol(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _toggleOrSave,
                      icon: Icon(_isEditing ? Icons.save : Icons.edit),
                      label: Text(
                        _isEditing ? 'Guardar cambios' : 'Editar perfil',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEditing ? gold : navy,
                        foregroundColor: _isEditing ? navy : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _isEditing = false);
                          _loadProfile(); // revierte cambios locales
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: navy,
                          side: BorderSide(color: navy.withOpacity(0.25)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Cancelar edición',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _headerCard() {
    final name = _fullName();
    final rol = _rol();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isEditing ? _pickImage : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: navy.withOpacity(0.08),
                  backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? const Icon(Icons.person, size: 34, color: navy)
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 14, color: navy),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _chipBg(rol),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: navy.withOpacity(0.12)),
                  ),
                  child: Text(
                    rol,
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
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: navy,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: navy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: navy, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
      ),
    );
  }
}