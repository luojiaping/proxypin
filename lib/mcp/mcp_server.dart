import 'dart:io';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/mcp/mcp_config.dart';
import 'package:proxypin/mcp/mcp_traffic_listener.dart';
import 'package:proxypin/mcp/tools/proxy_tools.dart';
import 'package:proxypin/mcp/tools/traffic_tools.dart';
import 'package:proxypin/mcp/tools/vpn_tools.dart';
import 'package:proxypin/mcp/tools/filter_tools.dart';
import 'package:proxypin/mcp/tools/history_tools.dart';
import 'package:proxypin/mcp/tools/favorites_tools.dart';
import 'package:proxypin/mcp/tools/rewrite_tools.dart';
import 'package:proxypin/mcp/tools/map_tools.dart';
import 'package:proxypin/mcp/tools/block_tools.dart';
import 'package:proxypin/mcp/tools/breakpoint_tools.dart';
import 'package:proxypin/mcp/tools/script_tools.dart';
import 'package:proxypin/mcp/tools/hosts_tools.dart';
import 'package:proxypin/mcp/tools/crypto_tools.dart';
import 'package:proxypin/mcp/tools/cert_tools.dart';
import 'package:proxypin/mcp/tools/report_tools.dart';
import 'package:proxypin/mcp/tools/app_tools.dart';
import 'package:proxypin/mcp/tools/toolbox_tools.dart';
import 'package:proxypin/mcp/tools/request_tools.dart';
import 'package:proxypin/mcp/resources/mcp_resources.dart';
import 'package:proxypin/network/bin/server.dart';
import 'package:proxypin/network/util/logger.dart';
import 'package:proxypin/ui/configuration.dart';

/// ProxyPin MCP Server - exposes all proxy capabilities via MCP protocol.
class ProxyPinMcpServer {
  static ProxyPinMcpServer? _instance;

  McpServer? _server;
  HttpServer? _httpServer;
  McpTrafficListener trafficListener = McpTrafficListener();
  final McpServerConfig config;
  bool _running = false;

  ProxyPinMcpServer._(this.config);

  static ProxyPinMcpServer create(McpServerConfig config) {
    _instance = ProxyPinMcpServer._(config);
    return _instance!;
  }

  static ProxyPinMcpServer? get instance => _instance;

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;
    if (!config.enabled) return;

    try {
      // Register traffic listener with proxy server
      ProxyServer.current?.addListener(trafficListener);

      _server = McpServer(
        Implementation(name: 'proxypin', version: AppConfiguration.version),
        options: McpServerOptions(
          capabilities: ServerCapabilities(
            tools: ServerCapabilitiesTools(listChanged: true),
            resources: ServerCapabilitiesResources(subscribe: true, listChanged: true),
          ),
        ),
      );

      // Register all tools
      registerProxyTools(_server!);
      registerTrafficTools(_server!, trafficListener);
      registerVpnTools(_server!);
      registerFilterTools(_server!);
      registerHistoryTools(_server!);
      registerFavoritesTools(_server!);
      registerRewriteTools(_server!);
      registerMapTools(_server!);
      registerBlockTools(_server!);
      registerBreakpointTools(_server!);
      registerScriptTools(_server!);
      registerHostsTools(_server!);
      registerCryptoTools(_server!);
      registerCertTools(_server!);
      registerReportTools(_server!);
      registerAppTools(_server!);
      registerToolboxTools(_server!);
      registerRequestTools(_server!);

      // Register resources
      registerMcpResources(_server!);

      // Start Streamable HTTP server
      final transport = StreamableHTTPServerTransport(
        options: StreamableHTTPServerTransportOptions(),
      );
      await _server!.connect(transport);

      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, config.port);
      _running = true;

      _httpServer!.listen((HttpRequest request) {
        if (request.method == 'POST') {
          transport.handleRequest(request);
        } else if (request.method == 'GET' || request.method == 'DELETE') {
          transport.handleRequest(request);
        } else {
          request.response.statusCode = 405;
          request.response.close();
        }
      });

      logger.i('MCP Server started on port ${config.port}');
    } catch (e) {
      logger.e('Failed to start MCP Server', error: e);
      _running = false;
      rethrow;
    }
  }

  Future<void> stop() async {
    if (!_running) return;
    try {
      await _server?.close();
      await _httpServer?.close(force: true);
      ProxyServer.current?.listeners.remove(trafficListener);
      _running = false;
      logger.i('MCP Server stopped');
    } catch (e) {
      logger.e('Error stopping MCP Server', error: e);
    }
  }

  Future<void> restart() async {
    await stop();
    await start();
  }
}
