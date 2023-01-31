part of 'pylogger_bloc.dart';

@immutable
abstract class PyloggerEvent {}

class PyloggerRecognizeStarted extends PyloggerEvent {}

class PyloggerRecognizeEnded extends PyloggerEvent {}

class PyloggerDecrementSeconds extends PyloggerEvent {}

class PyloggerIncrementSeconds extends PyloggerEvent {}
