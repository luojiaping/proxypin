import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/network/components/manager/request_block_manager.dart';

void registerBlockTools(McpServer server) {
  server.registerTool(
    'block_list_rules',
    description: 'List all request blocking rules.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      final manager = await RequestBlockManager.instance;
      final rules = manager.list.asMap().entries.map((e) => {
        'index': e.key,
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
    'block_add_rule',
    description: 'Add a blocking rule. type: blockRequest or blockResponse.',
    inputSchema: JsonSchema.object(
      properties: {
        'url': JsonSchema.string(description: 'URL pattern to block'),
        'type': JsonSchema.string(description: 'blockRequest or blockResponse'),
        'enabled': JsonSchema.boolean(description: 'Enable rule (default true)'),
      },
    ),
    callback: (args, extra) async {
      final manager = await RequestBlockManager.instance;
      final item = RequestBlockItem(
        args['enabled'] as bool? ?? true,
        args['url'] as String,
        BlockType.nameOf(args['type'] as String),
      );
      manager.addBlockRequest(item);
      return CallToolResult(content: [TextContent(text: 'Block rule added')]);
    },
  );

  server.registerTool(
    'block_remove_rule',
    description: 'Remove a blocking rule by index.',
    inputSchema: JsonSchema.object(
      properties: {
        'index': JsonSchema.integer(required: true),
      },
    ),
    callback: (args, extra) async {
      final manager = await RequestBlockManager.instance;
      manager.removeBlockRequest(args['index'] as int);
      return CallToolResult(content: [TextContent(text: 'Removed')]);
    },
  );

  server.registerTool(
    'block_toggle',
    description: 'Enable or disable the blocking system.',
    inputSchema: JsonSchema.object(
      properties: {
        'enabled': JsonSchema.boolean(required: true),
      },
    ),
    callback: (args, extra) async {
      final manager = await RequestBlockManager.instance;
      manager.enabled = args['enabled'] as bool;
      await manager.flushConfig();
      return CallToolResult(content: [TextContent(text: 'Block enabled: ' + args['enabled'].toString())]);
    },
  );
}
