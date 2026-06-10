import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:proxypin/network/util/crts.dart';

void registerCertTools(McpServer server) {
  server.registerTool(
    'cert_get_details',
    description: 'Get CA certificate details (subject, issuer, validity, etc.).',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      try {
        final cert = await CertificateManager.getCertificateDetails();
        return CallToolResult(
          content: [TextContent(text: jsonEncode({
            'subject': cert.subject.toString(),
            'issuer': cert.issuer.toString(),
            'serialNumber': cert.serialNumber,
            'validity': {
              'notBefore': cert.validity.notBefore?.toIso8601String(),
              'notAfter': cert.validity.notAfter?.toIso8601String(),
            },
          }))],
        );
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'cert_get_pem',
    description: 'Get the CA certificate in PEM format.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      try {
        final pem = await CertificateManager.certificatePem();
        return CallToolResult(content: [TextContent(text: pem)]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'cert_get_subject_hash',
    description: 'Get CA certificate subject hash name (for Android system cert installation).',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      try {
        final hashName = await CertificateManager.systemCertificateName();
        return CallToolResult(content: [TextContent(text: jsonEncode({'subjectHashName': hashName}))]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'cert_generate_new',
    description: 'Generate a new root CA certificate. WARNING: Requires reinstalling the CA on devices.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      try {
        await CertificateManager.generateNewRootCA();
        return CallToolResult(content: [TextContent(text: 'New root CA generated')]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );

  server.registerTool(
    'cert_reset_default',
    description: 'Reset to the default built-in root CA certificate.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      try {
        await CertificateManager.resetDefaultRootCA();
        return CallToolResult(content: [TextContent(text: 'Root CA reset to default')]);
      } catch (e) {
        return CallToolResult(isError: true, content: [TextContent(text: 'Failed: ' + e.toString())]);
      }
    },
  );
}
