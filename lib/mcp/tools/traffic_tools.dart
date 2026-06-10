import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/mcp/mcp_traffic_listener.dart';
import 'package:proxypin/utils/curl.dart';
import 'package:proxypin/utils/har.dart';

/// Register traffic viewing MCP tools.
void registerTrafficTools(McpServer server, McpTrafficListener listener) {
  server.registerTool(
    'traffic_list',
    description: 'List captured HTTP traffic records from current session.',
    inputSchema: JsonSchema.object(
      properties: {
        'limit': JsonSchema.integer(description: 'Max records to return (default 50)'),
        'offset': JsonSchema.integer(description: 'Number of records to skip'),
        'domain': JsonSchema.string(description: 'Filter by domain substring'),
        'method': JsonSchema.string(description: 'Filter by HTTP method (GET, POST, etc.)'),
        'status': JsonSchema.integer(description: 'Filter by response status code'),
        'contentType': JsonSchema.string(description: 'Filter by content type substring'),
        'keyword': JsonSchema.string(description: 'Search keyword in URL, request body, response body'),
      },
    ),
    callback: (args, extra) async {
      final results = listener.query(
        limit: args['limit'] as int? ?? 50,
        offset: args['offset'] as int? ?? 0,
        domain: args['domain'] as String?,
        method: args['method'] as String?,
        statusCode: args['status'] as int?,
        contentType: args['contentType'] as String?,
        keyword: args['keyword'] as String?,
      );
      final list = results.map((r) => {
        'requestId': r.requestId,
        'method': r.method.name,
        'url': r.requestUrl,
        'host': r.hostAndPort?.host,
        'statusCode': r.response?.status.code,
        'statusText': r.response?.status.reasonPhrase,
        'contentType': r.response?.headers.contentType,
        'requestTime': r.requestTime.toIso8601String(),
        'costTime': r.response?.costTime(),
      }).toList();
      return CallToolResult(
        content: [TextContent(text: jsonEncode({'count': listener.count, 'results': list}))],
      );
    },
  );

  server.registerTool(
    'traffic_get_detail',
    description: 'Get full detail of a specific HTTP request/response as HAR format.',
    inputSchema: JsonSchema.object(
      properties: {
        'requestId': JsonSchema.string(description: 'The request ID to retrieve'),
      },
      required: ['requestId'],
    ),
    callback: (args, extra) async {
      final request = listener.getById(args['requestId'] as String);
      if (request == null) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Request not found')]);
      }
      final har = Har.toHar(request);
      return CallToolResult(content: [TextContent(text: jsonEncode(har))]);
    },
  );

  server.registerTool(
    'traffic_get_curl',
    description: 'Get cURL command for a captured request.',
    inputSchema: JsonSchema.object(
      properties: {
        'requestId': JsonSchema.string(description: 'The request ID'),
      },
      required: ['requestId'],
    ),
    callback: (args, extra) async {
      final request = listener.getById(args['requestId'] as String);
      if (request == null) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Request not found')]);
      }
      return CallToolResult(content: [TextContent(text: curlRequest(request))]);
    },
  );

  server.registerTool(
    'traffic_export_har',
    description: 'Export captured traffic as HAR JSON string.',
    inputSchema: JsonSchema.object(
      properties: {
        'requestIds': JsonSchema.array(items: JsonSchema.string(), description: 'Specific request IDs to export. Empty = all'),
      },
    ),
    callback: (args, extra) async {
      List requests;
      if (args.containsKey('requestIds') && (args['requestIds'] as List).isNotEmpty) {
        final ids = (args['requestIds'] as List).cast<String>();
        requests = ids.map((id) => listener.getById(id)).where((r) => r != null).toList();
      } else {
        requests = listener.query(limit: 1000);
      }
      final harJson = await Har.writeJson(requests.cast());
      return CallToolResult(content: [TextContent(text: harJson)]);
    },
  );

  server.registerTool(
    'traffic_clear',
    description: 'Clear all captured traffic records in current session.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      listener.clear();
      return CallToolResult(content: [TextContent(text: 'Cleared')]);
    },
  );
}
