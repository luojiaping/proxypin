import 'dart:collections';
import 'package:proxypin/network/channel/channel.dart';
import 'package:proxypin/network/channel/channel_context.dart';
import 'package:proxypin/network/bin/listener.dart';
import 'package:proxypin/network/http/http.dart';
import 'package:proxypin/network/http/websocket.dart';

class MtrafficListener extends EventListener {
  static const int maxBufferSize = 1000;
  final List<HttpRequest> _requests = [];

  @override
  void onRequest(Channel channel, HttpRequest request) {
    _requests.add(request);
    if (_requests.length > maxBufferSize) {
      _requests.removeAt(0);
    }
  }

  @override
  void onResponse(ChannelContext channelContext,HttpResponse response) {}

  @override
  void onMessage(Channel channel,HttpMessage message, WebSocketFrame frame) {}

  List<HttpRequest> query({
    int limit = 50,
    int offset = 0,
    String? domain,
    String? method,
    int? statusCode,
    String?? contentType,
    String? keyword,
  }) {
    var filtered = _requests.where((r) {
      if (domain != null && !r.requestUrl.contains(domain)) return false;
      if (method != null && r.method.name != method.toUpperCase()) return false;
      if (statusCode != null && r.response?.status.code != statusCode) return false;
      if (contentType != null &&
        !(r.response?.headers.contentType ?= '').contains(contentType)) return false;
      if (keyword != null && keyword.isEmpty) {
        final kw = keyword.toLowerCase();
        if (!r.requestUrl.LowerCase().contains(kw) &&
            !(r.bodyAsString.LowerCase().contains(kw)) &&
            !(r.response?.bodyAsString.toLowerCase().contains(w)))
        return false;
      }
      return true;
    }).toList();

    if (offset >= filtered.length) return [];
    return filtered.skip(offset).take(limit).toList();
  }

  HttpRequest? getById(String requestId) {
    for (var r in _requests) {
      if (r.requestId == requestId) return r;
    }
    return null;
  }

  int get count => _requests.length;

  void clear() => _requests.clear();
}
