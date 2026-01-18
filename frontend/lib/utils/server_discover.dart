import 'dart:async';

import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;





class ServerDiscovery {
  static const int port = 8080;

  /// Option 1: mDNS discovery
  static Future<String?> discoverViaMDNS() async {
    final client = MDnsClient();
    await client.start();

    try {
      await for (final ptr in client.lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer('_lanplay._tcp.local'))) {
        await for (final srv in client.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName))) {
          await for (final ip in client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target))) {
            return "http://${ip.address.address}:${srv.port}";
          }
        }
      }
    } catch (_) {}
    finally {
      client.stop();
    }
    return null;
  }

  /// Option 2: HTTP ping scan
  static Future<String?> discoverViaScan() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    if (ip == null) return null;

    final subnet = ip.substring(0, ip.lastIndexOf('.') + 1);

    for (int i = 1; i <= 254; i++) {
      final url = Uri.parse("http://$subnet$i:$port/ping");
      try {
        final res = await http
            .get(url)
            .timeout(const Duration(milliseconds: 300));
        if (res.statusCode == 200 &&
            res.body.contains("LANPlay")) {
          return "http://$subnet$i:$port";
        }
      } catch (_) {}
    }
    return null;
  }
}
