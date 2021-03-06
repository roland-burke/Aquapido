import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:water_tracker/src/Models/DailyGoalModel.dart';
import 'dart:collection';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';


import '../../src/Models/SettingsModel.dart';

class Event {
  final String title;

  const Event(this.title);

  @override
  String toString() => title;
}

class Calendar extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => CalendarState();
}

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

class CalendarState extends State<Calendar> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay;
  List<DateTime> dailyGoalReachDates;

  LinkedHashMap<DateTime, List<Event>> events = LinkedHashMap(
    equals: isSameDay,
    hashCode: getHashCode,
  );
  List<Color> gradientColors = [
    const Color(0xffed882f),
    const Color(0xfff54831),
  ];

  List<Color> gradientColorsGreen = [
    Colors.green,
    Colors.green[300],
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();

    _selectedDay =
        Provider.of<SettingsModel>(context, listen: false).selectedDate;
  }

  Future<LinkedHashMap<DateTime, List<Event>>> _getEvents() async {
    List<DateTime> goalsReachedDays =
        await Provider.of<DailyGoalModel>(context, listen: false)
            .getGoalsReachedDaysList();

    Map<DateTime, List<Event>> mapEvents = {
      for (var v in goalsReachedDays) v: [Event('Goal reached')]
    };

    events = LinkedHashMap(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(mapEvents);
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 24, right: 8, bottom: 10, left: 7),
      child: FutureBuilder(
          future: _getEvents(),
          builder: (BuildContext context,
              AsyncSnapshot<LinkedHashMap<DateTime, List<Event>>> snapshot) {
            if (snapshot.hasData) events = snapshot.data;

            return TableCalendar(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              availableCalendarFormats: {
                CalendarFormat.month: tr('calendar.month'),
                CalendarFormat.week: tr('calendar.week'),
                CalendarFormat.twoWeeks: tr('calendar.two_weeks')
              },
              selectedDayPredicate: (day) {
                // Use `selectedDayPredicate` to determine which day is currently selected.
                // If this returns true, then `day` will be marked as selected.

                // Using `isSameDay` is recommended to disregard
                // the time-part of compared DateTime objects.
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  // Call `setState()` when updating the selected day
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    Provider.of<SettingsModel>(context, listen: false)
                        .setSelectedDate(_selectedDay);
                    Provider.of<SettingsModel>(context, listen: false)
                        .setDayDiagramm(null);
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  // Call `setState()` when updating calendar format
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                // No need to call `setState()` here
                _focusedDay = focusedDay;
              },
              eventLoader: (day) {
                return events[day] ?? [];
              },
              daysOfWeekStyle: DaysOfWeekStyle(dowTextFormatter: (date, languageCode) => DateFormat( "E", languageCode).format(date),
              ),
              headerStyle: HeaderStyle(
                titleTextFormatter:(date, languageCode) => DateFormat( "yMMMM", languageCode).format(date) ,
                  formatButtonDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  formatButtonTextStyle: TextStyle(color: Colors.white),
              ),
              calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).accentColor
                        ],
                      ),
                      shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.4),
                          Theme.of(context).accentColor.withOpacity(0.4),
                        ],
                      ),
                      shape: BoxShape.circle),
                  markerDecoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColorsGreen),
                    shape: BoxShape.circle,
                  ),
                  markersAutoAligned: true,
                  markerSizeScale: 0.4),
            );
          }),
    );
  }
}
