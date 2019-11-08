import 'package:flutter/material.dart';
import 'package:sis/component/thread_component.dart';
import 'package:sis/component/thread_group_component.dart';

import 'component/index_component.dart';

final Map<String, WidgetBuilder> kAppRoutingTable = {
  '/': (context) => IndexComponent(title: '主页'),
  'group': (context) => ThreadGroupComponent(group: ModalRoute.of(context).settings.arguments,),
  'thread': (context) => ThreadComponent(thread: ModalRoute.of(context).settings.arguments,)
};