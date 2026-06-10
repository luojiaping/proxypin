import 'dart:convert';
import 'dart:io';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/utils/curl.dart';
import 'package:proxypin/network/http/http.dart';
import 'package:proxypin/mcp/mcp_traffic_listener.dart';
import 'package:proxypin/mcp/mcp_server.dart';

void registerRequestTools(McpServer server) {
  server.registerTool(
    'request_send',
    description: 'Send an HTTP request and return the response. Does not go through the proxy.',
    inputSchema: JsonSchema.object(
      properties: {
        'method': JsonSchema.string(description: 'HTTP method (GET, POST, PUT, DELETE, etc.)'),
        'url': JsonSchema.string(description: 'Full URL'),
        'headers': JsonSchema.object(description: 'Request headers as key-value map'),
        'body': JsonSchema.string(description: 'Request body'),
        'followRedirects': JsonSchema.boolean(description: 'Follow redirects (default true)'),
      },
      required: ['method', 'url'],
    ),
    callback: (args, extra) async {
      try {
        final method = (args['method'] as String).toUpperCase();
        final url = Uri.parse(args['url'] as String);
        final client = HttpClient();
        client.connectionTimeout = Duration(seconds: 30);

        HttpClientRequest req;
        switch (method) {
          case 'GET': req = await client.getUrl(url); break;
          case 'POST': req = await client.postUrl(url); break;
          case 'PUT': req = await client.putUrl(url); break;
          case 'DELETE': req = await client.deleteUrl(url); break;
          case 'PATCH': req = await client.patchUrl(url); break;
          case 'HEAD': req = await client.headUrl(url); break;
          default: req = await client.openUrl(method, url);
        }

        final headers = args['headers'] as Map<String, dynamic>?;
        if (headers != null) {
          headers.forEach((key, value) => req.headers.set(key, value.toString()));
        }

        final body = args['body'] as String?;
        if (body != null && body.isNotEmpty) {
          req.write(body);
        }

        final followRedirects = args['followRedirects'] as bool? ?? true;
        client.followRedirects = followRedirects;

        final res = await req.close().timeout(Duration(seconds: 30));
        final responseBody = await res.transform(utf8.decoder).join();
        final responseHeaders = <String, String>{};
        res.headers.forEach((name, values) {
          responseHeaders[name] = values.join(', ');
        });

        client.close();

        return CallToolResult(content: [TextContent(text: jsonEncode({
          'statusCode': res.statusCode,
          'headers': responseHeaders,
          'body': responseBody,
          'contentLength': responseBody.length,
        }))]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Request failed: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'request_repeat',
    description: 'Replay a captured request by its requestId, optionally modifying it.',
    inputSchema: JsonSchema.object(
      properties: {
        'requestId': JsonSchema.string(description: 'Request ID to replay'),
        'modifiedUrl': JsonSchema.string(description: 'Override URL'),
        'modifiedMethod': JsonSchema.string(description: 'Override HTTP method'),
        'modifiedHeaders': JsonSchema.object(description: 'Override headers'),
        'modifiedBody': JsonSchema.string(description: 'Override body'),
      },
      required: ['requestId'],
    ),
    callback: (args, extra) async {
      try {
        final mcpServer = ProxyPinMcpServer.instance;
        final original = mcpServer?.trafficListener.getById(args['requestId'] as String);
        if (original == null) {
          return CallToolResult(isError: true, content: [TextContent(text: 'Request not found')]);
        }

        final url = Uri.parse(args['modifiedUrl'] as String? ?? original.requestUrl);
        final method = (args['modifiedMethod'] as String? ?? original.method.name).toUpperCase();
        final client = HttpClient();
        client.connectionTimeout = Duration(seconds: 30);

        HttpClientRequest req;
        switch (method) {
          case 'GET': req = await client.getUrl(url); break;
          case 'POST': req = await client.postUrl(url); break;
          case 'PUT': req = await client.putUrl(url); break;
          case 'DELETE': req = await client.deleteUrl(url); break;
          default: req = await client.openUrl(method, url);
        }

        // Set original headers
        original.headers.forEach((name, values) {
          for (var v in values) {
            req.headers.set(name, v);
          }
        });
        // Override headers
        final modHeaders = args['modifiedHeaders'] as Map<String, dynamic>?;
        if (modHeaders != null) {
          modHeaders.forEach((key, value) => req.headers.set(key, value.toString()));
        }

        final body = args['modifiedBody'] as String? ?? original.bodyAsString;
        if (body.isNotEmpty) {
          req.write(body);
        }

        final res = await req.close().timeout(Duration(seconds: 30));
        final responseBody = await res.transform(utf8.decoder).join();
        client.close();

        return CallToolResult(content: [TextContent(text: jsonEncode({
          'statusCode': res.statusCode,
          'body': responseBody,
          'contentLength': responseBody.length,
        }))]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Request failed: ' + e.toString())]);
      }
    },
  );
}
