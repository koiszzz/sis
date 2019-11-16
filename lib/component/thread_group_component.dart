import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sis/util/baseUtil.dart';
import 'package:html/dom.dart' as DOM;

import 'basic_models.dart';

class ThreadGroupComponent extends StatefulWidget {
  ThreadGroupComponent({Key key, this.group}) : super(key: key);
  final TopicGroup group;

  @override
  _ThreadGroupComponentState createState() => _ThreadGroupComponentState();
}

class _ThreadGroupComponentState extends State<ThreadGroupComponent> {
  var _loadState = LoadingState.Loading;
  int pageNum = 1;
  int pageSize;
  String messageToShow = '';
  List<Thread> threads = new List();

  initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList({int pageNum}) async {
    if (widget.group.titleUrl == null || widget.group.titleUrl.length <= 0) {
      setState(() {
        _loadState = LoadingState.Failure;
        messageToShow = '链接错误，请返回主页刷新页面';
      });
      return;
    }
    String url = widget.group.titleUrl;
    if (pageNum != null) {
      if (url.contains('?')) {
        url += 'page=' + pageNum.toString();
      } else {
        url = url.substring(0, url.lastIndexOf('-') + 1) +
            pageNum.toString() +
            url.substring(url.lastIndexOf('.'), url.length);
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
            document
                .querySelector('a.last')
                .text
                .replaceAll('... ', ''));
      } else {
        if (document.querySelectorAll('.pages a') == null) {
          pageSize = 1;
        } else {
          pageSize = document
              .querySelectorAll('.pages a')
              .length ~/ 2 - 1;
        }
      }
    }
    List<DOM.Element> threads = document.querySelectorAll('th');
    for (DOM.Element thread in threads) {
      if (thread.querySelector('a') == null) {
        continue;
      }
      var title, url;
      if (thread.querySelector('span') != null) {
        title = thread
            .querySelector('span')
            .text
            .trim();
        url = thread
            .querySelector('span a')
            .attributes['href'];
      } else {
        title = thread.text.trim();
        url = thread
            .querySelector('a')
            .attributes['href'];
      }
      this.threads.add(Thread(title: title, url: url));
    }
    setState(() {
      _loadState = LoadingState.Success;
    });
  }

  Widget _buildSuccess() {
    return ListView.separated(
      itemCount: threads.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index >= threads.length) {
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
        return ListTile(
          title: Text(threads[index].title, style: Theme.of(context).textTheme.subtitle,),
          onTap: () {
            Navigator.of(context)
                .pushNamed('thread', arguments: threads[index]);
          },
        );
      },
      separatorBuilder: (BuildContext context, index) {
        return Divider(color: Theme.of(context).dividerTheme.color,);
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
        title: Text(widget.group.title),
      ),
      body: _buildBody(),
    );
  }
}
