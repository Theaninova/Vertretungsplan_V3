import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'web_get/web_get.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('loginSuccess') == true) {
    runApp(MyApp());
  } else {
    runApp(LoginApp());
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primaryColor: Color.fromRGBO(1, 103, 169, 1.0),
          accentColor: Color.fromRGBO(68, 179, 162, 1.0),
        ),
        home: MyHomePage() // MyHomePage(title: 'Flutter Demo Home Page'),
        );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return new FutureBuilder<Widget>(
      future: getAllSites(() {
        setState(() {

        });
      }), // a Future<Widget> or null
      builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return new Text('Press button to start');
          case ConnectionState.waiting:
            return new Scaffold(
              appBar: AppBar(),
              body: Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              ),
            );
          default:
            if (snapshot.hasError)
              return new Text('Error: ${snapshot.error}');
            else
              return snapshot.data;
        }
      },
    );
  }
}
