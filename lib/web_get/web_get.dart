import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vertretungsplan_v3/web_get/roro_parse.dart';
import 'package:vertretungsplan_v3/database/database.dart';
import 'package:http/http.dart' as http;

const urlPartial =
    'http://www.romain-rolland-gymnasium.eu/schuelerbereich/svplaneinseitig/';

Future<bool> probeCredentials(String credentials) async {
  return !latin1
      .decode((await http.get('${urlPartial}Index.html',
              headers: {'Authorization': 'Basic $credentials'}))
          .bodyBytes)
      .contains('abgebrochen');
}

Future<Widget> getAllSites(VoidCallback setState) async {
  final prefs = await SharedPreferences.getInstance();
  final urls = prefs.getStringList('urls');
  final database = new ScheduleDatabase();
  await database.configure();

  final sites = List<Widget>();
  final dates = List<Widget>();

  for (final url in urls) {
    sites.add(await Schedule.getAll(database, url.hashCode));
    dates.add(Tab(text: await Schedule.getDate(url.hashCode)));
  }

  return DefaultTabController(
      length: sites.length,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: dates,
          ),
          title: Text(
              'Vertretungsplan vom ${await Schedule.getGlobalUpdateDate()}'),
        ),
        body: TabBarView(children: sites),
        floatingActionButton: ActionChip(
            label: Text('Neuen Plan anzeigen'),
            backgroundColor: Color.fromRGBO(68, 179, 162, 1.0),
            onPressed: () {
              setState();
            }),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ));
}

Future<bool> refresh() async {
  final prefs = await SharedPreferences.getInstance();

  if (!(await probeCredentials(prefs.getString('login'))))
    await prefs.setBool('loginSuccess', false);

  final res = await http.get('${urlPartial}Index.html',
      headers: {'Authorization': 'Basic ${prefs.getString('login')}'});

  final urls = await Schedule.extractUrls(latin1.decode(res.bodyBytes));

  bool out = false;

  ScheduleDatabase database = new ScheduleDatabase();
  for (final url in urls) {
    final oldDate = await Schedule.getUpdateDate(url.hashCode);

    await database.configure();
    await database.deleteTable(url.hashCode);
    await Schedule.parseSchedule(
        database,
        latin1.decode((await http.get(url, headers: {
          'Authorization': 'Basic ${prefs.getString('login')}'
        }))
            .bodyBytes),
        url.hashCode);

    if (oldDate != await Schedule.getUpdateDate(url.hashCode)) out = true;
  }

  await prefs.setStringList('urls', urls);

  return out;
}
