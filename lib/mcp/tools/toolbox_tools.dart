import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/utils/curl.dart';
import 'package:crypto/crypto.dart';

void registerToolboxTools(McpServer server) {
  server.registerTool(
    'toolbox_encode',
    description: 'Encode text using various encodings.',
    inputSchema: JsonSchema.object(
      properties: {
        'type': JsonSchema.string(description: 'Encoding type: url, base64, unicode, md5'),
        'input': JsonSchema.string(description: 'Text to encode'),
      },
      required: ['type', 'input'],
    ),
    callback: (args, extra) async {
      final input = args['input'] as String;
      final type = args['type'] as String;
      String result;
      switch (type) {
        case 'url':
          result = Uri.encodeFull(input);
        case 'base64':
          result = base64Encode(utf8.encode(input));
        case 'unicode':
          result = input.runes.map((r) => '\u\${r.toRadixString(16).padLeft(4, "0")}').join();
        case 'md5':
          result = md5.convert(utf8.encode(input)).toString();
        default:
          return CallToolResult(isError: true, content: [TextContent(text: 'Unknown encoding type: ' + type)]);
      }
      return CallToolResult(content: [TextContent(text: jsonEncode({'type': type, 'result': result}))]);
    },
  );

  server.registerTool(
    'toolbox_decode',
    description: 'Decode text using various encodings.',
    inputSchema: JsonSchema.object(
      properties: {
        'type': JsonSchema.string(description: 'Decoding type: url, base64, unicode'),
        'input': JsonSchema.string(description: 'Text to decode'),
      },
      required: ['type', 'input'],
    ),
    callback: (args, extra) async {
      final input = args['input'] as String;
      final type = args['type'] as String;
      String result;
      switch (type) {
        case 'url':
          result = Uri.decodeFull(input);
        case 'base64':
          result = utf8.decode(base64Decode(input));
        case 'unicode':
          result = input;
        default:
          return CallToolResult(isError: true, content: [TextContent(text: 'Unknown decoding type: ' + type)]);
      }
      return CallToolResult(content: [TextContent(text: jsonEncode({'type': type, 'result': result}))]);
    },
  );

  server.registerTool(
    'toolbox_curl_parse',
    description: 'Parse a cURL command string into HTTP request components.',
    inputSchema: JsonSchema.object(
      properties: {
        'curlCommand': JsonSchema.string(description: 'Full cURL command string'),
      },
      required: ['curlCommand'],
    ),
    callback: (args, extra) async {
      try {
        final request = Curl.parse(args['curlCommand'] as String);
        return CallToolResult(
          content: [TextContent(text: jsonEncode({
            'method': request.method.name,
            'url': request.requestUrl,
            'headers': request.headers.toMap(),
            'body': request.bodyAsString,
          }))],
        );
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed to parse cURL: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'toolbox_timestamp',
    description: 'Convert between timestamps and human-readable dates.',
    inputSchema: JsonSchema.object(
      properties: {
        'input': JsonSchema.string(description: 'Timestamp (milliseconds or seconds) or ISO8601 date string'),
      },
      required: ['input'],
    ),
    callback: (args, extra) async {
      final input = (args['input'] as String).trim();
      try {
        if (RegExp(r'^\d+\$').hasMatch(input)) {
          final ts = int.parse(input);
          final dt = ts > 9999999999 ? DateTime.fromMillisecondsSinceEpoch(ts) : DateTime.fromMillisecondsSinceEpoch(ts * 1000);
          return CallToolResult(content: [TextContent(text: jsonEncode({
            'timestamp_ms': dt.millisecondsSinceEpoch,
            'timestamp_s': dt.millisecondsSinceEpoch ~/ 1000,
            'iso8601': dt.toIso8601String(),
            'local': dt.toString(),
          }))]);
        } else {
          final dt = DateTime.parse(input);
          return CallToolResult(content: [TextContent(text: jsonEncode({
            'timestamp_ms': dt.millisecondsSinceEpoch,
            'timestamp_s': dt.millisecondsSinceEpoch ~/ 1000,
            'iso8601': dt.toIso8601String(),
          }))]);
        }
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'toolbox_regexp_test',
    description: 'Test a regular expression pattern against input text.',
    inputSchema: JsonSchema.object(
      properties: {
        'pattern': JsonSchema.string(description: 'Regular expression pattern'),
        'input': JsonSchema.string(description: 'Text to test against'),
      },
      required: ['pattern', 'input'],
    ),
    callback: (args, extra) async {
      try {
        final pattern = args['pattern'] as String;
        final input = args['input'] as String;
        final regExp = RegExp(pattern);
        final matches = regExp.allMatches(input).map((m) => {
          'match': m.group(0),
          'start': m.start,
          'end': m.end,
          'groups': List.generate(m.groupCount, (i) => m.group(i + 1)),
        }).toList();
        return CallToolResult(content: [TextContent(text: jsonEncode({
          'matched': regExp.hasMatch(input),
          'matchCount': matches.length,
          'matches': matches,
        }))]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Invalid regex: ' + e.toString())]);
      }
    },
  );
}
