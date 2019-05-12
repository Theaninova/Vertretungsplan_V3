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
        setState(() {});
      }), // a Future<Widget> or null
      builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return new Text('Press button to start');
          case ConnectionState.waiting:
            return new DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  bottom: TabBar(
                    tabs: [
                      Tab(child: Placeholder(130.0, 16.0)),
                      Tab(child: Placeholder(160.0, 16.0)),
                    ],
                  ),
                  title: Placeholder(90.0, 30.0),
                ),
                body: ListView(children: [
                  PlaceholderCard(6, 0),
                  PlaceholderCard(10, 6),
                  PlaceholderCard(4, 10),
                ]),
              ),
            );
          default:
          if (snapshot.hasError) {
              refresh().then((val) {
                setState(() {
                  // in case the database got deleted accidentally
                });
              });
              return new Row(children: [
                Text('Something went wrong.\nPlease wait a second...'),
                CircularProgressIndicator(),
              ]);
            } else
              return snapshot.data;
        }
      },
    );
  }
}

class PlaceholderCard extends StatelessWidget {
  final int rows;
  final int start;
  final widths = [
    200.0,
    190.0,
    130.0,
    140.0,
    190.0,
    90.0,
    180.0,
    200.0,
    120.0,
    150.0,
    210.0,
    180.0
  ];

  PlaceholderCard(this.rows, this.start);

  @override
  Widget build(BuildContext context) {
    List<Widget> placeholders = new List<Widget>();

    for (int i = start; i < rows + start; i++)
      placeholders.add(
        Container(
            margin: EdgeInsets.all(8.0),
            child: Placeholder(widths[i % widths.length], 16.0)),
      );

    return Card(
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: placeholders,
        ),
      ),
    );
  }
}

class Placeholder extends StatelessWidget {
  final double width;
  final double height;

  Placeholder(this.width, this.height);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(0, 0, 0, 0.05),
          borderRadius: BorderRadius.circular(30.0),
        ),
        height: this.height,
        width: this.width,
      ),
      alignment: Alignment.centerLeft,
    );
  }
}

class RefreshChip extends StatefulWidget {
  final VoidCallback refreshCallback;

  RefreshChip(this.refreshCallback);

  @override
  State<StatefulWidget> createState() => _RefreshChipState(refreshCallback);
}

class _RefreshChipState extends State<RefreshChip> {
  VoidCallback refreshCallback;
  bool show = false;

  _RefreshChipState(this.refreshCallback) {
    backgroundRefresh();
  }

  backgroundRefresh() async {
    if (await refresh()) {
      setState(() {
        show = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return show
        ? ActionChip(
            label: Text('Neuen Plan anzeigen'),
            backgroundColor: Colors.white,
            onPressed: () {
              refreshCallback();
              setState(() {
                show = false;
              });
            })
        : Container();
  }
}
