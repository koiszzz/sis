import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fast_gbk/fast_gbk.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

class BaseUtil {
  static Future<String> httpGet(String url, [bool utfDecode]) async {
    print('访问:' + url);
    try {
      var httpClient = new HttpClient();
      var request = await httpClient.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 5));
      var response = await request.close();
      var status = response.statusCode;
      print('状态码: ' + status.toString());
      if (status == HttpStatus.ok) {
        var docStr;
        if (utfDecode == null || !utfDecode) {
          docStr = await response.transform(gbk.decoder).join();
        } else {
          docStr = await response.transform(utf8.decoder).join();
        }
        return docStr;
      } else{
        print('http状态码：$status');
        return null;
      }
    } catch (exception, stacktrace) {
      print(stacktrace.toString());
      print(exception.toString());
      return null;
    }
  }

  static Document parseHtml(String docStr) {
    return parse(docStr);
  }
}