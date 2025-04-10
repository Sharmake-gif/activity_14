mport 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

Future<void> _messageHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  runApp(MessagingTutorial());
}

class MessagingTutorial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Messaging',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: 'Firebase Messaging'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FirebaseMessaging messaging;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    messaging = FirebaseMessaging.instance;
    _setupFCM();
  }

  void _setupFCM() async {
    // Request permission
    NotificationSettings settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      print("Permission granted");

      try {
        String? token = await messaging.getToken();
        setState(() {
          _fcmToken = token;
        });
        print("FCM Token: $_fcmToken");
      } catch (e) {
        print("Error getting token: $e");
      }
    } else {
      print("Notification permission denied");
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String msg =
          message.data['message'] ?? message.notification?.body ?? "No message";
      String type = message.data['type'] ?? 'regular';

      _showNotificationDialog(type, msg);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Notification clicked!');
    });

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      messaging.subscribeToTopic("messaging");
    }
  }

  void _showNotificationDialog(String type, String message) {
    Color backgroundColor =
        type == 'important' ? Colors.red[100]! : Colors.white;
    String title =
        type == 'important'
            ? 'This is a Important Notification!!'
            : 'Notification';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title!)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Messaging Tutorial", style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Text(
              "Your FCM Token:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            SelectableText(
              _fcmToken ?? "Fetching token...",
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 20),
            Text(
              "Send test messages from Firebase Console.\nAdd a custom data field `type: important` to trigger red alerts.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

