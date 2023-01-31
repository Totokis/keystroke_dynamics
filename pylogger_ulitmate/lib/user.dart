import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String name;
  final double percentage;

  User({required this.name, required this.percentage});

  @override
  String toString() {
    return name;
  }

  @override
  List<Object?> get props => [name, percentage];
}
