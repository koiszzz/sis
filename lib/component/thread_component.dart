import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
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
    Match match = RegExp(r'thread-[\d]+-([\d]+)-[\d]+.html')
        .firstMatch(widget.thread.url);
    if (match != null) {
      pageNum = int.parse(match.group(1));
    }
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
        DOM.Element postInfo = thread.querySelector('.postinfo');
        String threadIndex = '?楼', postTime = '时间';
        List<String> postInfoStrs = postInfo.text
            .replaceAll(RegExp('[大|小|中|只|看|该|作|者|\n]'), '')
            .replaceAll(RegExp('[	]+'), '')
            .split('发表于');
        if (postInfoStrs.length == 2) {
          threadIndex = postInfoStrs[0];
          postTime = postInfoStrs[1];
        }
        author = Author(
            uid: authorEle
                .querySelector('cite a')
                .attributes['href']
                .replaceAll('space.php?uid=', ''),
            name: authorEle.querySelector('cite a').text,
            threadIndex: threadIndex,
            postTime: postTime);
      }
      String id = thread.attributes['id'].replaceFirst('pid', '');
      List<DOM.Element> contentEles =
          thread.querySelectorAll('div[id^=postmessage_]');
      if (contentEles.length <= 0) {
        continue;
      }
      RegExp exp = new RegExp(
          r'([\u4e00-\u9fa5\u3002\uff1b\uff0c\uff1a\u201c\u201d\uff08\uff09\u3001\uff1f\u300a\u300b]{1})\n([\u4e00-\u9fa5\u4e00-\u9fa5\u3002\uff1b\uff0c\uff1a\u201c\u201d\uff08\uff09\u3001\uff1f\u300a\u300b]{1})');
      String message = contentEles[contentEles.length - 1]
          .innerHtml
          .replaceAllMapped(new RegExp(r'(<[^>]+>)'), (match) {
            if (match.group(1).contains('img')) {
              return '\n' + match.group(1);
            }
            return '';
          })
          .replaceAll('&nbsp;', '　')
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
    return RefreshIndicator(
      child: ListView.builder(
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
                    // ignore: sdk_version_ui_as_code
                    ...contents[index]
                        .message
                        .split(RegExp(r'[\n]+'))
                        .map(_buildContentRow)
                        .toList()
                  ],
                ),
              ));
        },
      ),
      onRefresh: () async {
        // todo: 改造下加载数据结构
        print('load pre');
      },
    );
  }

  Widget _buildContentRow(String row) {
    if (row.startsWith('<img')) {
      Match match = RegExp(r'src="([^"]+)"').firstMatch(row);
      if (match == null) {
        return Text('错误的图片链接');
      }
      String imgUrl = match.group(1);
      if (!imgUrl.startsWith('http')) {
        imgUrl = 'http://sexinsex.net/bbs/' + imgUrl;
      }
      return CachedNetworkImage(
        placeholder: (contents, url) => Column(
          children: <Widget>[CircularProgressIndicator(), Text(url)],
        ),
        imageUrl: imgUrl,
        errorWidget: (context, url, error) => Column(
          children: <Widget>[
            Icon(Icons.error),
            Text('加载失败: ${error.toString()}'),
            Text('链接:' + url, maxLines: 1, overflow: TextOverflow.ellipsis)
          ],
        ),
      );
    }
    return Text(row + '\n');
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
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                author == null ? Text('用户已被删除') : Text(author.name),
                Text(''),
                author == null ? Text('没有获取提交时间') : Text(author.postTime)
              ],
            ),
          ),
          Text(author == null ? '?楼' : author.threadIndex)
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // todo: 重置加载页数为1
        },
        child: Icon(Icons.replay),
      ),
    );
  }
}
