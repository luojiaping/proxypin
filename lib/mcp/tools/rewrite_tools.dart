import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/network/components/manager/request_rewrite_manager.dart';
import 'package:proxypin/network/components/manager/rewrite_rule.dart';
import 'package:proxypin/network/http/http.dart';

void registerRewriteTools(McpServer server) {
  server.registerTool(
    'rewrite_list_rules',
    description: 'List all request rewrite rules.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      final manager = await RequestRewriteManager.instance;
      final rules = manager.rules.asMap().entries.map((e) => {
        'index': e.key,
        'name': e.value.name,
        'url': e.value.url,
        'type': e.value.type.name,
        'enabled': e.value.enabled,
        'method': e.value.method?.name,
      }).toList();
      return CallToolResult(
        content: [TextContent(text: jsonEncode({'enabled': manager.enabled, 'rules': rules}))],
      );
    },
  );

  server.registerTool(
    'rewrite_add_rule',
    description: 'Add a rewrite rule. type: redirect, requestReplace, responseReplace, requestUpdate, responseUpdate',
    inputSchema: JsonSchema.object(
      properties: {
        'url': JsonSchema.string(description: 'URL pattern (regex or wildcard)'),
        'type': JsonSchema.string(description: 'Rule type: redirect, requestReplace, responseReplace, requestUpdate, responseUpdate'),
        'name': JsonSchema.string(description: 'Rule name'),
        'enabled': JsonSchema.boolean(description: 'Enable this rule (default true)'),
        'method': JsonSchema.string(description: 'HTTP method filter (GET, POST, etc.)'),
        'items': JsonSchema.array(
          items: JsonSchema.object(properties: {
            'type': JsonSchema.string(description: 'RewriteType name'),
            'enabled': JsonSchema.boolean(),
            'values': JsonSchema.object(description: 'Rewrite values map'),
          }),
          description: 'Rewrite items list',
        ),
      },
      required: ['url', 'type', 'items'],
    ),
    callback: (args, extra) async {
      try {
        final manager = await RequestRewriteManager.instance;
        final ruleType = RuleType.fromName(args['type'] as String);
        HttpMethod? method;
        if (args['method'] != null) method = HttpMethod.valueOf(args['method'] as String);
        final rule = RequestRewriteRule(
          enabled: args['enabled'] as bool? ?? true,
          name: args['name'] as String?,
          url: args['url'] as String,
          type: ruleType,
          method: method,
        );
        final itemsList = (args['items'] as List).map((e) {
          final m = e as Map<String, dynamic>;
          return RewriteItem(
            RewriteType.fromName(m['type'] as String),
            m['enabled'] as bool? ?? true,
            values: m['values'] as Map<dynamic, dynamic>?,
          );
        }).toList();
        await manager.addRule(rule, itemsList);
        await manager.flushRequestRewriteConfig();
        return CallToolResult(content: [TextContent(text: 'Rule added')]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'rewrite_delete_rule',
    description: 'Delete rewrite rules by indexes.',
    inputSchema: JsonSchema.object(
      properties: {
        'indexes': JsonSchema.array(items: JsonSchema.integer(), description: 'Indexes to delete'),
      },
      required: ['indexes'],
    ),
    callback: (args, extra) async {
      final manager = await RequestRewriteManager.instance;
      final idx = (args['indexes'] as List).cast<int>();
      await manager.removeIndex(idx);
      await manager.flushRequestRewriteConfig();
      return CallToolResult(content: [TextContent(text: 'Deleted')]);
    },
  );

  server.registerTool(
    'rewrite_toggle',
    description: 'Enable or disable the entire rewrite system.',
    inputSchema: JsonSchema.object(
      properties: {
        'enabled': JsonSchema.boolean(required: true),
      },
      required: ['enabled'],
    ),
    callback: (args, extra) async {
      final manager = await RequestRewriteManager.instance;
      manager.enabled = args['enabled'] as bool;
      await manager.flushRequestRewriteConfig();
      return CallToolResult(content: [TextContent(text: 'Rewrite enabled: ' + args['enabled'].toString())]);
    },
  );
}
