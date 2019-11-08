import 'package:flutter/material.dart';
import 'package:sis/util/baseUtil.dart';
import 'package:html/dom.dart' as DOM;
import 'basic_models.dart';

class IndexComponent extends StatefulWidget {
  IndexComponent({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _IndexComponentState createState() => _IndexComponentState();
}

class _IndexComponentState extends State<IndexComponent> {
  bool _loadingFlag = true;
  List<TopicSection> sections = new List();

  @override
  initState() {
    super.initState();
    _getTopics();
  }

  // 加载页面
  Widget _loading() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildGroup(TopicGroup group) {
    final routeTitleTextStyle =
        Theme.of(context).textTheme.body1.copyWith(fontWeight: FontWeight.bold);
    return ListTile(
      title: Text(group.title, style: routeTitleTextStyle),
      onTap: () => {
        Navigator.of(context).pushNamed('group', arguments: group)
      },
    );
  }

  Widget _buildSection(TopicSection section) {
    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.bookmark),
        title: Text(
          section.title,
          style: Theme.of(context).textTheme.title,
        ),
        children: section.groups.map(_buildGroup).toList(),
      ),
    );
  }

  // 话题列表
  Widget _buildList() {
    if (sections == null || sections.length <= 0) {
      return Center(
        child: Text('加载失败'),
      );
    } else {
      return ListView(
        children: sections.map(_buildSection).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _loadingFlag
          ? _loading()
          : _buildList(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> _getTopics() async {
    String str = await BaseUtil.httpGet('http://sexinsex.net/bbs/index.php');
    if (str == null) {
      setState(() {
        _loadingFlag = false;
      });
      return;
    }
    DOM.Document document = BaseUtil.parseHtml(str);
    List<DOM.Element> blocks = document.getElementsByClassName('forumlist');
    if (blocks == null || blocks.length <= 0) {
      print('没有找到分区内容');
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
      _loadingFlag = false;
    });
  }
}
