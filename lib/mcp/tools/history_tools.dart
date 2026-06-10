import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/storage/histories.dart';

void registerHistoryTools(McpServer server) {
  server.registerTool(
    'history_list',
    description: 'List saved traffic history sessions.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      final storage = await HistoryStorage.instance;
      final items = storage.histories.asMap().entries.map((e) => {
        'index': e.key,
        'name': e.value.name,
        'requestCount': e.value.requestLength,
        'fileSize': e.value.size,
        'createTime': e.value.createTime.toIso8601String(),
      }).toList();
      return CallToolResult(content: [TextContent(text: jsonEncode(items))]);
    },
  );

  server.registerTool(
    'history_get_requests',
    description: 'Get HTTP requests from a history session.',
    inputSchema: JsonSchema.object(
      properties: {
        'index': JsonSchema.integer(description: 'History session index'),
      },
    ),
    callback: (args, extra) async {
      final storage = await HistoryStorage.instance;
      final idx = args['index'] as int;
      if (idx < 0 || idx >= storage.histories.length) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Invalid index')]);
      }
      final requests = await storage.getRequests(storage.histories[idx]);
      final har = requests.map((r) => {
        'requestId': r.requestId,
        'method': r.method.name,
        'url': r.requestUrl,
        'statusCode': r.response?.status.code,
        'requestTime': r.requestTime.toIso8601String(),
      }).toList();
      return CallToolResult(content: [TextContent(text: jsonEncode({'count': requests.length, 'requests': har}))]);
    },
  );

  server.registerTool(
    'history_delete',
    description: 'Delete a history session by index.',
    inputSchema: JsonSchema.object(
      properties: {
        'index': JsonSchema.integer(description: 'History session index to delete'),
      },
    ),
    callback: (args, extra) async {
      final storage = await HistoryStorage.instance;
      await storage.removeHistory(args['index'] as int);
      return CallToolResult(content: [TextContent(text: 'Deleted')]);
    },
  );
}
