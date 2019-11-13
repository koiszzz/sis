import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sis/component/basic_models.dart';
import 'package:sis/util/baseUtil.dart';
import 'package:html/dom.dart' as DOM;

class ThreadComponent extends StatefulWidget {
  ThreadComponent({Key key, this.thread}) : super(key: key);
  final Thread thread;

  @override
  _ThreadComponentState createState() => _ThreadComponentState();
}

class _ThreadComponentState extends State<ThreadComponent> {
  var _loadState = LoadingState.Loading;
  int pageNum = 1;
  int pageSize;
  String messageToShow = '';
  List<ThreadContent> contents = new List();

  initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList({int pageNum}) async {
    if (widget.thread.titleUrl == null || widget.thread.titleUrl.length <= 0) {
      setState(() {
        _loadState = LoadingState.Failure;
        messageToShow = '链接错误，请返回主页刷新页面';
      });
      return;
    }
    String url = widget.thread.titleUrl;
    if (pageNum != null) {
      RegExp reg = new RegExp(r"(thread-\d+-)(\d+)(-\d+.html)");
      Match m = reg.firstMatch(url);
      if (m != null) {
        if (m.group(3) == null) {
          print('帖子链接不符合规则');
        } else {
          url = m.group(1) + pageNum.toString() + m.group(3);
        }
      } else {
        print('没有匹配');
      }
    }
    String str = await BaseUtil.httpGet('http://sexinsex.net/bbs/' + url);
    if (str == null) {
      setState(() {
        _loadState = LoadingState.Failure;
        messageToShow = '加载内容失败';
      });
    }
    DOM.Document document = BaseUtil.parseHtml(str);
    if (document.querySelector('.box.message') != null) {
      DOM.Element message = document.querySelector('.box.message');
      for (DOM.Element rowP in message.querySelectorAll('p')) {
        messageToShow += rowP.text.trim() + '\n';
      }
      setState(() {
        _loadState = LoadingState.NotAuth;
      });
      return;
    }
    if (pageSize == null) {
      if (document.querySelector('a.last') != null) {
        pageSize = int.parse(
            document.querySelector('a.last').text.replaceAll('... ', ''));
      } else {
        if (document.querySelectorAll('.pages a') == null) {
          pageSize = 1;
        } else {
          pageSize = document.querySelectorAll('.pages a').length ~/ 2 - 1;
        }
      }
    }
    List<DOM.Element> threads = document.querySelectorAll('table[id^=pid]');
    for (DOM.Element thread in threads) {
      DOM.Element authorEle = thread.querySelector('.postauthor');
      Author author;
      if (authorEle.querySelector('cite a') != null) {
        author = Author(
            uid: authorEle
                .querySelector('cite a')
                .attributes['href']
                .replaceAll('space.php?uid=', ''));
      }
      String id = thread.attributes['id'].replaceFirst('pid', '');
      List<DOM.Element> contentEles =
          thread.querySelectorAll('div[id^=postmessage_]');
      if (contentEles.length <= 0) {
        continue;
      }
      print('内容个数:${contentEles.length}');
      List<MessageContent> messages = new List();
      List<DOM.Element> fontElement =
          contentEles[contentEles.length - 1].querySelectorAll('font');
      if (fontElement.length > 0) {
        print('font 元素个数：${fontElement.length}');
        for (DOM.Element font in fontElement) {
          messages.addAll(_dealWithFontTag(font));
        }
      } else {
        for (DOM.Node msgElement in contentEles[contentEles.length - 1].nodes) {
          String t = msgElement.text.replaceAll('　', '').trim();
          if (t.length <= 0) {
            continue;
          }
          messages.add(
              MessageContent(type: ContentType.Text, content: msgElement.text));
        }
      }

      this
          .contents
          .add(ThreadContent(id: id, messages: messages, author: author));
    }
    setState(() {
      _loadState = LoadingState.Success;
    });
  }

  List<MessageContent> _dealWithFontTag(DOM.Element font) {
    if (font.querySelector('font') != null) {
      print('子项有font');
      return [];
    }
    if (font.querySelector('marquee') != null) {
      print('子项有marquee');
      return [MessageContent(type: ContentType.Text, content: font.text)];
    }
    if (font.querySelector('img') != null) {
      print('子项有img');
      List<MessageContent> list = [];
      for (DOM.Node node in font.nodes) {
        if (node.toString() == '<html img>') {
          list.add(MessageContent(
              type: ContentType.Img, content: node.attributes['src']));
        } else {
          String t = node.text.replaceAll('　', '').trim();
          if (t.length > 0) {
            list.add(MessageContent(type: ContentType.Text, content: t));
          }
        }
      }
      return list;
    } else {
      print('子项没有img');
      RegExp t = new RegExp(r'[　]{2,}');
      return [
        MessageContent(
            type: ContentType.Text,
            content: font.text.replaceAll('\n', '').replaceAll(t, '\n　　'))
      ];
    }
  }

  Widget _buildSuccess() {
    return ListView.builder(
      itemCount: contents.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index >= contents.length) {
          if (pageNum < pageSize) {
            pageNum++;
            _loadList(pageNum: pageNum);
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return Center(
            child: Text('没有更多的内容了😜'),
          );
        }
        return Card(
          child: Column(
            children: contents[index].messages.map<Widget>((message) {
              return Text(message.content);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_loadState) {
      case LoadingState.Failure:
        // TODO: Handle this case.
        return _buildFailure();
      case LoadingState.Success:
        // TODO: Handle this case.
        return _buildSuccess();
      case LoadingState.NotAuth:
        // TODO: Handle this case.
        return _buildNotAuth();
        break;
      case LoadingState.Loading:
      default:
        return Center(
          child: CircularProgressIndicator(),
        );
    }
  }

  Widget _buildNotAuth() {
    return Center(
      child: Column(
        children: <Widget>[
          Text(messageToShow),
          FlatButton(
            child: Text('返回'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Widget _buildFailure() {
    return Center(
      child: Column(
        children: <Widget>[
          Text(messageToShow),
          FlatButton(
            child: Text('重新加载'),
            onPressed: _loadList,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.thread.title),
      ),
      body: _buildBody(),
    );
  }
}
