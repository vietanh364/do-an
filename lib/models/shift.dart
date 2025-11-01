import 'package:intl/intl.dart';

class Shift {
  int? shiftId;
  int userId;
  DateTime startTime;
  DateTime? endTime;
  double totalRevenue;
  int totalOrders;
  String? notes;

  Shift({
    this.shiftId,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.totalRevenue = 0.0,
    this.totalOrders = 0,
    this.notes,
  });

  factory Shift.fromMap(Map<String, dynamic> map) {
    try {
      return Shift(
        shiftId: map['id'],
        userId: map['userId'],
        startTime: DateTime.parse(map['startTime']),
        endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
        totalRevenue: (map['totalRevenue'] is num)
            ? (map['totalRevenue'] as num).toDouble()
            : 0.0,
        totalOrders: map['totalOrders'] ?? 0,
        notes: map['notes'],
      );
    } catch (e) {
      print("Error creating Shift object from map: $e");
      print("Map data: $map");
      return Shift(userId: 0, startTime: DateTime.now());
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': shiftId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'notes': notes,
    };
  }

  String getFormattedStartTime() {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(startTime);
  }

  String? getFormattedEndTime() {
    return endTime != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(endTime!) : null;
  }
}
