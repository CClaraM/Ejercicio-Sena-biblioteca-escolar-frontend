import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  
  static const String baseUrl = 'http://localhost:8000';

  static String? _token;
  static String? _refreshToken;
  static String? _rol;
  static String? _documento;

  static String? get token => _token;
  static String? get refreshToken => _refreshToken;
  static String? get rol => _rol;
  static String? get documento => _documento;

  // ----------------------------
  // Storage token
  // ----------------------------
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _refreshToken = prefs.getString('refreshToken');
    _rol = prefs.getString('rol');
    _documento = prefs.getString('documento');
  }

  static Future<void> _saveSession({
    required String token,
    String? refreshToken,
    required String rol,
    required String documento,
  }) async {
    _token = token;
    _refreshToken = refreshToken;
    _rol = rol;
    _documento = documento;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await prefs.setString('refreshToken', refreshToken);
    } else {
      await prefs.remove('refreshToken');
    }

    await prefs.setString('rol', rol);
    await prefs.setString('documento', documento);
  }

  static Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    _rol = null;
    _documento = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');
    await prefs.remove('rol');
    await prefs.remove('documento');
  }

  // ----------------------------
  // HTTP helpers
  // ----------------------------
  static Map<String, String> _headers({bool auth = true}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth && _token != null && _token!.trim().isNotEmpty) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  static String _absUrl(String raw) {
    final u = (raw).trim();
    if (u.isEmpty) return '';
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    if (u.startsWith('/')) return '$baseUrl$u';
    return '$baseUrl/$u';
  }

  static Exception _httpError(http.Response r) {
    try {
      final body = r.body.trim();
      if (body.isEmpty) {
        return Exception('HTTP ${r.statusCode}: respuesta vacía');
      }

      final j = jsonDecode(body);

      if (j is Map<String, dynamic>) {
        if (j['detail'] != null) {
          return Exception('HTTP ${r.statusCode}: ${j['detail']}');
        }

        if (j['message'] != null) {
          return Exception('HTTP ${r.statusCode}: ${j['message']}');
        }

        if (j['error'] != null) {
          return Exception('HTTP ${r.statusCode}: ${j['error']}');
        }

        // Errores de validación de DRF
        final parts = <String>[];
        j.forEach((key, value) {
          if (value is List) {
            parts.add('$key: ${value.join(', ')}');
          } else {
            parts.add('$key: $value');
          }
        });

        if (parts.isNotEmpty) {
          return Exception('HTTP ${r.statusCode}: ${parts.join(' | ')}');
        }
      }

      if (j is List) {
        return Exception('HTTP ${r.statusCode}: ${j.join(', ')}');
      }

      return Exception('HTTP ${r.statusCode}: $body');
    } catch (_) {
      return Exception('HTTP ${r.statusCode}: ${r.body}');
    }
  }

  static List<dynamic> _extractList(dynamic j) {
    if (j is List) return j;

    if (j is Map<String, dynamic>) {
      if (j['results'] is List) return j['results'] as List;
      if (j['data'] is List) return j['data'] as List;
      if (j['items'] is List) return j['items'] as List;
    }

    return [];
  }

  static Map<String, dynamic> _extractMap(dynamic j) {
    if (j is Map<String, dynamic>) return j;
    return <String, dynamic>{};
  }

  static Future<http.Response> _get(
    String path, {
    bool auth = true,
    bool retryOn401 = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    var r = await http.get(url, headers: _headers(auth: auth));

    if (r.statusCode == 401 && retryOn401 && auth) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        r = await http.get(url, headers: _headers(auth: true));
      }
    }

    return r;
  }

  static Future<http.Response> _post(
    String path, {
    Object? body,
    bool auth = true,
    bool retryOn401 = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    var r = await http.post(
      url,
      headers: _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );

    if (r.statusCode == 401 && retryOn401 && auth) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        r = await http.post(
          url,
          headers: _headers(auth: true),
          body: body == null ? null : jsonEncode(body),
        );
      }
    }

    return r;
  }

  static Future<http.Response> _put(
    String path, {
    Object? body,
    bool auth = true,
    bool retryOn401 = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    var r = await http.put(
      url,
      headers: _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );

    if (r.statusCode == 401 && retryOn401 && auth) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        r = await http.put(
          url,
          headers: _headers(auth: true),
          body: body == null ? null : jsonEncode(body),
        );
      }
    }

    return r;
  }

  static Future<http.Response> _patch(
    String path, {
    Object? body,
    bool auth = true,
    bool retryOn401 = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    var r = await http.patch(
      url,
      headers: _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );

    if (r.statusCode == 401 && retryOn401 && auth) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        r = await http.patch(
          url,
          headers: _headers(auth: true),
          body: body == null ? null : jsonEncode(body),
        );
      }
    }

    return r;
  }

  static Future<http.Response> _delete(
    String path, {
    Object? body,
    bool auth = true,
    bool retryOn401 = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    var r = await http.delete(
      url,
      headers: _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );

    if (r.statusCode == 401 && retryOn401 && auth) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        r = await http.delete(
          url,
          headers: _headers(auth: true),
          body: body == null ? null : jsonEncode(body),
        );
      }
    }

    return r;
  }

  static Future<bool> _tryRefreshToken() async {
    if (_refreshToken == null || _refreshToken!.trim().isEmpty) {
      return false;
    }

    try {
      final url = Uri.parse('$baseUrl/api/auth/token/refresh/');
      final r = await http.post(
        url,
        headers: _headers(auth: false),
        body: jsonEncode({'refresh': _refreshToken}),
      );

      if (r.statusCode < 200 || r.statusCode >= 300) {
        return false;
      }

      final j = jsonDecode(r.body);
      final newAccess = (j['access'] ?? '').toString().trim();

      if (newAccess.isEmpty) return false;

      _token = newAccess;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', newAccess);

      return true;
    } catch (_) {
      return false;
    }
  }

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  // ============================
  // AUTH
  // ============================
  // Supuesto Django:
  // POST /api/auth/login/
  // body: {documento, password}
  // respuesta:
  // {
  //   "access": "...",
  //   "refresh": "...",
  //   "user": {
  //     "id": 1,
  //     "documento": "123",
  //     "rol": "estudiante"
  //   }
  // }
  static Future<void> login({
    required String documento,
    required String contrasena,
  }) async {
    final r = await _post(
      '/api/auth/login/',
      auth: false,
      retryOn401: false,
      body: {
        'documento': documento,
        'password': contrasena,
      },
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }

    final j = jsonDecode(r.body);

    final token = (j['access'] ?? j['token'] ?? j['accessToken'] ?? '')
        .toString()
        .trim();

    final refresh = (j['refresh'] ?? '').toString().trim();

    final user = j['user'] is Map<String, dynamic>
        ? j['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rol = (j['rol'] ??
            user['rol'] ??
            user['role'] ??
            user['tipo_usuario'] ??
            'estudiante')
        .toString()
        .trim();

    final doc = (j['documento'] ??
            user['documento'] ??
            user['username'] ??
            documento)
        .toString()
        .trim();

    if (token.isEmpty) {
      throw Exception('Login sin token. Revisa la respuesta del backend.');
    }

    await _saveSession(
      token: token,
      refreshToken: refresh.isEmpty ? null : refresh,
      rol: rol.isEmpty ? 'estudiante' : rol,
      documento: doc,
    );
  }

  // Opcional si usas endpoint de logout en backend
  static Future<void> logoutServerSide() async {
    if (_refreshToken == null || _refreshToken!.trim().isEmpty) {
      await logout();
      return;
    }

    try {
      final r = await _post(
        '/api/auth/logout/',
        body: {'refresh': _refreshToken},
      );

      if (r.statusCode >= 200 && r.statusCode < 300) {
        await logout();
        return;
      }
    } catch (_) {}

    await logout();
  }

  // Django típico:
  // POST /api/auth/change-password/
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final r = await _post(
      '/api/auth/change-password/',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }
  }

  // ============================
  // LIBROS
  // ============================
  // GET /api/libros/?search=...
  static Future<List<Map<String, dynamic>>> getLibros({
    String search = '',
  }) async {
    final qs = search.trim();
    final path =
        '/api/libros/${qs.isEmpty ? '' : '?search=${Uri.encodeQueryComponent(qs)}'}';

    var r = await _get(path, auth: true);

    // Si la lista de libros es pública, se intenta sin auth
    if (r.statusCode == 401) {
      r = await _get(path, auth: false, retryOn401: false);
    }

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }

    final j = jsonDecode(r.body);
    final list = _extractList(j);

    return list.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);

      final id = m['id_libro'] ?? m['id'] ?? m['pk'];
      final titulo = m['titulo'] ?? m['title'] ?? '';
      final autor = m['autor'] ?? m['author'] ?? '';
      final genero = m['genero'] ?? m['area'] ?? m['categoria'] ?? 'General';
      final anio = m['anio'] ?? m['anio_publicacion'] ?? m['year'] ?? '';
      final portada =
          m['portadaUrl'] ?? m['portada_url'] ?? m['portada'] ?? m['imagen'] ?? '';

      return {
        'id': _asInt(id),
        'titulo': titulo.toString(),
        'autor': autor.toString(),
        'genero': genero.toString(),
        'anio': anio.toString(),
        'isbn': (m['isbn'] ?? m['codigo_libro'] ?? '').toString(),
        'ejemplares': _asInt(
          m['cantidad_ejemplares'] ?? m['ejemplares'] ?? m['stock'],
        ),
        'ejemplares_disponibles': _asInt(
          m['ejemplares_disponibles'] ?? m['disponibles'],
        ),
        'portadaUrl': _absUrl(portada.toString()),
      };
    }).toList();
  }

  // GET /api/libros/{id}/
  static Future<Map<String, dynamic>> getLibroDetalle(int id) async {
    final r = await _get('/api/libros/$id/');

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }

    final j = _extractMap(jsonDecode(r.body));

    return {
      'id': _asInt(j['id'] ?? j['id_libro'] ?? j['pk']),
      'titulo': (j['titulo'] ?? '').toString(),
      'autor': (j['autor'] ?? '').toString(),
      'genero': (j['genero'] ?? j['area'] ?? 'General').toString(),
      'anio': (j['anio'] ?? j['anio_publicacion'] ?? '').toString(),
      'isbn': (j['isbn'] ?? j['codigo_libro'] ?? '').toString(),
      'ejemplares': _asInt(j['cantidad_ejemplares'] ?? j['ejemplares']),
      'ejemplares_disponibles': _asInt(
        j['ejemplares_disponibles'] ?? j['disponibles'],
      ),
      'descripcion': (j['descripcion'] ?? '').toString(),
      'portadaUrl': _absUrl(
        (j['portada_url'] ?? j['portadaUrl'] ?? j['portada'] ?? '').toString(),
      ),
    };
  }

  // POST /api/admin/libros/
  static Future<int> agregarLibro(Map<String, dynamic> libro) async {
    final r = await _post(
      '/api/admin/libros/',
      body: {
        'codigo_libro': (libro['isbn'] ?? '').toString().trim(),
        'titulo': (libro['titulo'] ?? '').toString().trim(),
        'autor': (libro['autor'] ?? '').toString().trim(),
        'area': (libro['genero'] ?? 'General').toString().trim(),
        'anio_publicacion':
            int.tryParse((libro['anio'] ?? '').toString().trim()),
        'cantidad_ejemplares':
            int.tryParse((libro['ejemplares'] ?? '0').toString().trim()) ?? 0,
      },
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }

    final j = _extractMap(jsonDecode(r.body));
    final id = _asInt(j['id'] ?? j['id_libro'] ?? j['pk']);

    if (id <= 0) {
      throw Exception('El backend no devolvió el id del libro.');
    }

    return id;
  }

  // PUT /api/admin/libros/{id}/
  static Future<void> editarLibro(int id, Map<String, dynamic> cambios) async {
    final r = await _put(
      '/api/admin/libros/$id/',
      body: {
        if (cambios.containsKey('titulo')) 'titulo': cambios['titulo'],
        if (cambios.containsKey('autor')) 'autor': cambios['autor'],
        if (cambios.containsKey('genero')) 'area': cambios['genero'],
        if (cambios.containsKey('anio'))
          'anio_publicacion': int.tryParse((cambios['anio'] ?? '').toString()),
        if (cambios.containsKey('isbn')) 'codigo_libro': cambios['isbn'],
        if (cambios.containsKey('ejemplares'))
          'cantidad_ejemplares':
              int.tryParse((cambios['ejemplares'] ?? '').toString()),
      },
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }
  }

  // DELETE /api/admin/libros/{id}/
  static Future<void> eliminarLibro(int id) async {
    final r = await _delete('/api/admin/libros/$id/');

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }
  }

  // POST /api/admin/libros/{id}/portada/
  static Future<String> uploadPortada(
    int idLibro,
    List<int> bytes,
    String filename,
  ) async {
    final url = Uri.parse('$baseUrl/api/admin/libros/$idLibro/portada/');
    final req = http.MultipartRequest('POST', url);

    if (_token != null && _token!.trim().isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $_token';
    }
    req.headers['Accept'] = 'application/json';

    req.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final res = await req.send();
    final body = await res.stream.bytesToString();

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: $body');
    }

    final j = _extractMap(jsonDecode(body));
    return _absUrl(
      (j['portada_url'] ?? j['portadaUrl'] ?? j['portada'] ?? '').toString(),
    );
  }

  // POST /api/admin/import/libros/
  static Future<int> importarLibrosExcel(
    List<int> bytes,
    String filename,
  ) async {
    final url = Uri.parse('$baseUrl/api/admin/import/libros/');
    final req = http.MultipartRequest('POST', url);

    if (_token != null && _token!.trim().isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $_token';
    }
    req.headers['Accept'] = 'application/json';

    req.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final res = await req.send();
    final body = await res.stream.bytesToString();

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: $body');
    }

    final j = _extractMap(jsonDecode(body));
    return _asInt(j['inserted'] ?? j['count'] ?? j['rows']);
  }

  // POST /api/admin/import/usuarios/
  static Future<int> importarUsuariosExcel(
    List<int> bytes,
    String filename,
  ) async {
    final url = Uri.parse('$baseUrl/api/admin/import/usuarios/');
    final req = http.MultipartRequest('POST', url);

    if (_token != null && _token!.trim().isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $_token';
    }
    req.headers['Accept'] = 'application/json';

    req.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final res = await req.send();
    final body = await res.stream.bytesToString();

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: $body');
    }

    final j = _extractMap(jsonDecode(body));
    return _asInt(j['inserted'] ?? j['count'] ?? j['rows']);
  }

  // ============================
  // USUARIOS
  // ============================
  // GET /api/usuarios/?search=...
  static Future<List<Map<String, dynamic>>> getUsuarios({String q = ''}) async {
    final qs = q.trim();
    final path =
        '/api/usuarios/${qs.isEmpty ? '' : '?search=${Uri.encodeQueryComponent(qs)}'}';

    final r = await _get(path);

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }

    final j = jsonDecode(r.body);
    final list = _extractList(j);

    return list.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);

      return {
        'id': _asInt(m['id'] ?? m['pk']),
        'documento': (m['documento'] ?? m['username'] ?? '').toString(),
        'nombre': (m['nombre'] ?? m['first_name'] ?? '').toString(),
        'apellido': (m['apellido'] ?? m['last_name'] ?? '').toString(),
        'correo': (m['correo'] ?? m['email'] ?? '').toString(),
        'telefono': (m['telefono'] ?? '').toString(),
        'rol': (m['rol'] ?? m['role'] ?? 'estudiante').toString(),
        'activo': (m['is_active'] ?? m['activo'] ?? true) == true,
      };
    }).toList();
  }

  // POST /api/admin/usuarios/
  static Future<void> agregarUsuario(Map<String, dynamic> u) async {
    final r = await _post(
      '/api/admin/usuarios/',
      body: {
        'documento': u['documento'],
        'nombre': u['nombre'],
        'apellido': u['apellido'],
        'correo': u['correo'],
        'telefono': u['telefono'],
        'rol': u['rol'],
        'password': u['password'],
      },
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }
  }

  // GET /api/usuarios/me/
  static Future<Map<String, dynamic>> getMiPerfil() async {
    final r = await _get('/api/usuarios/me/');

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }

    final j = _extractMap(jsonDecode(r.body));

    return {
      'id': _asInt(j['id'] ?? j['pk']),
      'documento': (j['documento'] ?? j['username'] ?? '').toString(),
      'nombre': (j['nombre'] ?? j['first_name'] ?? '').toString(),
      'apellido': (j['apellido'] ?? j['last_name'] ?? '').toString(),
      'correo': (j['correo'] ?? j['email'] ?? '').toString(),
      'telefono': (j['telefono'] ?? '').toString(),
      'rol': (j['rol'] ?? 'estudiante').toString(),
    };
  }

  // PUT /api/usuarios/me/
  static Future<void> updateMiPerfil({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
  }) async {
    final r = await _put(
      '/api/usuarios/me/',
      body: {
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'telefono': telefono,
      },
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }
  }

  // PUT /api/admin/usuarios/{id}/
  static Future<void> adminUpdateUsuario(
    int id,
    Map<String, dynamic> cambios,
  ) async {
    final r = await _put('/api/admin/usuarios/$id/', body: cambios);

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }
  }

  // PATCH /api/admin/usuarios/{id}/activar/
  static Future<void> activarUsuario(int id, bool activo) async {
    final r = await _patch(
      '/api/admin/usuarios/$id/activar/',
      body: {'activo': activo},
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }
  }

  // ============================
  // SOLICITUDES
  // ============================
  // POST /api/solicitudes/
  static Future<int> solicitarLibro(int idLibro) async {
    final r = await _post(
      '/api/solicitudes/',
      body: {'id_libro': idLibro},
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }

    final j = _extractMap(jsonDecode(r.body));
    return _asInt(j['id_solicitud'] ?? j['id'] ?? j['pk']);
  }

  // GET /api/solicitudes/me/
  static Future<List<Map<String, dynamic>>> getMisSolicitudes() async {
    final r = await _get('/api/solicitudes/me/');

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }

    final j = jsonDecode(r.body);
    final list = _extractList(j);

    return list
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // GET /api/bibliotecario/solicitudes/pendientes/
  static Future<List<Map<String, dynamic>>> getSolicitudesPendientes() async {
    final r = await _get('/api/bibliotecario/solicitudes/pendientes/');

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }

    final j = jsonDecode(r.body);
    final list = _extractList(j);

    return list
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ----------------------------
  // PRESTAMOS (usuario)
  // ----------------------------
  // GET /api/me/prestamos/ -> préstamos del usuario autenticado
  static Future<List<Map<String, dynamic>>> getMisPrestamos() async {
    final r = await _get('/api/me/prestamos/');

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }

    final j = jsonDecode(r.body);
    final list = _extractList(j);

    return list.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);

      final portadaRaw =
          (m['portada_url'] ?? m['portadaUrl'] ?? m['portada'] ?? '').toString();
      final portadaAbs = _absUrl(portadaRaw);

      final fechaPrestamo =
          (m['fecha_prestamo'] ?? m['fechaPrestamo'] ?? '').toString();
      final fechaVenc =
          (m['fecha_vencimiento'] ?? m['fechaVencimiento'] ?? '').toString();
      final fechaDev =
          (m['fecha_devolucion'] ?? m['fechaDevolucion'] ?? '').toString();

      return {
        ...m,
        'id': m['id'] ?? m['id_prestamo'] ?? m['pk'],
        'portada_url': portadaAbs,
        'portadaUrl': portadaAbs,

        'fecha_prestamo': fechaPrestamo,
        'fecha_vencimiento': fechaVenc,
        'fecha_devolucion': fechaDev,

        'fechaPrestamo': fechaPrestamo,
        'fechaVencimiento': fechaVenc,
        'fechaDevolucion': fechaDev,
      };
    }).toList();
  }

  // POST /api/bibliotecario/solicitudes/{id}/aprobar/
  static Future<void> aprobarSolicitud(
    int idSolicitud, {
    int? diasPrestamo,
    String? observacion,
  }) async {
    final r = await _post(
      '/api/bibliotecario/solicitudes/$idSolicitud/aprobar/',
      body: {
        if (diasPrestamo != null) 'dias_prestamo': diasPrestamo,
        if (observacion != null && observacion.trim().isNotEmpty)
          'observacion': observacion.trim(),
      },
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }
  }

  // POST /api/bibliotecario/solicitudes/{id}/rechazar/
  static Future<void> rechazarSolicitud(
    int idSolicitud, {
    String? observacion,
  }) async {
    final r = await _post(
      '/api/bibliotecario/solicitudes/$idSolicitud/rechazar/',
      body: {
        if (observacion != null && observacion.trim().isNotEmpty)
          'observacion': observacion.trim(),
      },
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }
  }

  // ============================
  // PRESTAMOS
  // ============================
  // GET /api/bibliotecario/prestamos/?estado=activo&solo_vencidos=1
  static Future<List<Map<String, dynamic>>> getPrestamos({
    String estado = 'activo',
    bool soloVencidos = false,
  }) async {
    final path =
        '/api/bibliotecario/prestamos/?estado=${Uri.encodeQueryComponent(estado)}&solo_vencidos=${soloVencidos ? 1 : 0}';

    final r = await _get(path);

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }

    final j = jsonDecode(r.body);
    final list = _extractList(j);

    return list
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // POST /api/prestamos/{id}/devolver/
  static Future<void> devolverPrestamo(
    int idPrestamo, {
    String condicion = 'bueno',
    String observaciones = '',
  }) async {
    final r = await _post(
      '/api/prestamos/$idPrestamo/devolver/',
      body: {
        'condicion': condicion.toLowerCase().trim(),
        'observaciones': observaciones.trim(),
      },
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }
  }

  // ============================
  // DASHBOARD
  // ============================
  static Future<Map<String, int>> getDashboardCounts() async {
    final solicitudes = await getSolicitudesPendientes();
    final prestamos = await getPrestamos(estado: 'activo', soloVencidos: false);
    final libros = await getLibros(search: '');

    return {
      'pendientes': solicitudes.length,
      'activos': prestamos.length,
      'libros': libros.length,
    };
  }
}