import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/network/components/manager/script_manager.dart';

void registerScriptTools(McpServer server) {
  server.registerTool(
    'script_list',
    description: 'List all JavaScript scripts used for traffic interception.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      final manager = await ScriptManager.instance;
      final scripts = manager.list.asMap().entries.map((e) => {
        'index': e.key,
        'name': e.value.name,
        'urls': e.value.urls,
        'enabled': e.value.enabled,
        'scriptPath': e.value.scriptPath,
        'remoteUrl': e.value.remoteUrl,
      }).toList();
      return CallToolResult(
        content: [TextContent(text: jsonEncode({'enabled': manager.enabled, 'scripts': scripts}))],
      );
    },
  );

  server.registerTool(
    'script_add',
    description: 'Add a new JavaScript interception script.',
    inputSchema: JsonSchema.object(
      properties: {
        'name': JsonSchema.string(description: 'Script name'),
        'urls': JsonSchema.array(items: JsonSchema.string(), description: 'URL patterns to match'),
        'script': JsonSchema.string(description: 'JavaScript code with onRequest/onResponse functions'),
        'enabled': JsonSchema.boolean(description: 'Enable script (default true)'),
      },
    ),
    callback: (args, extra) async {
      try {
        final manager = await ScriptManager.instance;
        final item = ScriptItem(
          args['enabled'] as bool? ?? true,
          args['name'] as String,
          args['urls'] as List,
        );
        await manager.addScript(item, args['script'] as String);
        await manager.flushConfig();
        return CallToolResult(content: [TextContent(text: 'Script added')]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'script_delete',
    description: 'Delete a script by index.',
    inputSchema: JsonSchema.object(
      properties: {
        'index': JsonSchema.integer(required: true),
      },
    ),
    callback: (args, extra) async {
      final manager = await ScriptManager.instance;
      await manager.removeScript(args['index'] as int);
      await manager.flushConfig();
      return CallToolResult(content: [TextContent(text: 'Deleted')]);
    },
  );

  server.registerTool(
    'script_toggle',
    description: 'Enable or disable the script system.',
    inputSchema: JsonSchema.object(
      properties: {
        'enabled': JsonSchema.boolean(required: true),
      },
    ),
    callback: (args, extra) async {
      final manager = await ScriptManager.instance;
      manager.enabled = args['enabled'] as bool;
      await manager.flushConfig();
      return CallToolResult(content: [TextContent(text: 'Script enabled: ' + args['enabled'].toString())]);
    },
  );
}
