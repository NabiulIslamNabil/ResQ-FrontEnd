import 'dart:convert';

class User {
  final String? id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? role;  // Ensure role is present
  final bool? isActive;
  final String? dateJoined;

  User({
    this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.role,
    this.isActive,
    this.dateJoined,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    } else {
      return username ?? 'User';
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      role: json['role'],  // Parse role from JSON
      isActive: json['is_active'],
      dateJoined: json['date_joined'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'role': role,  // Include role in JSON
      'is_active': isActive,
      'date_joined': dateJoined,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
