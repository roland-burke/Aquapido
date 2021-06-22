import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shake/shake.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:flutter/src/painting/gradient.dart' as gradient;

import '../Models/SettingsModel.dart';
import '../Widgets/home/CupSizeElement.dart';
import '../Widgets/onboarding/QuickAddDialog.dart';
import '../Widgets/home/HistoryListElement.dart';
import '../Models/Water.dart';
import '../Utils/Utils.dart';
import '../Models/WaterModel.dart';
import '../Utils/Constants.dart';
import '../src/ReminderNotification.dart';

import 'package:rive/rive.dart';

typedef void DeleteCallback(int index);

class Home extends StatefulWidget {
  Home({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _unit = 'ml';

  static const stream =
      const EventChannel('com.example.flutter_application_1/stream');

  StreamSubscription _buttonEventStream;

  Artboard _riveArtboard;
  RiveAnimationController _controller;
  SimpleAnimation _animation = SimpleAnimation('100%');
  final _myController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    ReminderNotification.initialize();
    ReminderNotification.checkPermission(context);

    _updateWaterGlass();

    if (_buttonEventStream == null) {
      debugPrint('initialize stream');
      _buttonEventStream =
          stream.receiveBroadcastStream().listen(evaluateEvent);

      if (!Provider.of<SettingsModel>(context, listen: false).dialogSeen)
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await showDialog<String>(
              context: context,
              builder: (BuildContext context) => QuickAddDialog(
                    text: "rgdfg",
                    title: "dfgdfg",
                    descriptions: "44",
                  ));
        });
    }

    ShakeDetector.autoStart(onPhoneShake: () {
      _addWaterCup(
          Water(
              dateTime: DateTime.now(),
              cupSize: context.watch<SettingsModel>().cupSize),
          0,
          1);
    });

    // Load the animation file from the bundle, note that you could also
    // download this. The RiveFile just expects a list of bytes.
    rootBundle.load('assets/animations/water-glass.riv').then(
      (data) async {
        // Load the RiveFile from the binary data.
        final file = RiveFile.import(data);
        // The artboard is the root of the animation and gets drawn in the
        // Rive widget.
        final artboard = file.mainArtboard;
        // Add a controller to play back a known animation on the main/default
        // artboard.We store a reference to it so we can toggle playback.
        artboard.addController(_controller = _animation);
        setState(() => {
              _riveArtboard = artboard,
              this._controller.isActive = false,
            });
        _updateWaterGlass();
      },
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _myController.dispose();
    super.dispose();
  }

  void saveCustomSize(customSize, dialogContext, mainContext) {
    setState(() {
      _myController.text = '0';
      Provider.of<SettingsModel>(mainContext, listen: false)
          .addCustomCupSize(customSize);
      Navigator.pop(dialogContext);
    });
  }

  bool isCustomSizeValid(TextEditingController controller) {
    int customSize = int.tryParse(controller.text) ?? -1;
    if (customSize >= 50 && customSize <= 5000) {
      return true;
    }
    return false;
  }

  void showCustomSizeAddDialog(mainContext) {
    bool isInputValid = false;
    showDialog(
        context: mainContext,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return SimpleDialog(
                contentPadding: EdgeInsets.all(16),
                title: const Text('Add Size'),
                children: [
                  TextFormField(
                    controller: _myController,
                    onChanged: (value) {
                      setState(() {
                        isInputValid = isCustomSizeValid(_myController);
                      });
                    },
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                            child: const Text('Cancel'),
                            onPressed: () {
                              _myController.text = '0';
                              Navigator.pop(context);
                            }), // button 1
                        ElevatedButton(
                          child: const Text('Save'),
                          onPressed: (isInputValid)
                              ? () => saveCustomSize(
                                  int.parse(_myController.text),
                                  context,
                                  mainContext)
                              : null,
                        ), // button 2
                      ])
                ],
              );
            },
          );
        });
  }

  void _updateWaterGlass() {
    if (_controller != null) {
      setState(() {
        //_controller.isActive = true;
        double currentWater = Provider.of<WaterModel>(context, listen: false)
                .totalWaterAmountPerDay(DateTime.now()) /
            Provider.of<SettingsModel>(context, listen: false).dailyGoal;
        _animation.instance.reset();
        _animation.instance.advance(currentWater);
        _controller.apply(_riveArtboard, currentWater);
      });
    }
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> evaluateEvent(event) async {
    var arr = event.split(',');
    debugPrint(event);
    if (arr[0] == 'power') {
      _addWaterCup(
          Water(
              dateTime: DateTime.now(),
              cupSize:
                  Provider.of<SettingsModel>(context, listen: false).cupSize),
          0,
          int.parse(arr[1]));
    }
    if (arr[0] == 'shake') {
      _addWaterCup(
          Water(
              dateTime: DateTime.now(),
              cupSize:
                  Provider.of<SettingsModel>(context, listen: false).cupSize),
          0,
          int.parse(arr[1]));
    }
  }

  Future<void> _addWaterCup(Water water, int index, int amountOfCups) async {
    if (amountOfCups != 0) {
      if (mounted) {
        Provider.of<WaterModel>(context, listen: false).addWater(index, water);
      } else {
        print('not mounted');
      }
    }
  }

  void _delete(index) async {
    Water water =
        Provider.of<WaterModel>(context, listen: false).removeWater(index);
    _updateWaterGlass();
    this._showUndoSnackBar(index, water);
  }

  void _showUndoSnackBar(index, waterModel) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text('Deleted: ${waterModel.toString()}'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          this._addWaterCup(waterModel, index, 1);
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  double roundDouble(double value, int places){ 
   double mod = pow(10.0, places); 
   return ((value * mod).round().toDouble() / mod); 
}

  void disableListener() {
    debugPrint('disable');
    if (_buttonEventStream != null) {
      _buttonEventStream.cancel();
      _buttonEventStream = null;
    }
  }

  String _formatDailyTotalWaterAmount(dynamic water) {
    if (water >= 1000) {
      water = water / 1000.0;
      _unit = 'L';
      return roundDouble(water.toDb, 2).toString();
    } else {
      _unit = 'ml';
      return water.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke 'debug painting' (press 'p' in the console, choose the
          // 'Toggle Debug Paint' action from the Flutter Inspector in Android
          // Studio, or the 'Toggle Debug Paint' command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Stay Hydrated',
              style: Theme.of(context).textTheme.headline1,
            ),
            Expanded(
              child: 
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cups today:',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      FutureBuilder(
                          future:
                              context.watch<WaterModel>().getTotalCupsToday(),
                          builder:
                              (BuildContext context, AsyncSnapshot<int> text) {
                            return new Text(
                              text.data.toString(),
                              style: Theme.of(context).textTheme.headline5,
                            );
                          }),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_formatDailyTotalWaterAmount(context.watch<WaterModel>().totalWaterAmountPerDay(DateTime.now()))} $_unit',
                        style: Theme.of(context).textTheme.headline2,
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        height: MediaQuery.of(context).size.height * 0.23,
                        width: MediaQuery.of(context).size.width * 0.36,
                        child: _riveArtboard == null
                            ? const Text('Loading')
                            : Rive(artboard: _riveArtboard),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          _addWaterCup(
                              Water(
                                  dateTime: DateTime.now(),
                                  cupSize: Provider.of<SettingsModel>(context,
                                          listen: false)
                                      .cupSize),
                              0,
                              1);
                          _updateWaterGlass();
                        },
                        style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20))),
                        child: Ink(
                          decoration: BoxDecoration(
                              gradient: gradient.LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  Colors.blue,
                                  Colors.lightBlueAccent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20)),
                          child: Container(
                            width: 134,
                            height: 42,
                            alignment: Alignment.center,
                            child: Text(
                              'Add',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cup size:',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      TextButton(
                          child: Row(children: [
                            Text(
                              context
                                      .watch<SettingsModel>()
                                      .cupSize
                                      .toString() +
                                  'ml ',
                              style: Theme.of(context).textTheme.headline5,
                            ),
                            Icon(Icons.edit, color: Colors.black),
                          ]),
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return StatefulBuilder(
                                      builder: (context, setState) {
                                    return SimpleDialog(
                                      contentPadding: const EdgeInsets.all(14),
                                      title: Text('Choose Size'),
                                      children: [
                                        Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.55,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.8,
                                          child: GridView.count(
                                            crossAxisCount: 3,
                                            children: Provider.of<
                                                        SettingsModel>(context,
                                                    listen: true)
                                                .cupSizes
                                                .map((size) => CupSizeElement(
                                                      size: size,
                                                      isCustom: !Constants
                                                          .cupSizes
                                                          .contains(size),
                                                      mainContext: context,
                                                      dialogContext:
                                                          dialogContext,
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                        OutlinedButton(
                                          onPressed: () {
                                            showCustomSizeAddDialog(context);
                                          },
                                          child: const Text('Add'),
                                        )
                                      ],
                                    );
                                  });
                                });
                          }),
                    ],
                  ),
                  
                ],
              ),
            ),
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(top: 0, right: 11, bottom: 11, left: 11),
                elevation: Constants.CARD_ELEVATION,
                color: Color(0xFFE7F3FF),
                child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: Provider.of<WaterModel>(context, listen: true)
                        .history
                        .length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        child: HistoryListElement(
                            index,
                            Constants.cupImages[getImageIndex(
                                Provider.of<WaterModel>(context, listen: true)
                                    .history[index]
                                    .cupSize)],
                            Provider.of<WaterModel>(context, listen: true)
                                .history[index],
                            _delete),
                      );
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
