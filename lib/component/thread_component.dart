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
    if (widget.thread.url == null || widget.thread.url.length <= 0) {
      setState(() {
        _loadState = LoadingState.Failure;
        messageToShow = '链接错误，请返回主页刷新页面';
      });
      return;
    }
    String url = widget.thread.url;
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
    if (url.indexOf('http://') < 0) {
      url = 'http://sexinsex.net/bbs/' + url;
    }
    String str = await BaseUtil.httpGet(url);
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
                .replaceAll('space.php?uid=', ''),
            name: authorEle.querySelector('cite a').text);
      }
      String id = thread.attributes['id'].replaceFirst('pid', '');
      List<DOM.Element> contentEles =
          thread.querySelectorAll('div[id^=postmessage_]');
      if (contentEles.length <= 0) {
        continue;
      }
      RegExp exp = new RegExp(
          r'([\u4e00-\u9fa5\u3002\uff1b\uff0c\uff1a\u201c\u201d\uff08\uff09\u3001\uff1f\u300a\u300b]{1})\n([\u4e00-\u9fa5]{1})');
      String message = contentEles[contentEles.length - 1]
          .innerHtml
          .replaceAllMapped(new RegExp(r'(<[^>]+>)'), (match) {
            if (match.group(1).contains('img')) {
              return match.group(1);
            }
            return '';
          })
          .replaceAll(new RegExp(r'[　]{6,}'), '　　　　')
          .replaceAllMapped(exp, (match) {
            return match.group(1) + match.group(2);
          });
      this
          .contents
          .add(ThreadContent(id: id, message: message, author: author));
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
          if (pageNum < pageSize) {
            pageNum++;
            _loadList(pageNum: pageNum);
            return Center(
              child: SizedBox(
                height: 25,
                width: 25,
                child: CircularProgressIndicator(),
              ),
            );
          }
          return Center(
            child: Text('没有更多的内容了😜'),
          );
        }
        return Card(
            elevation: 5.0,
            margin: EdgeInsets.all(5.0),
            child: Container(
              padding: EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildRowAuthor(contents[index].author),
                  RichText(
                    text: TextSpan(
                        children:
                            contents[index].message.split('\n\n').map((row) {
                      return TextSpan(
                          text: row + '\n',
                          style: Theme.of(context).textTheme.body1);
                    }).toList()),
                  ),
                ],
              ),
            ));
      },
    );
  }

  Widget _buildRowAuthor(Author author) {
    return Container(
      padding: EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 25,
            child: Image.asset(
              'images/p_icon.jpg',
              width: 39,
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                author == null ? Text('用户已被删除') : Text(author.name)
              ],
            ),
          )
        ],
      ),
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
