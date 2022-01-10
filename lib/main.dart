import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:awesome_dropdown/awesome_dropdown.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Średnia ocen',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _ctrl1 = TextEditingController();
  var _ctrl2 = TextEditingController();
  var headers = {
    HttpHeaders.authorizationHeader:
        "Basic Mjg6ODRmZGQzYTg3YjAzZDNlYTZmZmU3NzdiNThiMzMyYjE=",
  };
  var grades = {},
      gradesCp = {},
      subjects = {},
      categories = {},
      teachers = {},
      comments = {},
      averages = {};
  String error = '';
  int screen = 0;
  List<String> listSubs = [];
  String dropdownValue = 'Wybierz przedmiot',
      avg = '-',
      newAvg = '-',
      ocena = "6",
      waga = "3";
  List<Widget> notes = [];

  login() async {
    try {
      var res = await post(Uri.parse('https://api.librus.pl/OAuth/Token'),
          body: {
            "username": this._ctrl1.text,
            "password": this._ctrl2.text,
            "librus_long_term_token": "1",
            "grant_type": "password",
          },
          headers: headers);

      var data = jsonDecode(res.body);
      print(data['error']);
      if (data["error"] == "invalid_grant")
        throw "Nieprawidłowy login lub hasło";

      headers[HttpHeaders.authorizationHeader] =
          "Bearer " + data['access_token'];
      return true;
    } on String catch (err) {
      print(err);
      return false;
    } on Exception catch (err) {
      print(err);
    }
  }

  getData(String uri) async {
    var res = await get(Uri.parse(uri), headers: headers);
    return jsonDecode(res.body);
  }

  getSubjects() async {
    if (subjects.isEmpty) {
      var r = await getData("https://api.librus.pl/2.0/Subjects");
      for (var i in r["Subjects"]) {
        subjects[i["Id"]] = i["Name"];
        listSubs.add(i["Name"]);
      }
    }
  }

  getCategories() async {
    if (categories.isEmpty) {
      var r = await getData("https://api.librus.pl/2.0/Grades/Categories");
      var w;

      for (var i in r["Categories"]) {
        if (i.containsKey("Weight"))
          w = i["Weight"];
        else
          w = null;

        if (i["CountToTheAverage"])
          i["CountToTheAverage"] = true;
        else
          i["CountToTheAverage"] = false;

        categories[i["Id"]] = {
          "Name": i["Name"],
          "Weight": w,
          "CountToTheAverage": i["CountToTheAverage"]
        };
      }
    }
  }

  getTeachers() async {
    if (teachers.isEmpty) {
      var r = await getData("https://api.librus.pl/2.0/Users");

      for (var i in r["Users"]) {
        teachers[i["Id"]] = {
          "FirstName": i["FirstName"],
          "LastName": i["LastName"]
        };
      }
    }
  }

  getComments() async {
    if (comments.isEmpty) {
      var r = getData('http://api.librus.pl/2.0/Grades/Comments');

      for (var i in r["Comments"]) {
        comments[i["Id"]] = {"Text": i["Text"]};
      }
    }
  }

  getGrades() async {
    var r = await getData('https://api.librus.pl/2.0/Grades');

    if (subjects.isEmpty) await getSubjects();
    if (categories.isEmpty) await getCategories();
    if (teachers.isEmpty) await getTeachers();
    if (grades.isEmpty) {
      for (var i in subjects.values) {
        grades[i] = [];
      }
    }

    for (var i in r["Grades"]) {
      if (![
        "1",
        "1+",
        "2-",
        "2",
        "2+",
        "3-",
        "3",
        "3+",
        "4-",
        "4",
        "4+",
        "5-",
        "5",
        "5+",
        "6-",
        "6"
      ].contains(i["Grade"])) continue;
      if (!categories[i["Category"]["Id"]]["CountToTheAverage"]) continue;
      grades[subjects[i["Subject"]["Id"]]].add({
        "Grade": i["Grade"],
        "Weight": categories[i["Category"]["Id"]]["Weight"],
      });
    }

    for (var s in grades.keys) {
      for (var i = 0; i < grades[s].length; i++) {
        if (grades[s][i]["Grade"].length > 1) {
          if (grades[s][i]["Grade"][1] == "+")
            grades[s][i]["Grade"] =
                double.parse(grades[s][i]["Grade"][0]) + 0.5;
          else
            grades[s][i]["Grade"] =
                double.parse(grades[s][i]["Grade"][0]) - 0.25;
        } else {
          grades[s][i]["Grade"] = double.parse(grades[s][i]["Grade"]);
        }
      }
      gradesCp[s] = List.from(grades[s]);
    }
  }

  getAverage(String subject) {
    double sum = 0;
    double num = 0;
    for (var g in grades[subject]) {
      double v = g["Grade"] * g["Weight"];
      sum += v;
      num += v / g["Grade"];
    }
    if (num != 0) return (sum / num).toStringAsFixed(2);
    return 'Brak ocen';
  }

  @override
  Widget build(BuildContext context) {
    List screens = [
      Padding(
          padding: EdgeInsets.symmetric(horizontal: 46),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Zaloguj się do Librusa',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 40),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: TextField(
                    controller: this._ctrl1,
                    cursorColor: Colors.white,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                    decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white)),
                        labelText: 'Login',
                        labelStyle: TextStyle(color: Colors.white)),
                  )),
              Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: TextField(
                    cursorColor: Colors.white,
                    controller: this._ctrl2,
                    obscureText: true,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                    decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Colors.white,
                        ),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white)),
                        labelText: 'Hasło',
                        labelStyle: TextStyle(color: Colors.white)),
                  )),
              Padding(
                  padding: EdgeInsets.only(top: 64),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      elevation:
                          MaterialStateProperty.resolveWith((states) => 2),
                      backgroundColor: MaterialStateColor.resolveWith(
                          (states) => Colors.purpleAccent),
                      shadowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.black),
                    ),
                    onPressed: () async {
                      var log = await this.login();
                      if (log) {
                        await getGrades();
                        setState(() {
                          this.error = '';
                          this.screen = 1;
                        });
                      } else {
                        setState(() {
                          this.error = "Coś poszło nie tak";
                        });
                      }
                    },
                    child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                        child: Text(
                          'Zaloguj się',
                          style: TextStyle(fontSize: 20),
                        )),
                  )),
              Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    this.error,
                    style: TextStyle(color: Colors.white),
                  ))
            ],
          )),
      Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          SizedBox(height: 20),
          AwesomeDropDown(
            dropDownList: listSubs,
            numOfListItemToShow: 10,
            dropDownBGColor: Colors.purpleAccent,
            selectedItemTextStyle: TextStyle(color: Colors.white, fontSize: 20),
            dropDownOverlayBGColor: Color(0xffcf28ec),
            dropDownListTextStyle: TextStyle(color: Colors.white, fontSize: 18),
            selectedItem: dropdownValue,
            onDropDownItemClick: (item) {
              if (dropdownValue != "Wybierz przedmiot")
                grades[dropdownValue] = List.from(gradesCp[dropdownValue]);
              dropdownValue = item;
              avg = getAverage(item).toString();
              newAvg = avg;
              this.notes = [];
              setState(() {});
            },
          ),
          SizedBox(height: 40),
          Text("Obecna średnia: $avg",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("Nowa średnia: $newAvg",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 36),
          ElevatedButton(
            style: ButtonStyle(
                elevation: MaterialStateProperty.resolveWith((states) => 5),
                backgroundColor: MaterialStateProperty.resolveWith(
                    (states) => Colors.purpleAccent),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)))),
            onPressed: () {
              if (avg == '-') {
                showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                        title: Text("Nieprawidłowa akcja"),
                        content: Text("Wybierz przedmiot, aby kontynuować"),
                        elevation: 24,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))));
              } else {
                showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                        title: Text('Dodaj ocenę'),
                        actions: [
                          TextButton(
                              onPressed: () {
                                if (ocena.length > 1) {
                                  if (ocena[1] == "+")
                                    grades[dropdownValue].add({
                                      "Grade": double.parse(ocena[0]) + 0.5,
                                      "Weight": double.parse(waga)
                                    });
                                  else
                                    grades[dropdownValue].add({
                                      "Grade": double.parse(ocena[0]) - 0.25,
                                      "Weight": double.parse(waga)
                                    });
                                } else
                                  grades[dropdownValue].add({
                                    "Grade": double.parse(ocena),
                                    "Weight": double.parse(waga)
                                  });
                                Navigator.pop(context);
                                newAvg = getAverage(dropdownValue);
                                this.notes.add(Grade(
                                    parent: this,
                                    index: grades[dropdownValue].length - 1,
                                    subject: dropdownValue));
                                setState(() {});
                              },
                              child: Text("OK"))
                        ],
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Ocena: "),
                            AwesomeDropDown(
                                numOfListItemToShow: 7,
                                selectedItem: ocena,
                                onDropDownItemClick: (value) {
                                  ocena = value;
                                },
                                dropDownList: [
                                  "6",
                                  "6-",
                                  "5+",
                                  "5",
                                  "5-",
                                  "4+",
                                  "4",
                                  "4-",
                                  "3+",
                                  "3",
                                  "3-",
                                  "2+",
                                  "2",
                                  "2-",
                                  "1+",
                                  "1"
                                ]),
                            SizedBox(height: 15),
                            Text("Waga: "),
                            AwesomeDropDown(
                              selectedItem: waga,
                              numOfListItemToShow: 3,
                              dropDownList: ["3", "2", "1"],
                              onDropDownItemClick: (value) {
                                waga = value;
                              },
                            )
                          ],
                        )));
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 34),
                SizedBox(width: 10, height: 50),
                Text('Dodaj ocenę',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(width: 10)
              ],
            ),
          ),
          SizedBox(
            height: 48,
          ),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Column(children: notes)),
        ]),
      ),
    ];
    return Scaffold(
        backgroundColor: Color(0xff9a44bd), body: screens[this.screen]);
  }
}

// ignore: must_be_immutable
class Grade extends StatelessWidget {
  Grade(
      {Key? key,
      required this.index,
      required this.subject,
      required this.parent})
      : super(key: key);
  int index;
  final String subject;
  final parent;

  get getIndex {
    return index;
  }

  void changeIndex() {
    index--;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
          elevation: MaterialStateProperty.resolveWith((states) => 5),
          backgroundColor: MaterialStateProperty.resolveWith(
              (states) => Colors.purpleAccent),
          shape: MaterialStateProperty.resolveWith((states) =>
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)))),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Text(
            'Ocena: ${parent.grades[subject][index]["Grade"]}, Waga: ${parent.grades[subject][index]["Weight"]}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      onPressed: () {},
      onLongPress: () {
        parent.grades[subject].removeAt(index);
        parent.notes.removeAt(index - parent.gradesCp[subject].length);
        parent.newAvg = parent.getAverage(subject);
        for (var n in parent.notes) {
          if (n.getIndex > index) n.changeIndex();
        }
        parent.setState(() {});
      },
    );
  }
}
