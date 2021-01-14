import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:push_notification/item.dart';

class PushMessaging extends StatefulWidget {
  @override
  _PushMessagingState createState() => _PushMessagingState();
}

class _PushMessagingState extends State<PushMessaging> {
  String _homeScreenText = "Waiting for token...";
  bool _topicButtonsDisabled = false;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final TextEditingController _topicController =
      TextEditingController(text: 'topic');

  Widget _buildDialog(BuildContext context, Item item) {
    return AlertDialog(
      content: Text("Item ${item.itemId} has been updated"),
      actions: <Widget>[
        FlatButton(
          child: const Text('CLOSE'),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        FlatButton(
          child: const Text('SHOW'),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }

  Item _itemForMessage(Map<String, dynamic> message) {
    final dynamic data = message['data'] ?? message;
    final String itemId = data['id'];
    final Item item = items.putIfAbsent(itemId, () => Item(itemId: itemId))
      ..status = data['status'];
    return item;
  }

  void _showItemDialog(Map<String, dynamic> message) {
    showDialog<bool>(
      context: context,
      builder: (_) => _buildDialog(context, _itemForMessage(message)),
    ).then((bool shouldNavigate) {
      if (shouldNavigate == true) {
        _navigateToItemDetail(message);
      }
    });
  }

  void _navigateToItemDetail(Map<String, dynamic> message) {
    final Item item = _itemForMessage(message);
    // Clear away dialogs
    Navigator.popUntil(context, (Route<dynamic> route) => route is PageRoute);
    if (!item.route.isCurrent) {
      Navigator.push(context, item.route);
    }
  }

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        _showItemDialog(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        _navigateToItemDetail(message);
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        _navigateToItemDetail(message);
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(
            sound: true, badge: true, alert: true, provisional: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      setState(() {
        _homeScreenText = "Push Messaging token: $token";
      });
      print(_homeScreenText);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Push Messaging Demo'),
        ),
        // For testing -- simulate a message being received
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showItemDialog(<String, dynamic>{
            "data": <String, String>{
              "id": "2",
              "status": "out of stock",
            },
          }),
          tooltip: 'Simulate Message',
          child: const Icon(Icons.message),
        ),
        body: Material(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(_homeScreenText),
                  ),
                ),
                Divider(
                  thickness: 2.0,
                ),
                Row(children: <Widget>[
                  Expanded(
                    child: TextField(
                        controller: _topicController,
                        onChanged: (String v) {
                          setState(() {
                            _topicButtonsDisabled = v.isEmpty;
                          });
                        }),
                  ),
                  FlatButton(
                    child: const Text("subscribe"),
                    onPressed: _topicButtonsDisabled
                        ? null
                        : () {
                            _firebaseMessaging
                                .subscribeToTopic(_topicController.text);
                            _clearTopicText();
                          },
                  ),
                  FlatButton(
                    child: const Text("unsubscribe"),
                    onPressed: _topicButtonsDisabled
                        ? null
                        : () {
                            _firebaseMessaging
                                .unsubscribeFromTopic(_topicController.text);
                            _clearTopicText();
                          },
                  ),
                ])
              ],
            ),
          ),
        ));
  }

  void _clearTopicText() {
    setState(() {
      _topicController.text = "";
      _topicButtonsDisabled = true;
    });
  }
}
