import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/network/components/manager/request_map_manager.dart';

void registerMapTools(McpServer server) {
  server.registerTool(
    'map_list_rules',
    description: 'List all request mapping rules.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      final manager = await RequestMapManager.instance;
      final rules = manager.rules.asMap().entries.map((e) => {
        'index': e.key,
        'name': e.value.name,
        'url': e.value.url,
        'type': e.value.type.name,
        'enabled': e.value.enabled,
      }).toList();
      return CallToolResult(
        content: [TextContent(text: jsonEncode({'enabled': manager.enabled, 'rules': rules}))],
      );
    },
  );

  server.registerTool(
    'map_add_rule',
    description: 'Add a request mapping rule. type: local (return custom response) or script (execute JS).',
    inputSchema: JsonSchema.object(
      properties: {
        'url': JsonSchema.string(description: 'URL pattern'),
        'type': JsonSchema.string(description: 'Mapping type: local or script'),
        'name': JsonSchema.string(description: 'Rule name'),
        'enabled': JsonSchema.boolean(description: 'Enable rule (default true)'),
        'statusCode': JsonSchema.integer(description: 'HTTP status code for local mapping (default 200)'),
        'headers': JsonSchema.object(description: 'Response headers map for local mapping'),
        'body': JsonSchema.string(description: 'Response body text for local mapping'),
        'script': JsonSchema.string(description: 'JavaScript code for script mapping'),
      },
    ),
    callback: (args, extra) async {
      try {
        final manager = await RequestMapManager.instance;
        final rule = RequestMapRule(
          enabled: args['enabled'] as bool? ?? true,
          name: args['name'] as String?,
          url: args['url'] as String,
          type: RequestMapType.fromName(args['type'] as String),
        );
        final item = RequestMapItem(
          statusCode: args['statusCode'] as int? ?? 200,
          headers: (args['headers'] as Map?)?.cast<String, String>(),
          body: args['body'] as String?,
          script: args['script'] as String?,
        );
        await manager.addRule(rule, item);
        return CallToolResult(content: [TextContent(text: 'Mapping rule added')]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'map_delete_rule',
    description: 'Delete a mapping rule by index.',
    inputSchema: JsonSchema.object(
      properties: {
        'index': JsonSchema.integer(),
      },
    ),
    callback: (args, extra) async {
      final manager = await RequestMapManager.instance;
      await manager.deleteRule(args['index'] as int);
      return CallToolResult(content: [TextContent(text: 'Deleted')]);
    },
  );

  server.registerTool(
    'map_toggle',
    description: 'Enable or disable the request mapping system.',
    inputSchema: JsonSchema.object(
      properties: {
        'enabled': JsonSchema.boolean(),
      },
    ),
    callback: (args, extra) async {
      final manager = await RequestMapManager.instance;
      manager.enabled = args['enabled'] as bool;
      await manager.flushConfig();
      return CallToolResult(content: [TextContent(text: 'Map enabled: ' + args['enabled'].toString())]);
    },
  );
}
