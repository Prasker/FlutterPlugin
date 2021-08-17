import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_plugin/flutter_plugin.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _textureId = 0;

  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {

    print("-----------------build${this._textureId}");
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child:Stack(
            children: [
              Positioned(
                top: 10,
                left: 10,
                width: 300,
                height: 300,
                child: Texture(textureId: this._textureId),
              ),
              Positioned(
                  left: 50,
                  bottom: 10,
                  child: Row(
                    children: [
                      FlatButton(
                          onPressed: () {
                            start();
                          },
                          child: Container(
                            color: Colors.teal,
                            padding: EdgeInsets.all(5),
                            child: Text("start"),
                          )),
                      SizedBox.fromSize(size: Size(50, 0),),

                      FlatButton(
                          onPressed: () {
                            stop();
                          },
                          child: Container(
                            color: Colors.teal,
                            padding: EdgeInsets.all(5),
                            child: Text("stop"),
                          )),
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }


  start() async{
    this._textureId = await FlutterPlugin.platformTextureID;
    setState((){

    });
  }



  stop() {
    FlutterPlugin.platformStop();
    this._textureId = 0;
  }
}
