import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/network/components/manager/report_server_manager.dart';

void registerReportTools(McpServer server) {
  server.registerTool(
    'report_list_servers',
    description: 'List all configured report (webhook) servers.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      final manager = await ReportServerManager.instance;
      final servers = manager.servers.asMap().entries.map((e) => {
        'index': e.key,
        'name': e.value.name,
        'matchUrl': e.value.matchUrl,
        'serverUrl': e.value.serverUrl,
        'enabled': e.value.enabled,
        'compression': e.value.compression,
        'splitReport': e.value.splitReport,
      }).toList();
      return CallToolResult(content: [TextContent(text: jsonEncode(servers))]);
    },
  );

  server.registerTool(
    'report_add_server',
    description: 'Add a report server (webhook) for forwarding captured traffic.',
    inputSchema: JsonSchema.object(
      properties: {
        'name': JsonSchema.string(description: 'Server name'),
        'matchUrl': JsonSchema.string(description: 'URL pattern to match'),
        'serverUrl': JsonSchema.string(description: 'Report server URL to POST to'),
        'enabled': JsonSchema.boolean(description: 'Enable server (default true)'),
        'compression': JsonSchema.string(description: 'Compression: none or gzip'),
        'splitReport': JsonSchema.boolean(description: 'Split request and response reports (default false)'),
      },
    ),
    callback: (args, extra) async {
      try {
        final manager = await ReportServerManager.instance;
        final server = ReportServer(
          name: args['name'] as String,
          matchUrl: args['matchUrl'] as String,
          serverUrl: args['serverUrl'] as String,
          enabled: args['enabled'] as bool? ?? true,
          compression: args['compression'] as String? ?? 'none',
          splitReport: args['splitReport'] as bool? ?? false,
        );
        await manager.add(server);
        return CallToolResult(content: [TextContent(text: 'Report server added')]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'report_delete_server',
    description: 'Delete a report server by index.',
    inputSchema: JsonSchema.object(
      properties: {
        'index': JsonSchema.integer(),
      },
    ),
    callback: (args, extra) async {
      final manager = await ReportServerManager.instance;
      await manager.removeAt(args['index'] as int);
      return CallToolResult(content: [TextContent(text: 'Deleted')]);
    },
  );

  server.registerTool(
    'report_toggle_server',
    description: 'Enable or disable a report server by index.',
    inputSchema: JsonSchema.object(
      properties: {
        'index': JsonSchema.integer(),
        'enabled': JsonSchema.boolean(),
      },
    ),
    callback: (args, extra) async {
      final manager = await ReportServerManager.instance;
      await manager.toggleEnabled(args['index'] as int, args['enabled'] as bool);
      return CallToolResult(content: [TextContent(text: 'Toggled')]);
    },
  );
}
