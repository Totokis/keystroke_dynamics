import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import '../user.dart';

part 'pylogger_event.dart';
part 'pylogger_state.dart';

class PyloggerBloc extends Bloc<PyloggerEvent, PyloggerState> {
  PyloggerBloc({required this.httpClient}) : super(const PyloggerState()) {
    on<PyloggerRecognizeStarted>(_onRecognizeStarted);
    on<PyloggerIncrementSeconds>(_onIncrement);
    on<PyloggerDecrementSeconds>(_onDecrement);
  }
  final Client httpClient;
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  Future<void> _onRecognizeStarted(
      PyloggerRecognizeStarted event, Emitter<PyloggerState> emit) async {
    emit(state.copyWith(status: PyloggerStatus.type, users: List.empty()));

    final username =
        await await httpClient.get(Uri.http("localhost:5000", "/username"));

    emit(state.copyWith(
        status: PyloggerStatus.type,
        users: List.empty(),
        userName: username.body.toString()));

    final response = await httpClient
        .get(Uri.http("localhost:5000", "/run/${state.seconds}"));

    final body = jsonDecode(response.body) as List<dynamic>;

    final users = body.map((dynamic json) {
      final map = json as Map<String, dynamic>;
      return User(name: map["name"], percentage: map["percentage"]);
    }).toList();

    users.sort((a, b) => a.percentage.compareTo(b.percentage));

    emit(state.copyWith(
        status: PyloggerStatus.user_sucess, users: users.reversed.toList()));
  }

  FutureOr<void> _onIncrement(
      PyloggerIncrementSeconds event, Emitter<PyloggerState> emit) {
    emit(state.copyWith(seconds: state.seconds + 10));
  }

  FutureOr<void> _onDecrement(
      PyloggerDecrementSeconds event, Emitter<PyloggerState> emit) {
    emit(state.copyWith(seconds: state.seconds - 10));
  }
}
