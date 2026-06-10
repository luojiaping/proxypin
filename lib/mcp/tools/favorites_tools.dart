import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/storage/favorites.dart';
import 'package:proxypin/mcp/mcp_traffic_listener.dart';
import 'package:proxypin/mcp/mcp_server.dart';

void registerFavoritesTools(McpServer server) {
  server.registerTool(
    'favorites_list',
    description: 'List all favorited requests.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      final favs = await FavoriteStorage.favorites;
      final list = favs.map((f) => {
        'requestId': f.request.requestId,
        'url': f.request.requestUrl,
        'method': f.request.method.name,
        'statusCode': f.response?.status.code,
        'name': f.name,
      }).toList();
      return CallToolResult(content: [TextContent(text: jsonEncode(list))]);
    },
  );

  server.registerTool(
    'favorites_add',
    description: 'Add a captured request to favorites by requestId.',
    inputSchema: JsonSchema.object(
      properties: {
        'requestId': JsonSchema.string(description: 'Request ID to favorite'),
      },
    ),
    callback: (args, extra) async {
      final mcpServer = ProxyPinMcpServer.instance;
      final request = mcpServer?.trafficListener.getById(args['requestId'] as String);
      if (request == null) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Request not found in buffer')]);
      }
      await FavoriteStorage.addFavorite(request);
      return CallToolResult(content: [TextContent(text: 'Added to favorites')]);
    },
  );

  server.registerTool(
    'favorites_remove',
    description: 'Remove a favorite by requestId.',
    inputSchema: JsonSchema.object(
      properties: {
        'requestId': JsonSchema.string(description: 'Request ID to remove from favorites'),
      },
    ),
    callback: (args, extra) async {
      final favs = await FavoriteStorage.favorites;
      final id = args['requestId'] as String;
      final match = favs.where((f) => f.request.requestId == id).toList();
      if (match.isEmpty) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Not found in favorites')]);
      }
      await FavoriteStorage.removeFavorite(match.first);
      return CallToolResult(content: [TextContent(text: 'Removed')]);
    },
  );
}
