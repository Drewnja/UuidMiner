import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io'; // Added import for Platform

class UUIDMinerApiService {
  final _uuid = Uuid();

  Future<void> start() async {
    var handler = Pipeline().addMiddleware(logRequests()).addHandler(_handleRequest);
    
    // Use environment variables with fallbacks
    var host = Platform.environment['HOST'] ?? '0.0.0.0';
    var port = int.parse(Platform.environment['PORT'] ?? '8080');
    
    var server = await shelf_io.serve(handler, host, port);
    print('Server running on ${server.address.host}:${server.port}');
  }

  Future<Response> _handleRequest(Request request) async {
    if (request.method == 'POST' && request.url.path == 'mine') {
      return _handleMine(request);
    }
    return Response.notFound('Not Found');
  }

  Future<Response> _handleMine(Request request) async {
    var body = await request.readAsString();
    var data = json.decode(body);
    var pattern = data['pattern'];
    if (pattern == null) {
      return Response.badRequest(body: 'Missing pattern parameter');
    }

    var result = await _mineUUID(pattern);
    return Response.ok(json.encode(result));
  }

  Future<Map<String, dynamic>> _mineUUID(String pattern) async {
    int attempts = 0;
    pattern = pattern.toLowerCase();

    while (true) {
      attempts++;
      var generatedUUID = _uuid.v4();
      if (generatedUUID.toLowerCase().contains(pattern)) {
        return {
          'minedUUID': generatedUUID,
          'attempts': attempts,
        };
      }
      if (attempts % 1000 == 0) {
        await Future.delayed(Duration.zero);
      }
    }
  }
}

void main() async {
  var service = UUIDMinerApiService();
  await service.start();
}