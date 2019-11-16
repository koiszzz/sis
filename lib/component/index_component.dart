import 'package:flutter/material.dart';
import 'package:html/dom.dart' as DOM;
import 'package:sis/component/search_component.dart';
import 'package:sis/util/baseUtil.dart';

import 'basic_models.dart';

class IndexComponent extends StatefulWidget {
  IndexComponent({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _IndexComponentState createState() => _IndexComponentState();
}

class _IndexComponentState extends State<IndexComponent> {
  SearchBarDelegate _delegate;
  var _loadState = LoadingState.Loading;
  String messageToShow = '';
  List<TopicSection> sections = new List();

  @override
  initState() {
    super.initState();
    _getTopics();
    _delegate = SearchBarDelegate();
  }

  Widget _buildGroup(TopicGroup group) {
    final routeTitleTextStyle =
        Theme.of(context).textTheme.body1.copyWith(fontWeight: FontWeight.bold);
    return ListTile(
      title: Text(group.title, style: routeTitleTextStyle),
      onTap: () => {Navigator.of(context).pushNamed('group', arguments: group)},
    );
  }

  Widget _buildSection(TopicSection section) {
    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.bookmark),
        title: Text(
          section.title,
          style: Theme.of(context)
              .textTheme
              .subhead
              .copyWith(fontWeight: FontWeight.bold),
        ),
        children: section.groups.map(_buildGroup).toList(),
      ),
    );
  }

  // 话题列表
  Widget _buildSuccess() {
    return ListView(
      children: sections.map(_buildSection).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            tooltip: 'search',
            icon: Icon(Icons.search),
            onPressed: () async {
              await showSearch<String>(
                context: context,
                delegate: _delegate,
              );
            },
          )
        ],
      ),
      body:
          _buildBody(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> _getTopics() async {
    String str = await BaseUtil.httpGet('http://sexinsex.net/bbs/index.php');
    if (str == null) {
      setState(() {
        _loadState = LoadingState.Failure;
        messageToShow = '加载失败';
      });
      return;
    }
    DOM.Document document = BaseUtil.parseHtml(str);
    List<DOM.Element> blocks = document.getElementsByClassName('forumlist');
    if (blocks == null || blocks.length <= 0) {
      setState(() {
        _loadState = LoadingState.Failure;
        messageToShow = '文档结构变化，无法找到分组情况';
      });
    }
    for (DOM.Element element in blocks) {
      DOM.Element titleP = element.getElementsByTagName('h3').first;
      if (titleP == null) {
        continue;
      }
      DOM.Element title = titleP.getElementsByTagName('a').first;
      if (title == null) {
        continue;
      }
      TopicSection section =
          new TopicSection(title.innerHtml, title.attributes['href']);
      List<DOM.Element> subs = element.getElementsByTagName('h2');
      for (DOM.Element sub in subs) {
        DOM.Element subLink = sub.getElementsByTagName('a').first;
        section.addGroup(TopicGroup(subLink.text, subLink.attributes['href']));
      }
      sections.add(section);
    }
    setState(() {
      _loadState = LoadingState.Success;
    });
  }

  Widget _buildBody() {
    switch (_loadState) {
      case LoadingState.Failure:
        // TODO: Handle this case.
        return _buildFailure();
      case LoadingState.Success:
        // TODO: Handle this case.
        return _buildSuccess();
      case LoadingState.Loading:
      default:
        return Center(
          child: CircularProgressIndicator(),
        );
    }
  }

  Widget _buildFailure() {
    return Center(
      child: Column(
        children: <Widget>[
          Text(messageToShow),
          FlatButton(
            child: Text('重新加载'),
            onPressed: _getTopics,
          )
        ],
      ),
    );
  }
}
