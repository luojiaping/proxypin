import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/network/components/manager/request_breakpoint_manager.dart';
import 'package:proxypin/network/components/request_breakpoint.dart';
import 'package:proxypin/network/http/http.dart';

void registerBreakpointTools(McpServer server) {
  server.registerTool(
    'breakpoint_list_rules',
    description: 'List all breakpoint rules.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      final manager = await RequestBreakpointManager.instance;
      final rules = manager.list.asMap().entries.map((e) => {
        'index': e.key,
        'url': e.value.url,
        'enabled': e.value.enabled,
        'name': e.value.name,
        'interceptRequest': e.value.interceptRequest,
        'interceptResponse': e.value.interceptResponse,
        'method': e.value.method?.name,
      }).toList();
      return CallToolResult(
        content: [TextContent(text: jsonEncode({'enabled': manager.enabled, 'rules': rules}))],
      );
    },
  );

  server.registerTool(
    'breakpoint_add_rule',
    description: 'Add a breakpoint rule for request/response interception.',
    inputSchema: JsonSchema.object(
      properties: {
        'url': JsonSchema.string(description: 'URL pattern (regex)'),
        'name': JsonSchema.string(description: 'Rule name'),
        'enabled': JsonSchema.boolean(description: 'Enable rule (default true)'),
        'interceptRequest': JsonSchema.boolean(description: 'Intercept requests (default true)'),
        'interceptResponse': JsonSchema.boolean(description: 'Intercept responses (default true)'),
        'method': JsonSchema.string(description: 'HTTP method filter (GET, POST, etc.)'),
      },
    ),
    callback: (args, extra) async {
      final manager = await RequestBreakpointManager.instance;
      HttpMethod? method;
      if (args['method'] != null) method = HttpMethod.valueOf(args['method'] as String);
      final rule = RequestBreakpointRule(
        enabled: args['enabled'] as bool? ?? true,
        name: args['name'] as String?,
        url: args['url'] as String,
        interceptRequest: args['interceptRequest'] as bool? ?? true,
        interceptResponse: args['interceptResponse'] as bool? ?? true,
        method: method,
      );
      manager.add(rule);
      return CallToolResult(content: [TextContent(text: 'Breakpoint rule added')]);
    },
  );

  server.registerTool(
    'breakpoint_remove_rule',
    description: 'Remove a breakpoint rule by index.',
    inputSchema: JsonSchema.object(
      properties: {
        'index': JsonSchema.integer(required: true),
      },
    ),
    callback: (args, extra) async {
      final manager = await RequestBreakpointManager.instance;
      final idx = args['index'] as int;
      if (idx < 0 || idx >= manager.list.length) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Invalid index')]);
      }
      manager.remove(manager.list[idx]);
      return CallToolResult(content: [TextContent(text: 'Removed')]);
    },
  );

  server.registerTool(
    'breakpoint_toggle',
    description: 'Enable or disable the breakpoint system.',
    inputSchema: JsonSchema.object(
      properties: {
        'enabled': JsonSchema.boolean(required: true),
      },
    ),
    callback: (args, extra) async {
      final manager = await RequestBreakpointManager.instance;
      manager.enabled = args['enabled'] as bool;
      await manager.save();
      return CallToolResult(content: [TextContent(text: 'Breakpoint enabled: ' + args['enabled'].toString())]);
    },
  );
}
