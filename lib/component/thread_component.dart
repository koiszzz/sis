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
      RegExp reg = new RegExp(r"(\d)+\-(\d)+\-(\d)");
      String next = url.replaceAllMapped(reg, (match) {
        return '${match.group(0)}-${pageNum}-${match.group(2)}';
      });
      print(next);
    }
    String str = await BaseUtil.httpGet(
        'http://sexinsex.net/bbs/' + url);
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
        pageSize = int.parse(document.querySelector('a.last').text.replaceAll('... ', ''));
      } else{
        if (document.querySelectorAll('.pages a') == null) {
          pageSize = 1;
        } else {
          pageSize = document.querySelectorAll('.pages a').length ~/ 2 - 1;
        }
      }
    }
    List<DOM.Element> threads = document.querySelectorAll('div[id^=postmessage_]');
    for (DOM.Element thread in threads) {
      String id = thread.attributes['id'].replaceFirst('postmessage_', '');
      List<MessageContent> messages = thread.children.map((child) {
        ContentType type = child.localName == 'img' ? ContentType.Img : ContentType.Text;
        String content = child.localName == 'img' ? child.attributes['img'] : child.text;
        if (content == null) {
          content = child.innerHtml;
        }
        return MessageContent(type: type, content: content);
      }).toList();
      this.contents.add(ThreadContent(id: id, messages: messages));
    }
    setState(() {
      _loadState = LoadingState.Success;
    });
  }

  Widget _buildSuccess() {
    return ListView.builder(
      itemCount: contents.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index >= contents.length) {
          print(pageNum);
          print(pageSize);
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
            children: contents[index].messages.map<Widget>((message) => Text(message.content)).toList(),
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
