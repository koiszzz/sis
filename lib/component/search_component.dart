import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sis/util/baseUtil.dart';

import 'basic_models.dart';

// Defines the content of the search page in `showSearch()`.
// SearchDelegate has a member `query` which is the query string.
class SearchBarDelegate extends SearchDelegate<String> {
  String jsToken;
  String lastQuery;
  List<Thread> lastThreads;

  @override
  List<Widget> buildActions(BuildContext context) {
    return null;
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        // SearchDelegate.close() can return vlaues, similar to Navigator.pop().
        this.close(context, null);
      },
    );
  }

  Future<List<Thread>> _search() async {
    if (this.query.length <= 0) {
      return [];
    }
    if (this.query == lastQuery) {
      return lastThreads;
    }
    if (jsToken == null) {
      String js = await BaseUtil.httpGet(
          'https://cse.google.com/cse.js?cx=009341400208504726543:qg1lhh9kw1y');
      if (js == null) {
        throw Exception('google js 加载错误');
      }
      RegExp exp = new RegExp(r'"cse_token": "([\w|\-\:]+)"');
      Match match = exp.firstMatch(js);
      if (match != null) {
        jsToken = match.group(1);
        print(jsToken);
      }
    }
    String url = "https://cse.google.com/cse/element/v1?"
        "rsz=filtered_cse&num=10&hl=zh-CN&source=gcsc&gss=.com&"
        "cselibv=b5752d27691147d6&cx=009341400208504726543:qg1lhh9kw1y&"
        "q=${this.query}&safe=off&cse_tok=${jsToken}&sort=&exp=csqr,cc&oq=${this.query}&callback=google.search.cse.api" +
        new Random().nextInt(2000).toString();
    String result = await BaseUtil.httpGet(url, true);
    if (result == null) {
      throw Exception('没有找到结果');
    }
    Map<String, dynamic> resultJson = json.decode(
        result.substring(result.indexOf('{'), result.lastIndexOf('}') + 1));
    print('结果总数:${resultJson['cursor']['estimatedResultCount']}');
    List<Thread> threads = new List();
    for (var row in resultJson['results']) {
      String rowTitle = row['titleNoFormatting'].toString();
      if (rowTitle.contains('-')) {
        rowTitle = rowTitle.substring(0, rowTitle.indexOf('-'));
      }
      threads.add(Thread(
          title: rowTitle, url: row['unescapedUrl'], content: row['content']));
    }
    this.lastQuery = this.query;
    this.lastThreads = threads;
    return threads;
  }

  @override
  Widget buildResults(BuildContext context) {
    return null;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    print('build suggestions');
    return FutureBuilder<List<Thread>>(
      future: _search(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          // TODO: Handle this case.
            return Text('没有查找结果');
          case ConnectionState.waiting:
          // TODO: Handle this case.
            return Center(
              child: SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(),
              ),
            );
          case ConnectionState.active:
          // TODO: Handle this case.
            return Text('加载完成');
          case ConnectionState.done:
          // TODO: Handle this case.
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }
            return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(snapshot.data[index].title),
                    subtitle: Text(snapshot.data[index].content),
                    onTap: () {
                      print('tap');
                      if (snapshot.data[index].url.contains('thread')) {
                        Navigator.of(context).pushNamed('thread',
                            arguments: snapshot.data[index]);
                      }
                    },
                  );
                });
          default:
            return Text("unknown state");
        }
      },
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    // TODO: implement appBarTheme
    return super.appBarTheme(context);
  }
}
