part of 'pylogger_bloc.dart';

enum PyloggerStatus { initial, type, user_sucess, user_failure }

class PyloggerState extends Equatable {
  final PyloggerStatus status;
  final int seconds;
  final List<User> users;
  final String userName;

  const PyloggerState(
      {this.seconds = 10,
      this.status = PyloggerStatus.initial,
      this.users = const <User>[],
      this.userName = ''});

  PyloggerState copyWith({
    PyloggerStatus? status,
    List<User>? users,
    int? seconds,
    String? userName,
  }) {
    return PyloggerState(
        status: status ?? this.status,
        users: users ?? this.users,
        seconds: seconds ?? this.seconds,
        userName: userName ?? this.userName);
  }

  @override
  List<Object?> get props => [status, users, seconds, userName];
}
