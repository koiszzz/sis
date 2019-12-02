import 'package:flutter/cupertino.dart';

class TopicSection {
  String title;
  String titleUrl;
  bool isExpanded;
  List<TopicGroup> groups;

  TopicSection(String title, String titleUrl) {
    this.title = title;
    this.titleUrl = titleUrl;
    this.isExpanded = false;
    this.groups = new List();
  }

  addGroup(TopicGroup group) {
    this.groups.add(group);
  }

  addGroupDirect(String groupTitle, String groupUrl) {
    TopicGroup newGroup = new TopicGroup(groupTitle, groupUrl);
    this.groups.add(newGroup);
  }

  addGroups(List<TopicGroup> list) {
    this.groups.addAll(list);
  }
}

class TopicGroup {
  String title;
  String titleUrl;

  TopicGroup(String title, String url) {
    this.title = title;
    this.titleUrl = url;
  }
}

class Thread {
  String title;
  String url;
  String content;

  Thread({@required this.url, @required this.title, this.content});
}

class ThreadContent {
  String message;
  String id;
  Author author;

  ThreadContent({this.message, this.id, this.author});
}

class Author {
  String uid;
  String name;
  String postCount;
  String postEssence;
  String fraction;
  String coin;
  String level;
  String postTime;
  String threadIndex;

  Author({this.uid, this.name, this.threadIndex, this.postTime});
}

enum LoadingState { Loading, Failure, Success, NotAuth }
