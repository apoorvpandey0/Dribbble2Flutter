import 'package:flutter/material.dart';
import 'package:dribbble_stepper/widgets/DraggableNumberPicker.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:flutter/services.dart';

void main(){
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(statusBarIconBrightness: Brightness.dark));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  ThemeData simpleTheme = new ThemeData(
    accentColor: Color(0xff594955),
    primaryColor: Color(0xffffffff),
  );

  @override
  Widget build(BuildContext context) {
    FlutterStatusbarcolor.setStatusBarColor(Colors.transparent);
    return MaterialApp(
      theme: simpleTheme,
      home: WidgetDisplay(
        child: new DraggableNumberPicker(),
      ),
    );
  }
}

class WidgetDisplay extends StatelessWidget {

  //Widget to display on screen
  final Widget child;

  WidgetDisplay({
    Key key,
    this.child
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: new Stack(
          children: <Widget>[
            new Align(
              alignment: Alignment.center,
              child: child,
            ),
          ],
        )
    );
  }
}