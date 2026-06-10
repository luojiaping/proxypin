/// MCP Server configuration.
class McpServerConfig {
  bool enabled;
  int port;

  McpServerConfig({this.enabled = false, this.port = 9100});

  factory McpServerConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return McpServerConfig();
    return McpServerConfig(
      enabled: json['enabled'] ?? false,
      port: json['port'] ?? 9100,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'port': port,
      };
}
