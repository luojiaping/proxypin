import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/native/installed_apps.dart';
import 'package:proxypin/native/process_info.dart';

void registerAppTools(McpServer server) {
  server.registerTool(
    'app_list_installed',
    description: 'List installed apps on Android. Useful for app-based proxy filtering.',
    inputSchema: JsonSchema.object(
      properties: {
        'includeSystemApps': JsonSchema.boolean(description: 'Include system apps (default false)'),
        'packageNamePrefix': JsonSchema.string(description: 'Filter by package name prefix'),
      },
    ),
    callback: (args, extra) async {
      try {
        final apps = await InstalledApps.getInstalledApps(
          false,
          includeSystemApps: args['includeSystemApps'] as bool? ?? false,
          packageNamePrefix: args['packageNamePrefix'] as String?,
        );
        final list = apps.map((a) => {
          'name': a.name,
          'packageName': a.packageName,
          'versionName': a.versionName,
        }).toList();
        return CallToolResult(content: [TextContent(text: jsonEncode({'count': list.length, 'apps': list}))]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'app_get_info',
    description: 'Get detailed info for a specific installed app.',
    inputSchema: JsonSchema.object(
      properties: {
        'packageName': JsonSchema.string(description: 'Android package name'),
      },
    ),
    callback: (args, extra) async {
      try {
        final info = await InstalledApps.getAppInfo(args['packageName'] as String);
        return CallToolResult(
          content: [TextContent(text: jsonEncode({
            'name': info.name,
            'packageName': info.packageName,
            'versionName': info.versionName,
          }))],
        );
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'app_get_process_by_port',
    description: 'Get the process/app that owns a given network port.',
    inputSchema: JsonSchema.object(
      properties: {
        'host': JsonSchema.string(description: 'Host address'),
        'port': JsonSchema.integer(description: 'Port number'),
      },
    ),
    callback: (args, extra) async {
      try {
        final process = await ProcessInfoPlugin.getProcessByPort(
          args['host'] as String,
          args['port'] as int,
        );
        if (process == null) {
          return CallToolResult(content: [TextContent(text: 'No process found for this port')]);
        }
        return CallToolResult(
          content: [TextContent(text: jsonEncode({
            'packageName': process.packageName,
            'name': process.name,
          }))],
        );
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );
}
