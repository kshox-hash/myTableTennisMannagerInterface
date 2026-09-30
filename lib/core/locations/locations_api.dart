import "dart:convert";
import "package:myttmi/core/api/api_http.dart";
import "package:myttmi/core/constants/app_config.dart";

class RegionCL {
  final String codigo;
  final String nombre;
  RegionCL({required this.codigo, required this.nombre});
  factory RegionCL.fromJson(Map<String, dynamic> j) =>
      RegionCL(codigo: (j["code"] ?? j["codigo"]).toString(), nombre: (j["name"] ?? j["nombre"]).toString());
}

class ProvinciaCL {
  final String codigo;
  final String nombre;
  final String codigoRegion;
  ProvinciaCL({required this.codigo, required this.nombre, required this.codigoRegion});
  factory ProvinciaCL.fromJson(Map<String, dynamic> j) => ProvinciaCL(
    codigo: (j["code"] ?? j["codigo"]).toString(),
    nombre: (j["name"] ?? j["nombre"]).toString(),
    codigoRegion: (j["region_code"] ?? j["codigoRegion"] ?? j["codigo_padre"]).toString(),
  );
}

class ComunaCL {
  final String codigo;
  final String nombre;
  final String codigoProvincia;
  ComunaCL({required this.codigo, required this.nombre, required this.codigoProvincia});
  factory ComunaCL.fromJson(Map<String, dynamic> j) => ComunaCL(
    codigo: (j["code"] ?? j["codigo"]).toString(),
    nombre: (j["name"] ?? j["nombre"]).toString(),
    codigoProvincia: (j["province_code"] ?? j["codigoProvincia"] ?? j["codigo_padre"]).toString(),
  );
}

class LocationsApi {
  final String baseUrl;
  LocationsApi({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  Future<List<RegionCL>> fetchRegions() async {
    final uri = Uri.parse("$baseUrl/api/locations/regions");
    final res = await apiHttp.get(uri);
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || decoded["ok"] != true) {
      throw Exception(decoded["error"] ?? "Error regiones");
    }
    final data = (decoded["data"] as List).cast<Map<String, dynamic>>();
    return data.map(RegionCL.fromJson).toList();
    }

  Future<List<ProvinciaCL>> fetchProvinces(String regionCode) async {
    final uri = Uri.parse("$baseUrl/api/locations/provinces")
        .replace(queryParameters: {"regionCode": regionCode});
    final res = await apiHttp.get(uri);
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || decoded["ok"] != true) {
      throw Exception(decoded["error"] ?? "Error provincias");
    }
    final data = (decoded["data"] as List).cast<Map<String, dynamic>>();
    return data.map(ProvinciaCL.fromJson).toList();
  }

  Future<List<ComunaCL>> fetchCommunes(String provinceCode) async {
    final uri = Uri.parse("$baseUrl/api/locations/communes")
        .replace(queryParameters: {"provinceCode": provinceCode});
    final res = await apiHttp.get(uri);
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || decoded["ok"] != true) {
      throw Exception(decoded["error"] ?? "Error comunas");
    }
    final data = (decoded["data"] as List).cast<Map<String, dynamic>>();
    return data.map(ComunaCL.fromJson).toList();
  }
}
