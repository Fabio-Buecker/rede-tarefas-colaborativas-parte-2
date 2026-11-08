import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/registro_local.dart';

class RedeException implements Exception {
  final String mensagem;
  const RedeException(this.mensagem);
  @override
  String toString() => mensagem;
}

class ApiService {
  final http.Client client;
  final Uri endpoint;
  final Duration timeout;
  ApiService(
    this.client, {
    Uri? endpoint,
    this.timeout = const Duration(seconds: 8),
  }) : endpoint =
           endpoint ?? Uri.parse('https://jsonplaceholder.typicode.com/todos');

  Future<http.Response> _request(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RedeException(
          'API respondeu HTTP ${response.statusCode}. Pendências preservadas.',
        );
      }
      return response;
    } on TimeoutException {
      throw const RedeException('Tempo de conexão esgotado.');
    } on SocketException {
      throw const RedeException('Sem conexão com a internet.');
    } on http.ClientException {
      throw const RedeException('Não foi possível acessar a API.');
    } on RedeException {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> catalogo() async {
    final r = await _request(
      () => client.get(endpoint.replace(queryParameters: {'_limit': '10'})),
    );
    try {
      final values = jsonDecode(r.body) as List<dynamic>;
      return values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on FormatException {
      throw const RedeException('JSON inválido recebido da API.');
    } on TypeError {
      throw const RedeException('Formato inesperado do catálogo.');
    }
  }

  Future<int?> enviar(RegistroLocal r) async {
    final item = Uri.parse('${endpoint.toString()}/${r.remotoId}');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Idempotency-Key': '${r.tarefa.id}:${r.revisao}',
    };
    if (r.excluido) {
      if (r.remotoId != null) {
        await _request(() => client.delete(item, headers: headers));
      }
      return r.remotoId;
    }
    final response = await _request(
      () => r.remotoId == null
          ? client.post(endpoint, headers: headers, body: r.toJson())
          : client.put(item, headers: headers, body: r.toJson()),
    );
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final id = (body['id'] as num?)?.toInt();
      if (id == null || id <= 0) {
        throw const RedeException('API não confirmou um identificador válido.');
      }
      return id;
    } on FormatException {
      throw const RedeException('JSON inválido na confirmação.');
    } on TypeError {
      throw const RedeException('Confirmação em formato inesperado.');
    }
  }
}
