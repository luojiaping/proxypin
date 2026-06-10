import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/network/components/host_filter.dart';
import 'package:proxypin/network/bin/configuration.dart';

/// Register domain filter MCP tools.
void registerFilterTools(McpServer server) {
  server.registerTool(
    'filter_get_config',
    description: 'Get domain whitelist and blacklist configuration.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      return CallToolResult(
        content: [TextContent(text: jsonEncode({
          'whitelist': HostFilter.whitelist.toJson(),
          'blacklist': HostFilter.blacklist.toJson(),
        }))],
      );
    },
  );

  server.registerTool(
    'filter_add_whitelist',
    description: 'Add a domain pattern to the whitelist (supports wildcards like *.example.com).',
    inputSchema: JsonSchema.object(
      properties: {
        'pattern': JsonSchema.string(description: 'Domain pattern (regex or wildcard)'),
      },
      required: ['pattern'],
    ),
    callback: (args, extra) async {
      HostFilter.whitelist.add(args['pattern'] as String);
      final config = await Configuration.instance;
      await config.flushConfig();
      return CallToolResult(content: [TextContent(text: 'Added to whitelist')]);
    },
  );

  server.registerTool(
    'filter_add_blacklist',
    description: 'Add a domain pattern to the blacklist.',
    inputSchema: JsonSchema.object(
      properties: {
        'pattern': JsonSchema.string(description: 'Domain pattern (regex or wildcard)'),
      },
      required: ['pattern'],
    ),
    callback: (args, extra) async {
      HostFilter.blacklist.add(args['pattern'] as String);
      final config = await Configuration.instance;
      await config.flushConfig();
      return CallToolResult(content: [TextContent(text: 'Added to blacklist')]);
    },
  );

  server.registerTool(
    'filter_remove_whitelist',
    description: 'Remove whitelist entries by index.',
    inputSchema: JsonSchema.object(
      properties: {
        'indexes': JsonSchema.array(items: JsonSchema.integer(), description: 'Indexes to remove'),
      },
      required: ['indexes'],
    ),
    callback: (args, extra) async {
      final idx = (args['indexes'] as List).cast<int>();
      HostFilter.whitelist.removeIndex(idx);
      final config = await Configuration.instance;
      await config.flushConfig();
      return CallToolResult(content: [TextContent(text: 'Removed')]);
    },
  );

  server.registerTool(
    'filter_remove_blacklist',
    description: 'Remove blacklist entries by index.',
    inputSchema: JsonSchema.object(
      properties: {
        'indexes': JsonSchema.array(items: JsonSchema.integer(), description: 'Indexes to remove'),
      },
      required: ['indexes'],
    ),
    callback: (args, extra) async {
      final idx = (args['indexes'] as List).cast<int>();
      HostFilter.blacklist.removeIndex(idx);
      final config = await Configuration.instance;
      await config.flushConfig();
      return CallToolResult(content: [TextContent(text: 'Removed')]);
    },
  );

  server.registerTool(
    'filter_toggle_whitelist',
    description: 'Enable or disable the whitelist.',
    inputSchema: JsonSchema.object(
      properties: {
        'enabled': JsonSchema.boolean(required: true),
      },
      required: ['enabled'],
    ),
    callback: (args, extra) async {
      HostFilter.whitelist.enabled = args['enabled'] as bool;
      final config = await Configuration.instance;
      await config.flushConfig();
      return CallToolResult(content: [TextContent(text: 'Whitelist enabled: ' + args['enabled'].toString())]);
    },
  );

  server.registerTool(
    'filter_toggle_blacklist',
    description: 'Enable or disable the blacklist.',
    inputSchema: JsonSchema.object(
      properties: {
        'enabled': JsonSchema.boolean(required: true),
      },
      required: ['enabled'],
    ),
    callback: (args, extra) async {
      HostFilter.blacklist.enabled = args['enabled'] as bool;
      final config = await Configuration.instance;
      await config.flushConfig();
      return CallToolResult(content: [TextContent(text: 'Blacklist enabled: ' + args['enabled'].toString())]);
    },
  );
}
