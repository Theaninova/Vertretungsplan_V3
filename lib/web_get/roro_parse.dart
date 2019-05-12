import 'dart:async';

import 'package:flutter/material.dart' hide Element;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' hide Text;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vertretungsplan_v3/database/database.dart';
import 'package:vertretungsplan_v3/web_get/web_get.dart' show urlPartial;

class Schedule {
  /// Parses the data and inserts it into the database
  static Future<void> parseSchedule(
      ScheduleDatabase database, String schedule, int urlHash) async {
    final doc = parse(schedule);
    final prefs = await SharedPreferences.getInstance();

    String currentClass = 'Aufsicht';
    String currentLesson = '';

    // insert table into database
    for (final table in doc.querySelectorAll('table')) {
      for (final row in table.querySelectorAll('tr')) {
        List<Element> tds = row.querySelectorAll('td');

        if (!tds[0].text.contains('Kl.')) {
          if (!(tds[0].text.trim() == '')) currentClass = tds[0].text.trim();
          if (!(tds[1].text.trim() == '')) currentLesson = tds[1].text.trim();

          await database.insertData(
              urlHash,
              currentClass,
              currentLesson,
              tds[2].text.trim(),
              tds[3].text.trim(),
              tds[4].text.trim(),
              tds[5].text.trim(),
              tds[6].text.trim(),
              tds[7].text.trim());
        }
      }
    }

    await prefs.setString(
        'Day ${urlHash}_Date', doc.querySelector('h2').text.trim());
    await prefs.setString('Day ${urlHash}_UpdateDate',
        doc.children[0].querySelector('h1').text.trim());
  }

  /// Returns the date of a given day
  static Future<String> getDate(int hash) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('Day ${hash}_Date');
  }

  /// Returns the update date of a given date
  static Future<String> getUpdateDate(int hash) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('Day ${hash}_UpdateDate');
  }

  /// Returns a list of all classes
  static Future<List<String>> getClassList(
      ScheduleDatabase db, int index) async {
    List<String> out = new List<String>();

    final res = await db.database.rawQuery(
        'SELECT ${ScheduleDatabase.COL_1} FROM ${ScheduleDatabase.TABLE_NAME}$index GROUP BY ${ScheduleDatabase.COL_1}');

    for (final elm in res) out.add(elm.values.elementAt(0));

    return out;
  }

  static Future<Widget> getClassInfoForSql(
      ScheduleDatabase db, int index, String klasse) async {
    // final res = await db.database.rawQuery(sql);
    final res = await db.database.query('${ScheduleDatabase.TABLE_NAME}$index',
        where: '"${ScheduleDatabase.COL_1}" = "$klasse"');

    List<Row> classInfo = new List<Row>();

    bool forInfo = true;
    String currentLesson = 'x';

    String KLASSE = '';

    for (final elm in res) {
      forInfo = true;
      KLASSE = elm.values.elementAt(1);
      final String STUNDE = elm.values.elementAt(2);
      final String FACH = elm.values.elementAt(3);
      final String RAUM = elm.values.elementAt(4);
      final String VLEHRER = elm.values.elementAt(5);
      final String VFACH = elm.values.elementAt(6);
      final String VRAUM = elm.values.elementAt(7);
      final String INFO = elm.values.elementAt(8);

      /*if (STUNDE.contains(currentLesson)) output = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
      else if (currentLesson.contains('10')) output = '$currentLesson.&nbsp;';
      output = '$STUNDE.&nbsp;&nbsp;';*/

      String output = decide(VFACH, FACH, '[Fach]');

      if (VLEHRER.contains('*Frei')) {
        output += ' entfällt';
        forInfo = false;
      } else if (VLEHRER.contains('Raumänderung')) {
        output += ': Raumänderung in Raum $VRAUM';
        forInfo = false;
      } else if (VLEHRER.contains('*Stillarbeit')) {
        if (VLEHRER.contains('\u00A0'))
          output += ': Stillarbeit';
        else
          output += ': Stillarbeit in Raum $VRAUM';
      }

      if (forInfo)
        output +=
            ' bei ${decideSimple(VLEHRER, '[Lehrer]')} in Raum ${decide(VRAUM, RAUM, '[Raum]')}';

      if (INFO.contains('verschoben'))
        output = '$FACH wird $INFO';
      else if (INFO.contains('anstatt'))
        output += ' $INFO';
      else if (INFO.contains('Aufg. erteilt'))
        output += '\nAufgaben erteilt';
      else if (INFO.contains('Aufg. für zu Hause erteilt'))
        output += '\nAufgaben für Zuhause erteilt';
      else if (INFO.contains('Aufg. für Stillarbeit erteilt'))
        output += '\nAufgaben für Stillarbeit erteilt';
      else if (INFO != '') output += '\n$INFO';

      if (!STUNDE.contains('&nbsp;')) currentLesson = STUNDE;

      classInfo.add(Row(
        children: [
          Container(
            child: Text(
              STUNDE,
              textScaleFactor: 1.0,
            ),
            margin: EdgeInsets.all(8.0),
          ),
          Container(
            child: Text(output),
            margin: EdgeInsets.all(4.0),
          )
        ],
      ));
    }

    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            KLASSE,
            textScaleFactor: 1.5,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: classInfo,
          )
        ],
      ),
    );
  }

  static Future<List<String>> extractUrls(String raw) async {
    final site = parse(raw);
    final table = site.querySelector('table');
    final prefs = await SharedPreferences.getInstance();

    String lastUrl = '';
    final out = List<String>();

    for (final row in table.querySelectorAll('tr')) {
      final tds =
          '$urlPartial${row.querySelector('td').querySelector('a').attributes['href']}';

      if (tds != lastUrl) out.add(tds);

      lastUrl = tds;
    }

    await prefs.setString(
        'GlobalUpdateDate', site.querySelector('h1').text.trim());

    return out;
  }

  static Future<String> getGlobalUpdateDate() async {
    return await (await SharedPreferences.getInstance())
        .get('GlobalUpdateDate');
  }

  static Future<Widget> getAll(ScheduleDatabase db, int index) async {
    List<Widget> list = new List<Widget>();

    final res = await db.database.rawQuery(
        'SELECT ${ScheduleDatabase.COL_1} FROM ${ScheduleDatabase.TABLE_NAME}$index GROUP BY ${ScheduleDatabase.COL_1}');

    for (final elm in res) {
      list.add(Card(
        child: await getClassInfoForSql(db, index, elm.values.elementAt(0)),
        margin: EdgeInsets.all(8.0),
      ));
    }

    return Container(
        child: ListView(scrollDirection: Axis.vertical, children: list));
  }

  static String decide(String primary, String secondary, String fallback) {
    return primary == '' ? secondary == '' ? fallback : secondary : primary;
  }

  static String decideSimple(String primary, String fallback) {
    return primary == '' ? fallback : primary;
  }
}
