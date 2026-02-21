import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ cambia según tu entorno
  static const String baseUrl = 'http://localhost:3000';

  static String? _token;
  static String? _rol;
  static String? _documento;

  static String? get token => _token;
  static String? get rol => _rol;
  static String? get documento => _documento;

  // ----------------------------
  // Storage token
  // ----------------------------
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _rol = prefs.getString('rol');
    _documento = prefs.getString('documento');
  }

  static Future<void> _saveSession({
    required String token,
    required String rol,
    required String documento,
  }) async {
    _token = token;
    _rol = rol;
    _documento = documento;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('rol', rol);
    await prefs.setString('documento', documento);
  }

  static Future<void> logout() async {
    _token = null;
    _rol = null;
    _documento = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('rol');
    await prefs.remove('documento');
  }

  // ----------------------------
  // HTTP helpers
  // ----------------------------
  static Map<String, String> _headers({bool auth = true}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth && _token != null) {
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
      final j = jsonDecode(r.body);
      final msg = (j is Map && j['message'] != null) ? j['message'].toString() : r.body;
      return Exception('HTTP ${r.statusCode}: $msg');
    } catch (_) {
      return Exception('HTTP ${r.statusCode}: ${r.body}');
    }
  }

  // ----------------------------
  // AUTH
  // ----------------------------
  // Espera backend: POST /api/auth/login {documento, contrasena}
  // y responde: { token, user: { documento, rol } } o { token, rol, documento }
  static Future<void> login({
    required String documento,
    required String contrasena,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final r = await http.post(
      url,
      headers: _headers(auth: false),
      body: jsonEncode({'documento': documento, 'contrasena': contrasena}),
    );

    if (r.statusCode < 200 || r.statusCode >= 300) throw _httpError(r);

    final j = jsonDecode(r.body);

    // soporta varias formas de respuesta
    final token = (j['token'] ?? j['accessToken'] ?? '').toString();
    final rol = (j['rol'] ??
            (j['user'] is Map ? j['user']['rol'] : null) ??
            (j['usuario'] is Map ? j['usuario']['rol'] : null) ??
            '')
        .toString();
    final doc = (j['documento'] ??
            (j['user'] is Map ? j['user']['documento'] : null) ??
            (j['usuario'] is Map ? j['usuario']['documento'] : null) ??
            documento)
        .toString();

    if (token.isEmpty) throw Exception('Login sin token. Revisa respuesta del backend.');
    if (rol.isEmpty) {
      // si tu backend no devuelve rol, igual guardamos
      await _saveSession(token: token, rol: 'estudiante', documento: doc);
      return;
    }
    await _saveSession(token: token, rol: rol, documento: doc);
  }

  // POST /api/auth/change-password {currentPassword,newPassword}
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/change-password');
    final r = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) throw _httpError(r);
  }

  // ----------------------------
  // LIBROS
  // ----------------------------
  // GET /api/libros?search=... (si no hay search, lista todo)
  static Future<List<Map<String, dynamic>>> getLibros({String search = ''}) async {
    final qs = search.trim();
    final url = Uri.parse('$baseUrl/api/libros${qs.isEmpty ? '' : '?search=${Uri.encodeQueryComponent(qs)}'}');
    final r = await http.get(url, headers: _headers()); // libros pueden ser públicos
    if (r.statusCode < 200 || r.statusCode >= 300) throw _httpError(r);

    final j = jsonDecode(r.body);
    final List list = (j is List) ? j : (j['data'] is List ? j['data'] : []);
    return list.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);

      // Normalizamos a lo que tu UI ya espera:
      final id = m['id_libro'] ?? m['id'] ?? m['idLibro'];
      final titulo = m['titulo'] ?? '';
      final autor = m['autor'] ?? '';
      final genero = m['genero'] ?? m['area'] ?? 'General';
      final anio = m['anio'] ?? m['anio_publicacion'] ?? '';
      final portada = m['portadaUrl'] ?? m['portada_url'] ?? m['portada'] ?? '';

      return {
        'id': id,
        'titulo': titulo,
        'autor': autor,
        'genero': genero,
        'anio': anio.toString(),
        'isbn': (m['isbn'] ?? m['codigo_libro'] ?? '').toString(),
        'portadaUrl': _absUrl(portada.toString()),
      };
    }).toList();
  }

  // POST /api/admin/libros (ajusta si tu ruta es diferente)
  static Future<int> agregarLibro(Map<String, dynamic> libro) async {
    final url = Uri.parse('$baseUrl/api/admin/libros');

    final r = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'codigo_libro': (libro['isbn'] ?? '').toString().trim(),
        'titulo': (libro['titulo'] ?? '').toString().trim(),
        'autor': (libro['autor'] ?? '').toString().trim(),
        'area': (libro['genero'] ?? 'General').toString().trim(),
        'anio_publicacion': int.tryParse((libro['anio'] ?? '').toString().trim()),
        'cantidad_ejemplares': int.tryParse((libro['ejemplares'] ?? '0').toString().trim()) ?? 0,
      }),
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _httpError(r);
    }

    final j = jsonDecode(r.body);

    final id = j['id_libro'];
    final idLibro = int.tryParse(id.toString()) ?? 0;

    if (idLibro == 0) {
      throw Exception("El backend no devolvió id_libro");
    }

    return idLibro;
  }


  // PUT /api/admin/libros/:id (ajusta si tu ruta es diferente)
  static Future<void> editarLibro(int id, Map<String, dynamic> cambios) async {
    final url = Uri.parse('$baseUrl/api/admin/libros/$id');
    final r = await http.put(
      url,
      headers: _headers(),
      body: jsonEncode({
        if (cambios.containsKey('titulo')) 'titulo': cambios['titulo'],
        if (cambios.containsKey('autor')) 'autor': cambios['autor'],
        if (cambios.containsKey('genero')) 'area': cambios['genero'],
        if (cambios.containsKey('anio'))
          'anio_publicacion': int.tryParse((cambios['anio'] ?? '').toString()),
        if (cambios.containsKey('isbn')) 'codigo_libro': cambios['isbn'],
        //if (cambios.containsKey('portadaUrl')) 'portada_url': cambios['portadaUrl'],
      }),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) throw _httpError(r);
  }

  // Upload portada: POST /api/admin/libros/:id/portada (multipart form-data field=file)
  static Future<String> uploadPortada(int idLibro, List<int> bytes, String filename) async {
    final url = Uri.parse('$baseUrl/api/admin/libros/$idLibro/portada');
    final req = http.MultipartRequest('POST', url);
    req.headers['Authorization'] = 'Bearer $_token';
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final res = await req.send();
    final body = await res.stream.bytesToString();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: $body');
    }
    final j = jsonDecode(body);
    final portadaUrl = _absUrl((j['portada_url'] ?? j['portadaUrl'] ?? '').toString());
    return portadaUrl;
  }

  // Carga masiva de Libros desde Excel (xlsx) - POST /api/admin/import/libros (multipart form-data field=file)
  static Future<int> importarLibrosExcel(List<int> bytes, String filename) async {
    final url = Uri.parse('$baseUrl/api/admin/import/libros'); // ✅ AJUSTA si tu ruta es otra

    final req = http.MultipartRequest('POST', url);
    req.headers['Authorization'] = 'Bearer $_token';
    req.files.add(http.MultipartFile.fromBytes(
      'file', // ✅ nombre del campo que espera multer
      bytes,
      filename: filename,
    ));
    final res = await req.send();
    final body = await res.stream.bytesToString();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: $body');
    }
    final j = jsonDecode(body);
    // soporta varias respuestas: {inserted: 10} o {ok:true, inserted:10} o {count:10}
    final inserted = (j['inserted'] ?? j['count'] ?? j['rows'] ?? 0);
    return int.tryParse(inserted.toString()) ?? 0;
  }

  // Carga masiva de Usuarios desde Excel (xlsx) - POST /api/admin/import/usuarios (multipart form-data field=file)
  static Future<int> importarUsuariosExcel(List<int> bytes, String filename) async {
    final url = Uri.parse('$baseUrl/api/admin/import/usuarios'); // ✅ AJUSTA si tu ruta es otra

    final req = http.MultipartRequest('POST', url);
    req.headers['Authorization'] = 'Bearer $_token';

    req.files.add(http.MultipartFile.fromBytes(
      'file', // ✅ nombre del campo que espera multer
      bytes,
      filename: filename,
    ));

    final res = await req.send();
    final body = await res.stream.bytesToString();

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: $body');
    }

    final j = jsonDecode(body);
    // soporta varias respuestas: {inserted: 10} o {ok:true, inserted:10} o {count:10}
    final inserted = (j['inserted'] ?? j['count'] ?? j['rows'] ?? 0);
    return int.tryParse(inserted.toString()) ?? 0;
  }

  // ----------------------------
  // USUARIOS (bibliotecario/admin)
  // ----------------------------
  // GET /api/usuarios?q=...
  static Future<List<Map<String, dynamic>>> getUsuarios({String q = ''}) async {
    final qs = q.trim();
    final url = Uri.parse('$baseUrl/api/usuarios${qs.isEmpty ? '' : '?q=${Uri.encodeQueryComponent(qs)}'}');
    final r = await http.get(url, headers: _headers());
    if (r.statusCode < 200 || r.statusCode >= 300) throw _httpError(r);

    final j = jsonDecode(r.body);
    final List list = (j is List) ? j : (j['data'] is List ? j['data'] : []);
    return list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // POST /api/admin/usuarios (ajusta si tu ruta es diferente)
  static Future<void> agregarUsuario(Map<String, dynamic> u) async {
    final url = Uri.parse('$baseUrl/api/admin/usuarios');
    final r = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(u),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) throw _httpError(r);
  }

  // ----------------------------
  // SOLICITUDES (bibliotecario/admin)
  // ----------------------------
  // GET /api/bibliotecario/solicitudes?estado=pendiente
  static Future<List<Map<String, dynamic>>> getSolicitudesPendientes() async {
    final url = Uri.parse('$baseUrl/api/bibliotecario/solicitudes/pendientes');
    final r = await http.get(url, headers: _headers());
    if (r.statusCode < 200 || r.statusCode >= 300) throw _httpError(r);

    final j = jsonDecode(r.body);
    final List list = (j is List) ? j : (j['data'] is List ? j['data'] : []);
    return list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // POST /api/bibliotecario/solicitudes/:id/aprobar {dias_prestamo,observacion}
  static Future<void> aprobarSolicitud(int idSolicitud, {int? diasPrestamo, String? observacion}) async {
    final url = Uri.parse('$baseUrl/api/bibliotecario/solicitudes/$idSolicitud/aprobar');
    final r = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        if (diasPrestamo != null) 'dias_prestamo': diasPrestamo,
        if (observacion != null) 'observacion': observacion,
      }),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) throw _httpError(r);
  }

  // POST /api/bibliotecario/solicitudes/:id/rechazar {observacion}
  static Future<void> rechazarSolicitud(int idSolicitud, {String? observacion}) async {
    final url = Uri.parse('$baseUrl/api/bibliotecario/solicitudes/$idSolicitud/rechazar');
    final r = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        if (observacion != null) 'observacion': observacion,
      }),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) throw _httpError(r);
  }

  // ----------------------------
  // PRESTAMOS (bibliotecario/admin)
  // ----------------------------
  // GET /api/bibliotecario/prestamos?estado=activo&soloVencidos=1
  static Future<List<Map<String, dynamic>>> getPrestamos({String estado = 'activo', bool soloVencidos = false}) async {
    final url = Uri.parse(
      '$baseUrl/api/bibliotecario/prestamos?estado=${Uri.encodeQueryComponent(estado)}&soloVencidos=${soloVencidos ? 1 : 0}',
    );
    final r = await http.get(url, headers: _headers());
    if (r.statusCode < 200 || r.statusCode >= 300) throw _httpError(r);

    final j = jsonDecode(r.body);
    final List list = (j is List) ? j : (j['data'] is List ? j['data'] : []);
    return list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // POST /api/prestamos/:id/devolver {condicion,observaciones}
  static Future<void> devolverPrestamo(int idPrestamo, {String condicion = 'bueno', String observaciones = ''}) async {
    final url = Uri.parse('$baseUrl/api/prestamos/$idPrestamo/devolver');
    final r = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'condicion': condicion.toLowerCase(),
        'observaciones': observaciones,
      }),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) throw _httpError(r);
  }

  // ----------------------------
  // Dashboard counts (admin_home)
  // ----------------------------
  static Future<Map<String, int>> getDashboardCounts() async {
    // Si no tienes un endpoint único, lo calculamos con llamadas existentes:
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
