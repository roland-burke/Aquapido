import 'package:flutter/material.dart';
import '../icons/my_flutter_app_icons.dart';
import '../Persistence/Database.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:time_range_picker/time_range_picker.dart';
import '../Models/SettingsModel.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  Settings({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  List<int> cupSizes = [100, 200, 300, 330, 400, 500];
  List<Icon> icons = [
    Icon(MyFlutterApp.cup_100ml),
    Icon(MyFlutterApp.cup_200ml),
    Icon(MyFlutterApp.cup_300ml),
    Icon(MyFlutterApp.cup_330ml),
    Icon(MyFlutterApp.cup_400ml),
    Icon(MyFlutterApp.cup_400ml)
  ];
  Map<String, String> languageCodeMap = {"en": "English", "de": "Deutsch"};

  List<ClockLabel> _clockLabels = [
    ClockLabel.fromTime(time: TimeOfDay(hour: 3, minute: 0), text: '3'),
    ClockLabel.fromTime(time: TimeOfDay(hour: 6, minute: 0), text: '6'),
    ClockLabel.fromTime(time: TimeOfDay(hour: 9, minute: 0), text: '9'),
    ClockLabel.fromTime(time: TimeOfDay(hour: 12, minute: 0), text: '12'),
    ClockLabel.fromTime(time: TimeOfDay(hour: 15, minute: 0), text: '15'),
    ClockLabel.fromTime(time: TimeOfDay(hour: 18, minute: 0), text: '18'),
    ClockLabel.fromTime(time: TimeOfDay(hour: 21, minute: 0), text: '21'),
    ClockLabel.fromTime(time: TimeOfDay(hour: 24, minute: 0), text: '0')
  ];

  TimeOfDay _timePickerStart = TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _timePickerEnd = TimeOfDay(hour: 8, minute: 0);

  String _weightUnit = 'kg';

  String _language = 'en';
  final myController = TextEditingController(text: '0');

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  void _reset() {
    //saveCurrentCupCounter(0);
    clearWaterTable();
  }

  void saveCustomSize(customSize) {
    setState(() {
      this.cupSizes.add(customSize);
      this.icons.add(Icon(MyFlutterApp.cup_400ml));
    });
  }

  List<Widget> createDialogOptions(context, reportState) {
    List<Widget> sizeOptions = [];

    // asMap() to get index and item
    cupSizes.asMap().forEach((index, size) {
      return sizeOptions.add(
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            reportState.updateCupSize(size);
          },
          child: ListTile(
            title: Text('$size ml'),
            leading: icons[index],
          ),
        ),
      );
    });
    sizeOptions.add(OutlinedButton(
        onPressed: () {
          setState(() {
            showCustomSizeAddDialog();
          });
        },
        child: Text("Add")));
    return sizeOptions;
  }

  void showCustomSizeAddDialog() {
    showDialog(
        context: context,
        builder: (_) => SimpleDialog(
              contentPadding: EdgeInsets.all(16),
              title: Text('Add Size'),
              children: [
                TextFormField(
                  controller: myController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Custom Cup Size (ml)',
                    border: OutlineInputBorder(),
                  ),
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                          child: Text('Cancel'),
                          onPressed: () => Navigator.pop(context)), // button 1
                      ElevatedButton(
                        child: Text('Save'),
                        onPressed: () {
                          setState(() {
                            saveCustomSize(int.parse(myController.text));
                            myController.clear();
                            Navigator.pop(context);
                          });
                        },
                      ), // button 2
                    ])
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    var reportState = Provider.of<SettingsModel>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              ListTile(
                title: Text(
                  'settings.general_settings.title',
                  style: Theme.of(context).textTheme.headline5,
                ).tr(),
              ),
              ListTile(
                title: Text('settings.general_settings.sleep_time').tr(),
                trailing: TextButton(
                  child: Text(this._timePickerStart.format(context) +
                      " - " +
                      this._timePickerEnd.format(context)),
                  onPressed: () async {
                    TimeRange result = await showTimeRangePicker(
                        context: context,
                        labels: this._clockLabels,
                        rotateLabels: false,
                        ticks: 24,
                        ticksLength: 8.0,
                        ticksWidth: 2.0,
                        ticksOffset: 5.0,
                        ticksColor: Colors.black45,
                        start: _timePickerStart,
                        end: _timePickerEnd,
                        use24HourFormat: true);
                    if (result != null) {
                      this._timePickerStart = result.startTime;
                      this._timePickerEnd = result.endTime;
                    }
                  },
                ),
              ),
              ListTile(
                title: Text('settings.general_settings.reminder_interval').tr(),
                trailing: TextButton(
                  child: Text(
                      context.watch<SettingsModel>().interval.toString() +
                          ' min'),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return SimpleDialog(
                                contentPadding: EdgeInsets.all(16),
                                title: Text('Set Interval'),
                                children: [
                                  NumberPicker(
                                    value:
                                        context.read<SettingsModel>().interval,
                                    minValue: 15,
                                    maxValue: 180,
                                    haptics: true,
                                    itemCount: 5,
                                    itemHeight: 32,
                                    step: 15,
                                    textMapper: (numberText) =>
                                        numberText + ' min',
                                    onChanged: (value) => setState(() => context
                                        .read<SettingsModel>()
                                        .updateInterval(value)),
                                  ),
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        TextButton(
                                            child: Text('Cancel'),
                                            onPressed: () {
                                              context.read<SettingsModel>().reset();
                                              Navigator.pop(context);
                                            }), // button 1
                                        ElevatedButton(
                                          child: Text('Save'),
                                          onPressed: () {
                                            context
                                                .read<SettingsModel>()
                                                .saveInterval();
                                            debugPrint("saved");
                                            Navigator.pop(context);
                                          },
                                        ), // button 2
                                      ])
                                ],
                              );
                            },
                          );
                        });
                  },
                ),
              ),
              ListTile(
                title: Text('settings.general_settings.cup_size').tr(),
                trailing: TextButton(
                    child: Text(context.watch<SettingsModel>().cupSize.toString() + ' ml'),
                    onPressed: () {
                      setState(() {
                        showDialog(
                            context: context,
                            builder: (_) =>
                                ChangeNotifierProvider<SettingsModel>.value(
                                  value: reportState,
                                  child: SimpleDialog(
                                    contentPadding: EdgeInsets.all(16),
                                    title: Text('Choose Size'),
                                    children: createDialogOptions(context, reportState),
                                  ),
                                ));
                      });
                    }),
              ),
              ListTile(
                title: Text('settings.general_settings.language').tr(),
                trailing: DropdownButton<Locale>(
                  value: context.supportedLocales.firstWhere((langLocale) =>
                      langLocale.languageCode == this._language),
                  items: context.supportedLocales
                      .map<DropdownMenuItem<Locale>>((Locale langLocale) {
                    return DropdownMenuItem<Locale>(
                      value: langLocale,
                      child: Text(languageCodeMap[langLocale.languageCode]),
                    );
                  }).toList(),
                  onChanged: (langLocale) {
                    context.setLocale(langLocale);
                    this._language = langLocale.languageCode;
                    context
                        .read<SettingsModel>()
                        .updateLanguage(langLocale.languageCode);
                  },
                ),
              ),
              const Divider(
                height: 40,
                thickness: 1,
                indent: 10,
                endIndent: 10,
              ),
              Column(
                children: [
                  ListTile(
                    title: Text(
                      'settings.quick_settings.title',
                      style: Theme.of(context).textTheme.headline5,
                    ).tr(),
                  ),
                  SwitchListTile(
                      value: context.watch<SettingsModel>().powerSettings,
                      title: Text('settings.quick_settings.quick_power').tr(),
                      onChanged: (value) {
                        setState(() {
                          context
                              .read<SettingsModel>()
                              .updatePowerSettings(value);
                        });
                      }),
                  SwitchListTile(
                      value: context.watch<SettingsModel>().shakeSettings,
                      title: Text('settings.quick_settings.quick_shaking').tr(),
                      onChanged: (value) {
                        setState(() {
                          context.read<SettingsModel>().updateShakeSettings(value);
                        });
                      }),
                  SwitchListTile(
                      value: false,
                      title:
                          Text('settings.quick_settings.quick_gesture').tr()),
                ],
              ),
              const Divider(
                height: 40,
                thickness: 1,
                indent: 10,
                endIndent: 10,
              ),
              Column(
                children: [
                  ListTile(
                    title: Text(
                      'settings.personal_settings.title',
                      style: Theme.of(context).textTheme.headline5,
                    ).tr(),
                  ),
                  ListTile(
                    title: Text('settings.personal_settings.weight').tr(),
                    trailing: TextButton(
                      child: Text(
                          context.watch<SettingsModel>().weight.toString() +
                              ' ' +
                              _weightUnit),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return SimpleDialog(
                                    contentPadding: EdgeInsets.all(16),
                                    title: Text('Set Weight'),
                                    children: [
                                      NumberPicker(
                                          value: context
                                              .read<SettingsModel>()
                                              .weight,
                                          minValue: 40,
                                          maxValue: 150,
                                          haptics: true,
                                          itemCount: 5,
                                          itemHeight: 32,
                                          textMapper: (numberText) =>
                                              numberText + ' ' + _weightUnit,
                                          onChanged: (value) => setState(() =>
                                              context
                                                  .read<SettingsModel>()
                                                  .updateWeight(value))),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: <Widget>[
                                            TextButton(
                                                child: Text('Cancel'),
                                                onPressed: () {
                                                  context.read<SettingsModel>().reset();
                                                  Navigator.pop(context);
                                                }), // button 1
                                            ElevatedButton(
                                              child: Text('Save'),
                                              onPressed: () {
                                                context
                                                    .read<SettingsModel>()
                                                    .saveWeight();
                                                Navigator.pop(context);
                                              },
                                            ), // button 2
                                          ])
                                    ],
                                  );
                                },
                              );
                            });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('settings.personal_settings.gender').tr(),
                    trailing: DropdownButton(
                      value: context.watch<SettingsModel>().gender,
                      items: <DropdownMenuItem>[
                        DropdownMenuItem(
                          value: 'choose',
                          child: Text('Choose'),
                        ),
                        DropdownMenuItem(
                          value: 'male',
                          child: Text('Male'),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Female'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          context.read<SettingsModel>().updateGender(value);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const Divider(
                height: 40,
                thickness: 1,
                indent: 10,
                endIndent: 10,
              ),
              new Container(
                margin: const EdgeInsets.only(top: 2, bottom: 20),
                padding: const EdgeInsets.only(
                    top: 3, bottom: 3, left: 100, right: 100),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(
                          6.0) //                 <--- border radius here
                      ),
                ),
                child: OutlinedButton(
                    onPressed: () => {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return SimpleDialog(
                                      contentPadding: EdgeInsets.all(16),
                                      title: Text('Reset - Are you sure?'),
                                      children: [
                                        Text(
                                            'This action can NOT be undone. All data will be lost!'),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: <Widget>[
                                              TextButton(
                                                  child: Text('Cancel'),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  }), // button 1
                                              ElevatedButton(
                                                child: Text('Reset'),
                                                onPressed: () {
                                                  this._reset();
                                                  Navigator.pop(context);
                                                },
                                              ), // button 2
                                            ])
                                      ],
                                    );
                                  },
                                );
                              })
                        },
                    child: Text('Reset')),
              )
            ],
          ),
        ),
      ),
    );
  }
}
