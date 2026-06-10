import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/native/vpn.dart';
import 'package:proxypin/network/bin/configuration.dart';
import 'package:proxypin/network/bin/server.dart';

/// Register VPN control MCP tools (Android only).
void registerVpnTools(McpServer server) {
  server.registerTool(
    'vpn_start',
    description: 'Start VPN mode on Android. Intercepts traffic at device level.',
    inputSchema: JsonSchema.object(
      properties: {
        'ipProxy': JsonSchema.boolean(description: 'Enable IP-level proxy (default false)'),
      },
    ),
    callback: (args, extra) async {
      try {
        final ps = ProxyServer.current;
        if (ps == null) {
          return CallToolResult(isError: true, content: [TextContent(text: 'ProxyServer not initialized')]);
        }
        final config = await Configuration.instance;
        Vpn.startVpn('127.0.0.1', ps.port, config, ipProxy: args['ipProxy'] as bool? ?? false);
        return CallToolResult(content: [TextContent(text: jsonEncode({'status': 'vpn_started'}))]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'vpn_stop',
    description: 'Stop VPN on Android.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      Vpn.stopVpn();
      return CallToolResult(content: [TextContent(text: jsonEncode({'status': 'vpn_stopped'}))]);
    },
  );

  server.registerTool(
    'vpn_status',
    description: 'Check VPN running status on Android.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      final running = await Vpn.isRunning();
      return CallToolResult(
        content: [TextContent(text: jsonEncode({'vpnRunning': running, 'vpnStarted': Vpn.isVpnStarted}))],
      );
    },
  );
}
