import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sis/util/baseUtil.dart';

import 'basic_models.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SearchComponent extends StatefulWidget {
  @override
  _SearchComponentState createState() => _SearchComponentState();
}

class _SearchComponentState extends State<SearchComponent> {
  final String _sharedKey = 'search_his';
  String jsToken;
  var _loadState = LoadingState.Loading;
  int start = 0;
  int end = 10;
  String messageToShow = '';
  var _textController = new TextEditingController();
  List<Thread> threads = [];
  String query = '';
  bool _loadMore = false;

  @override
  initState() {
    super.initState();
    _loadGoogleJs();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadGoogleJs() async {
    String js = await BaseUtil.httpGet(
        'https://cse.google.com/cse.js?cx=009341400208504726543:qg1lhh9kw1y');
    if (js == null) {
      setState(() {
        messageToShow = 'google js 加载错误';
        _loadState = LoadingState.Failure;
      });
    }
    RegExp exp = new RegExp(r'"cse_token": "([\w|\-\:]+)"');
    Match match = exp.firstMatch(js);
    if (match == null) {
      setState(() {
        messageToShow = 'google js 加载错误';
        _loadState = LoadingState.Failure;
      });
    }
    jsToken = match.group(1);
    setState(() {
      _loadState = LoadingState.Success;
    });
  }

  Future<List<String>> _getSearchHis() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_sharedKey);
  }

  Future<void> _addSearchHis(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> his = prefs.getStringList(_sharedKey);
    if (his == null) {
      his = [];
    }
    his.removeWhere((v) => v == value);
    if (his.length > 20) {
      his.removeAt(0);
    }
    his.add(value);
    await prefs.setStringList(_sharedKey, his);
  }

  Future<void> _loadSearchResult({start: int}) async {
    if (_loadMore) {
      return;
    }
    _loadMore = true;
    String url = "https://cse.google.com/cse/element/v1?"
            "rsz=filtered_cse&num=10&hl=zh-CN&source=gcsc&gss=.com&"
            "cselibv=b5752d27691147d6&cx=009341400208504726543:qg1lhh9kw1y&"
            "q=${this.query}&safe=off&cse_tok=${this.jsToken}&sort=&exp=csqr,cc&oq=${this.query}&callback=google.search.cse.api" +
        new Random().nextInt(2000).toString();
    if (start != null && start >= 0) {
      url += "&start=" + start.toString();
    }
    String result = await BaseUtil.httpGet(url, true);
    if (result == null) {
      setState(() {
        _loadState = LoadingState.Failure;
        messageToShow = '没有找到结果';
      });
    }
    Map<String, dynamic> resultJson = json.decode(
        result.substring(result.indexOf('{'), result.lastIndexOf('}') + 1));
    print('结果总数:${resultJson['cursor']['estimatedResultCount']}');
    if (resultJson['cursor']['estimatedResultCount'] == null) {
      setState(() {
        this.end = 0;
      });
      _loadMore = false;
      return;
    }
    List<Thread> threads = new List();
    for (var row in resultJson['results']) {
      String rowTitle = row['titleNoFormatting'].toString();
      if (rowTitle.contains('-')) {
        rowTitle = rowTitle.substring(0, rowTitle.lastIndexOf('-'));
      }
      threads.add(
          Thread(title: rowTitle, url: row['unescapedUrl'], content: (row['contentNoFormatting'] as String).replaceAll('\n', '')));
    }
    setState(() {
      this.start += threads.length;
      this.threads.addAll(threads);
      this.end = int.parse(resultJson['cursor']['estimatedResultCount']);
    });
    _loadMore = false;
  }

  Widget _buildFailure() {
    return Center(
      child: Column(
        children: <Widget>[
          Text(messageToShow),
          FlatButton(
            child: Text('重新加载'),
            onPressed: jsToken == null ? _loadGoogleJs : _loadSearchResult,
          )
        ],
      ),
    );
  }


  void _search(value) {
    setState(() {
      this.start = 0;
      this.end = 10;
      this.threads = [];
      this.query = value;
    });
    _addSearchHis(value);
  }

  Widget _buildSuggestions() {
    return FutureBuilder(
      future: _getSearchHis(),
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return Container(
            child: InkWell(child: Text('没有搜索记录'),),
          );
        }
        return Container(
          padding: EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InkWell(
                child: Text('历史记录', style: Theme.of(context).textTheme.subhead,),
              ),
              Wrap(children: (snapshot.data as List<String>).reversed.map((v) {
                return InkWell(
                  onTap: () {
                    if (_textController.text != v) {
                      _textController.text = v;
                      _search(v);
                      FocusScope.of(context).unfocus();
                    }
                  },
                  child: Chip(
                    label: Text(v),
                  ),
                );
              }).toList(),)
            ],
          ),
        );
      },
    );
  }

  Widget _buildResult() {
    return ListView.separated(
      itemCount: threads.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index >= threads.length) {
          if (start < end) {
            _loadSearchResult(start: this.start);
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return ListTile(
              title: Text('没有更多结果了'),
            );
          }
        }
        return ListTile(
          title: Text(threads[index].title),
          subtitle: Text(threads[index].content),
          onTap: () {
            print(threads[index].url);
            if (threads[index].url.contains('thread')) {
              Navigator.of(context).pushNamed('thread',
                  arguments: threads[index]);
            }
          },
        );
      },
      separatorBuilder: (BuildContext context, index) {
        return Divider(
          color: Theme.of(context).dividerTheme.color,
        );
      },
    );
  }

  Widget _buildSuccess() {
    if (this.query.length <= 0) {
      return _buildSuggestions();
    } else {
      return _buildResult();
    }
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
      case LoadingState.Loading:
      default:
        return Center(
          child: CircularProgressIndicator(),
        );
    }
  }

  List<Widget> _buildTextAction() {
    return _textController.text.length > 0
        ? [
            IconButton(
                icon: Icon(
                  Icons.clear,
                ),
                onPressed: () {
                  setState(() {
                    _textController.text = '';
                    this.query = '';
                  });
                })
          ]
        : [];
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: Theme.of(context).iconTheme.copyWith(color: Colors.black),
        title: TextField(
          textInputAction: TextInputAction.search,
          autofocus: true,
          controller: _textController,
          decoration:
              InputDecoration(border: InputBorder.none, hintText: 'Search'),
          onChanged: (value) {
            setState(() {});
          },
          onSubmitted: (value) {
            if (value != query) {
              _search(value);
            }
          },
        ),
        actions: _buildTextAction(),
      ),
      body: _buildBody(),
    );
  }
}