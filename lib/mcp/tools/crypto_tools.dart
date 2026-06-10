import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/network/components/manager/request_crypto_manager.dart';

void registerCryptoTools(McpServer server) {
  server.registerTool(
    'crypto_list_rules',
    description: 'List all request crypto/decryption rules.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      final manager = await RequestCryptoManager.instance;
      final rules = manager.rules.asMap().entries.map((e) => {
        'index': e.key,
        'name': e.value.name,
        'urlPattern': e.value.urlPattern,
        'field': e.value.field,
        'enabled': e.value.enabled,
        'mode': e.value.config.mode,
        'keyLength': e.value.config.keyLength,
      }).toList();
      return CallToolResult(
        content: [TextContent(text: jsonEncode({'enabled': manager.enabled, 'rules': rules}))],
      );
    },
  );

  server.registerTool(
    'crypto_add_rule',
    description: 'Add a crypto rule for automatic request/response decryption.',
    inputSchema: JsonSchema.object(
      properties: {
        'name': JsonSchema.string(description: 'Rule name'),
        'urlPattern': JsonSchema.string(description: 'URL pattern (regex)'),
        'field': JsonSchema.string(description: 'Field to decrypt (e.g., body, header)'),
        'enabled': JsonSchema.boolean(description: 'Enable rule (default true)'),
        'config': JsonSchema.object(
          properties: {
            'key': JsonSchema.string(description: 'Encryption key'),
            'iv': JsonSchema.string(description: 'IV for CBC mode'),
            'ivSource': JsonSchema.string(description: 'IV source: manual or prefix'),
            'ivPrefixLength': JsonSchema.integer(description: 'IV prefix length for prefix mode'),
            'mode': JsonSchema.string(description: 'AES mode: ECB or CBC'),
            'padding': JsonSchema.string(description: 'Padding: PKCS7'),
            'keyLength': JsonSchema.integer(description: 'Key length: 128, 192, or 256'),
          },
          description: 'Crypto configuration',
        ),
      },
    ),
    callback: (args, extra) async {
      try {
        final manager = await RequestCryptoManager.instance;
        final configMap = args['config'] as Map<String, dynamic>;
        final rule = CryptoRule(
          name: args['name'] as String,
          urlPattern: args['urlPattern'] as String,
          field: args['field'] as String?,
          enabled: args['enabled'] as bool? ?? true,
          config: CryptoKeyConfig(
            key: configMap['key'] as String? ?? '',
            iv: configMap['iv'] as String? ?? '',
            ivSource: configMap['ivSource'] as String? ?? 'manual',
            ivPrefixLength: configMap['ivPrefixLength'] as int? ?? 16,
            mode: configMap['mode'] as String? ?? 'ECB',
            padding: configMap['padding'] as String? ?? 'PKCS7',
            keyLength: configMap['keyLength'] as int? ?? 128,
          ),
        );
        await manager.addRule(rule);
        await manager.flushConfig();
        return CallToolResult(content: [TextContent(text: 'Crypto rule added')]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'crypto_delete_rule',
    description: 'Delete crypto rules by indexes.',
    inputSchema: JsonSchema.object(
      properties: {
        'indexes': JsonSchema.array(items: JsonSchema.integer(), description: 'Indexes to delete'),
      },
    ),
    callback: (args, extra) async {
      final manager = await RequestCryptoManager.instance;
      await manager.removeIndex((args['indexes'] as List).cast<int>());
      await manager.flushConfig();
      return CallToolResult(content: [TextContent(text: 'Deleted')]);
    },
  );

  server.registerTool(
    'crypto_toggle',
    description: 'Enable or disable the crypto system.',
    inputSchema: JsonSchema.object(
      properties: {
        'enabled': JsonSchema.boolean(),
      },
    ),
    callback: (args, extra) async {
      final manager = await RequestCryptoManager.instance;
      manager.enabled = args['enabled'] as bool;
      await manager.flushConfig();
      return CallToolResult(content: [TextContent(text: 'Crypto enabled: ' + args['enabled'].toString())]);
    },
  );
}
