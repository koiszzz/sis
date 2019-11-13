
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
  String titleUrl;
  Thread(String title, String url) {
    this.title = title;
    this.titleUrl = url;
  }
}

class ThreadContent {
  List<MessageContent> messages;
  String id;
  Author author;
  ThreadContent({this.messages, this.id, this.author});
}

class Author {
  String uid;
  String name;
  String postCount;
  String postEssence;
  String fraction;
  String coin;
  String level;
  Author({this.uid});
}

class MessageContent {
  MessageContent({this.type, this.content});
  ContentType type;
  String content;
}

enum ContentType {
  Text, Img
}

enum LoadingState {
  Loading, Failure, Success, NotAuth
}