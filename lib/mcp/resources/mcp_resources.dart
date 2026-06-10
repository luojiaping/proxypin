import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/network/bin/configuration.dart';
import 'package:proxypin/network/bin/server.dart';
import 'package:proxypin/native/vpn.dart';
import 'package:proxypin/ui/configuration.dart';

/// Register MCP Resources (read-only data sources).
void registerMcpResources(McpServer server) {
  server.registerResource(
    'Proxy Configuration',
    'proxy://config',
    null,
    (uri, extra) async {
      final config = await Configuration.instance;
      return ReadResourceResult(
        contents: [TextResourceContents(uri: 'proxy://config', text: jsonEncode(config.toJson()), mimeType: 'application/json')],
      );
    },
  );

  server.registerResource(
    'Proxy Status',
    'proxy://status',
    null,
    (uri, extra) async {
      final ps = ProxyServer.current;
      final vpnRunning = await Vpn.isRunning();
      return ReadResourceResult(
        contents: [TextResourceContents(
          uri: 'proxy://status',
          text: jsonEncode({
            'proxyRunning': ps?.isRunning ?? false,
            'proxyPort': ps?.port,
            'vpnRunning': vpnRunning,
            'appVersion': AppConfiguration.version,
          }),
          mimeType: 'application/json',
        )],
      );
    },
  );
}
