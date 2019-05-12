import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vertretungsplan_v3/web_get/web_get.dart';

import 'main.dart' show MyApp;

class LoginApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primaryColor: Color.fromRGBO(68, 179, 162, 1.0),
          hintColor: Colors.white30,
          disabledColor: Colors.white10,
          indicatorColor: Colors.white70,
          highlightColor: Colors.white70,
          brightness: Brightness.light,
          textTheme: Typography.whiteMountainView,
          primaryTextTheme: Typography.whiteMountainView,
          accentTextTheme: Typography.whiteMountainView,
        ),
        home: Login()// MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class _LoginState extends State<Login> {
  String username = '';
  String password = '';
  bool enabled = true;
  bool failed = false;
  double _opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(1, 103, 169, 1.0),
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: Duration(seconds: 1),
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.all(16.0),
          child: Wrap(
            runSpacing: 16.0,
            children: [
              Image(
                image: AssetImage('assets/img_login.png'),
              ),
              Text('Benutzerdaten eingeben'),
              TextField(
                decoration: InputDecoration(
                    hintText: 'RoRo Benutzername',
                    icon: Icon(Icons.account_circle),
                    border: OutlineInputBorder()),
                textInputAction: TextInputAction.next,
                autocorrect: false,
                autofocus: false,
                onChanged: (text) {
                  username = text;
                },
                onSubmitted: onSubmit,
                enabled: enabled,
              ),
              TextField(
                decoration: InputDecoration(
                    hintText: 'Passwort',
                    icon: Icon(Icons.vpn_key),
                    errorText: failed ? 'Falsches Passwort' : null,
                    border: OutlineInputBorder()),
                obscureText: true,
                autocorrect: false,
                onChanged: (text) {
                  password = text;
                },
                onSubmitted: onSubmit,
                enabled: enabled,
                autofocus: failed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onSubmit(text) async {
    setState(() {
      enabled = false;
    });

    final prefs = await SharedPreferences.getInstance();
    final credentials = base64.encode(utf8.encode('$username:$password'));
    if (await probeCredentials(credentials)) {
      await prefs.setString('login', credentials);
      await prefs.setBool('loginSuccess', true);
      await refresh();
      runApp(new MyApp());
    } else {
      setState(() {
        failed = true;
        enabled = true;
      });
    }
  }
}

class Login extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginState();
}
