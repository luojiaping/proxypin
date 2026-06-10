import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/network/components/manager/hosts_manager.dart';

void registerHostsTools(McpServer server) {
  server.registerTool(
    'hosts_list',
    description: 'List all host mapping rules.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      final manager = await HostsManager.instance;
      final hosts = manager.list.where((h) => !h.isFolder).map((h) => {
        'id': h.id,
        'host': h.host,
        'toAddress': h.toAddress,
        'enabled': h.enabled,
      }).toList();
      return CallToolResult(
        content: [TextContent(text: jsonEncode({'enabled': manager.enabled, 'hosts': hosts}))],
      );
    },
  );

  server.registerTool(
    'hosts_add',
    description: 'Add a host mapping rule (e.g., redirect domain to specific IP).',
    inputSchema: JsonSchema.object(
      properties: {
        'host': JsonSchema.string(description: 'Domain pattern to match'),
        'toAddress': JsonSchema.string(description: 'Target IP or domain'),
        'enabled': JsonSchema.boolean(description: 'Enable rule (default true)'),
      },
    ),
    callback: (args, extra) async {
      final manager = await HostsManager.instance;
      final item = HostsItem(
        host: args['host'] as String,
        toAddress: args['toAddress'] as String,
        enabled: args['enabled'] as bool? ?? true,
      );
      await manager.addHosts(item);
      await manager.flushConfig();
      return CallToolResult(content: [TextContent(text: 'Host mapping added')]);
    },
  );

  server.registerTool(
    'hosts_remove',
    description: 'Remove host mappings by IDs.',
    inputSchema: JsonSchema.object(
      properties: {
        'ids': JsonSchema.array(items: JsonSchema.string(), description: 'Host mapping IDs to remove'),
      },
    ),
    callback: (args, extra) async {
      final manager = await HostsManager.instance;
      final ids = (args['ids'] as List).cast<String>().toSet();
      final toRemove = manager.list.where((h) => ids.contains(h.id)).toList();
      await manager.removeHosts(toRemove);
      return CallToolResult(content: [TextContent(text: 'Removed')]);
    },
  );

  server.registerTool(
    'hosts_toggle',
    description: 'Enable or disable the hosts system.',
    inputSchema: JsonSchema.object(
      properties: {
        'enabled': JsonSchema.boolean(),
      },
    ),
    callback: (args, extra) async {
      final manager = await HostsManager.instance;
      manager.enabled = args['enabled'] as bool;
      await manager.flushConfig();
      return CallToolResult(content: [TextContent(text: 'Hosts enabled: ' + args['enabled'].toString())]);
    },
  );
}
