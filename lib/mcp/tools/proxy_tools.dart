import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/network/bin/configuration.dart';
import 'package:proxypin/network/bin/server.dart';
import 'package:proxypin/ui/configuration.dart';

/// Register proxy control MCP tools.
void registerProxyTools(McpServer server) {
  server.registerTool(
    'proxy_start',
    description: 'Start the ProxyPin proxy server.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      try {
        final ps = ProxyServer.current;
        if (ps == null) {
          return CallToolResult(isError: true, content: [TextContent(text: 'ProxyServer not initialized')]);
        }
        if (ps.isRunning) {
          return CallToolResult(content: [TextContent(text: jsonEncode({'status': 'already_running', 'port': ps.port}))]);
        }
        await ps.start();
        return CallToolResult(content: [TextContent(text: jsonEncode({'status': 'started', 'port': ps.port}))]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: \$e')]);
      }
    },
  );

  server.registerTool(
    'proxy_stop',
    description: 'Stop the ProxyPin proxy server.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      try {
        final ps = ProxyServer.current;
        if (ps == null || !ps.isRunning) {
          return CallToolResult(content: [TextContent(text: jsonEncode({'status': 'not_running'}))]);
        }
        await ps.stop();
        return CallToolResult(content: [TextContent(text: jsonEncode({'status': 'stopped'}))]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: \$e')]);
      }
    },
  );

  server.registerTool(
    'proxy_restart',
    description: 'Restart the ProxyPin proxy server.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      try {
        final ps = ProxyServer.current;
        if (ps == null) {
          return CallToolResult(isError: true, content: [TextContent(text: 'ProxyServer not initialized')]);
        }
        await ps.restart();
        return CallToolResult(content: [TextContent(text: jsonEncode({'status': 'restarted', 'port': ps.port, 'running': ps.isRunning}))]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: \$e')]);
      }
    },
  );

  server.registerTool(
    'proxy_status',
    description: 'Get current proxy server status and configuration summary.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      final ps = ProxyServer.current;
      final config = await Configuration.instance;
      return CallToolResult(
        content: [TextContent(text: jsonEncode({
          'running': ps?.isRunning ?? false,
          'port': config.port,
          'enableSsl': config.enableSsl,
          'enableSystemProxy': config.enableSystemProxy,
          'enableSocks5': config.enableSocks5,
          'enabledHttp2': config.enabledHttp2,
          'proxyPassDomains': config.proxyPassDomains,
          'historyCacheTime': config.historyCacheTime,
          'startup': config.startup,
          'appVersion': AppConfiguration.version,
        }))],
      );
    },
  );

  server.registerTool(
    'proxy_get_config',
    description: 'Get the full proxy configuration as JSON.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      final config = await Configuration.instance;
      return CallToolResult(content: [TextContent(text: jsonEncode(config.toJson()))]);
    },
  );

  server.registerTool(
    'proxy_update_config',
    description: 'Update proxy configuration. Only provided fields are updated.',
    inputSchema: JsonSchema.object(
      properties: {
        'port': JsonSchema.integer(description: 'Proxy port number'),
        'enableSsl': JsonSchema.boolean(description: 'Enable HTTPS interception'),
        'enableSystemProxy': JsonSchema.boolean(description: 'Enable system proxy'),
        'enableSocks5': JsonSchema.boolean(description: 'Enable SOCKS5 proxy'),
        'enabledHttp2': JsonSchema.boolean(description: 'Enable HTTP/2'),
        'proxyPassDomains': JsonSchema.string(description: 'Semicolon-separated domains to bypass'),
        'historyCacheTime': JsonSchema.integer(description: 'History cache time in days'),
        'startup': JsonSchema.boolean(description: 'Auto-start proxy on app launch'),
      },
    ),
    callback: (args, extra) async {
      try {
        final config = await Configuration.instance;
        if (args.containsKey('port')) config.port = args['port'] as int;
        if (args.containsKey('enableSsl')) config.enableSsl = args['enableSsl'] as bool;
        if (args.containsKey('enableSystemProxy')) config.enableSystemProxy = args['enableSystemProxy'] as bool;
        if (args.containsKey('enableSocks5')) config.enableSocks5 = args['enableSocks5'] as bool;
        if (args.containsKey('enabledHttp2')) config.enabledHttp2 = args['enabledHttp2'] as bool;
        if (args.containsKey('proxyPassDomains')) config.proxyPassDomains = args['proxyPassDomains'] as String;
        if (args.containsKey('historyCacheTime')) config.historyCacheTime = args['historyCacheTime'] as int;
        if (args.containsKey('startup')) config.startup = args['startup'] as bool;
        await config.flushConfig();
        return CallToolResult(content: [TextContent(text: jsonEncode({'status': 'updated', 'config': config.toJson()}))]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: \$e')]);
      }
    },
  );
}
