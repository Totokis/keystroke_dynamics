import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:pylogger_ultimate/bloc/pylogger_bloc.dart';
import 'package:pylogger_ultimate/simple_bloc_observer.dart';
import 'package:pylogger_ultimate/user.dart';

void main() {
  Bloc.observer = SimpleBlocObserver();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PyloggerPage(),
    );
  }
}

class PyloggerPage extends StatelessWidget {
  const PyloggerPage({key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Typing Biometrics 2.0")),
      body: BlocProvider(
        create: (_) => PyloggerBloc(httpClient: Client()),
        child: MainPage(),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PyloggerBloc, PyloggerState>(builder: ((context, state) {
      switch (state.status) {
        case PyloggerStatus.initial:
          return InitialPage(state.seconds);
        case PyloggerStatus.type:
          return TypePage(state.userName);
        case PyloggerStatus.user_sucess:
          return UserSuccessPage(state.users, state.userName);
        case PyloggerStatus.user_failure:
          return UserFailurePage();
        default:
          return const Center(child: CircularProgressIndicator());
      }
    }));
  }
}

class InitialPage extends StatelessWidget {
  InitialPage(this.seconds);
  final seconds;

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Witaj, musimy się poznać.",
            style: TextStyle(fontSize: 25),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Podaj przez ile sekund chcesz mnie uczyć.",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Material(
                color: Colors.blue, // Button color
                child: InkWell(
                  splashColor: Colors.red, // Splash color
                  onTap: () {
                    context
                        .read<PyloggerBloc>()
                        .add(PyloggerDecrementSeconds());
                  },
                  child: SizedBox(
                      width: 30, height: 30, child: Icon(Icons.remove)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: () => {
                        context
                            .read<PyloggerBloc>()
                            .add(PyloggerRecognizeStarted())
                      },
                  child: Text("Ucz mnie przez ${seconds}'s")),
            ),
            ClipOval(
              child: Material(
                color: Colors.blue, // Button color
                child: InkWell(
                  splashColor: Colors.red, // Splash color
                  onTap: () {
                    context
                        .read<PyloggerBloc>()
                        .add(PyloggerIncrementSeconds());
                  },
                  child:
                      SizedBox(width: 30, height: 30, child: Icon(Icons.add)),
                ),
              ),
            ),
          ],
        ),
      ],
      mainAxisAlignment: MainAxisAlignment.center,
    ));
  }
}

class TypePage extends StatelessWidget {
  TypePage(this.userName);
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            userName.isNotEmpty
                ? Text(
                    "Będę próbował rozpoznać czy jesteś użytkownikiem: $userName",
                    style: TextStyle(fontSize: 25),
                  )
                : Text(
                    "Witaj nieznajomy",
                    style: TextStyle(fontSize: 25),
                  ),
            TextField(
              focusNode: FocusNode()..requestFocus(),
              decoration: new InputDecoration(labelText: "Zacznij coś pisać."),
            ),
            LinearProgressIndicator(),
            Text("Proces uczenia potrwa mniej więcej podaną liczbę sekund")
          ],
        ),
      ),
    );
  }
}

class UserSuccessPage extends StatelessWidget {
  final List<User> users;
  final String userName;
  final List<Color> colorCodes = <Color>[
    Colors.green,
    Colors.teal,
    Colors.lightBlue,
    Colors.blue,
    Colors.blueGrey,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.amber,
    Colors.deepOrange,
  ];

  UserSuccessPage(this.users, this.userName);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Wykryłem że jesteś użytkownikiem: $userName",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            "Na ${(users.firstWhere((element) => "\"" + element.name + "\"" == userName).percentage * 100).toStringAsFixed(1)}% jesteś tym za kogo się podajesz",
            style: TextStyle(fontSize: 15),
          ),
          Text(
            "A poniżej rozkład innych użytkowników",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          AspectRatio(
            aspectRatio: 1.3,
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                    sections: users
                        .map((e) => PieChartSectionData(
                            radius: 100,
                            value: e.percentage,
                            title:
                                "${e.name}: ${(e.percentage * 100).toStringAsFixed(2)}%",
                            titleStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                            color: colorCodes[users.indexOf(e)]))
                        .toList(),
                    sectionsSpace: 0,
                    centerSpaceRadius: 0),
              ),
            ),
          ),
        ],
      )),
    );
  }
}

class UserFailurePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("User failure page"),
    );
  }
}
