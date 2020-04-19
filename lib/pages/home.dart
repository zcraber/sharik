import 'dart:io' show Platform;

import 'package:device_apps/device_apps.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../locale.dart';
import '../models/app.dart';
import '../models/file.dart';
import '../models/page.dart';
import 'app_selector.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _latest = <FileModel>[];
  AppModel _model;

  @override
  void initState() {
    _model = Provider.of<AppModel>(context, listen: false);
    _latest =
        Hive.box('app2').get('latest', defaultValue: []).cast<FileModel>();
    super.initState();
  }

  void saveLatest() {
    Hive.box('app2').put('latest', _latest);
  }

  void shareFile(FileModel file) {
    setState(() {
      if (_latest.contains(file)) _latest.remove(file);

      _latest.insert(0, file);
    });

    saveLatest();
    _model.file = file;
    _model.setState(() => _model.setPage(PageModel.sharing));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
            margin: EdgeInsets.only(left: 24, right: 24, top: 8),
            height: 104,
            child: Material(
              borderRadius: BorderRadius.circular(12),
              color: Colors.deepPurple[400],
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: <Widget>[
                    Center(
                        child: Text(L('Select file', _model.localeAdapter),
                            style: GoogleFonts.andika(
                                textStyle: TextStyle(
                                    color: Colors.white, fontSize: 24)))),
                    Container(
                      margin: EdgeInsets.all(16),
                      child: Align(
                          alignment: Alignment.bottomRight,
                          child: SvgPicture.asset(
                            'assets/icon_file.svg',
                          )),
                    )
                  ],
                ),
                onTap: () async {
                  var f = await FilePicker.getFile();
                  if (f != null && f.path != null && f.path.isNotEmpty) {
                    shareFile(
                        FileModel(data: f.path, type: FileTypeModel.file));
                  }
                },
              ),
            )),
        Row(
          children: <Widget>[
            if (Platform.isAndroid)
              Expanded(
                child: Container(
                    margin: EdgeInsets.only(left: 24, top: 8),
                    height: 48,
                    child: Material(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.deepPurple[400],
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                            child: Text(L('App', _model.localeAdapter),
                                style: GoogleFonts.andika(
                                    textStyle: TextStyle(
                                        color: Colors.white, fontSize: 24)))),
                        onTap: () async {
                          var data = await showDialog(
                                  context: context,
                                  child: AppSelector(_model.localeAdapter))
                              as String;
                          if (data != null && data.isNotEmpty) {
                            var app = await DeviceApps.getApp(data);
                            shareFile(FileModel(
                                type: FileTypeModel.app,
                                data: app.apkFilePath,
                                name: app.appName));
                          }
                        },
                      ),
                    )),
              ),
            SizedBox(
              width: Platform.isAndroid ? 8 : 24,
            ),
            Expanded(
              child: Container(
                  margin: EdgeInsets.only(right: 24, top: 8),
                  height: 48,
                  child: Material(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.deepPurple[400],
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                          child: Text(L('Text', _model.localeAdapter),
                              style: GoogleFonts.andika(
                                  textStyle: TextStyle(
                                      color: Colors.white, fontSize: 24)))),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            var c = TextEditingController();
                            return AlertDialog(
                              title: Text(
                                  L('Type some text', _model.localeAdapter)),
                              content: TextField(
                                controller: c,
                                maxLines: null,
                                minLines: null,
                              ),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text(L('Close', _model.localeAdapter)),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                FlatButton(
                                  child: Text(L('Send', _model.localeAdapter)),
                                  onPressed: () {
                                    Navigator.of(context).pop();

                                    if (c.text.isNotEmpty) {
                                      shareFile(FileModel(
                                          data: c.text,
                                          type: FileTypeModel.text));
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  )),
            ),
          ],
        ),
        SizedBox(
          height: 22,
        ),
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(left: 24, right: 24),
              child: Text(
                L('Latest', _model.localeAdapter),
                style:
                    GoogleFonts.comfortaa(textStyle: TextStyle(fontSize: 24)),
              ),
            ),
            Spacer(),
            Container(
              margin: EdgeInsets.only(right: 24),
              child: IconButton(
                  onPressed: () {
                    setState(() {
                      _latest.clear();
                    });

                    saveLatest();
                  },
                  icon: Icon(
                    Icons.delete,
                    size: 20,
                  )),
            )
          ],
        ),
        Expanded(
          child: Container(
              padding: EdgeInsets.only(left: 24, right: 24),
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 16),
                  itemCount: _latest.length,
                  itemBuilder: (context, index) => card(_latest[index]))),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 18),
          height: 54,
          decoration: BoxDecoration(
              color: Colors.deepPurple[100],
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24), topRight: Radius.circular(24))),
          child: Row(
            children: <Widget>[
              Material(
                color: Colors.deepPurple[100],
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  splashColor: Colors.deepPurple[400],
                  child: Container(
                    margin: EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      'assets/icon_locale.svg',
                      semanticsLabel: 'locale',
                      height: 18,
                    ),
                  ),
                  onTap: () => _model.setPage(PageModel.language),
                ),
              ),
              SizedBox(
                width: 2,
              ),
              Material(
                color: Colors.deepPurple[100],
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  splashColor: Colors.deepPurple[400],
                  child: Container(
                    margin: EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      'assets/icon_help.svg',
                      semanticsLabel: 'help',
                      height: 16,
                    ),
                  ),
                  onTap: () => _model.setPage(PageModel.intro),
                ),
              ),
              Spacer(),
              Material(
                color: Colors.deepPurple[100],
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  splashColor: Colors.deepPurple[400],
                  child: Container(
                    margin: EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      'assets/icon_browser.svg',
                      semanticsLabel: 'instagram',
                      height: 18,
                    ),
                  ),
                  onTap: () async {
                    if (await canLaunch('https://marchello.cf')) {
                      await launch('https://marchello.cf');
                    }
                  },
                ),
              ),
              SizedBox(
                width: 2,
              ),
              Container(
                color: Colors.deepPurple[700],
                height: double.infinity,
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 1,
              ),
              SizedBox(
                width: 2,
              ),
              Material(
                color: Colors.deepPurple[100],
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  splashColor: Colors.deepPurple[400],
                  child: Container(
                    margin: EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      'assets/icon_github.svg',
                      semanticsLabel: 'play store',
                      height: 18,
                    ),
                  ),
                  onTap: () async {
                    if (await canLaunch(
                        'https://github.com/marchellodev/sharik')) {
                      await launch('https://github.com/marchellodev/sharik');
                    }
                  },
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget card(FileModel f) {
    return Container(
      height: 44,
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Colors.deepPurple[300],
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            shareFile(f);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                SvgPicture.asset(
                  f.icon,
                  semanticsLabel: 'file ',
                  width: 18,
                ),
                SizedBox(
                  width: 12,
                ),
                Expanded(
                    child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    f.name,
                    style: GoogleFonts.andika(
                      textStyle: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    maxLines: 1,
                  ),
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
