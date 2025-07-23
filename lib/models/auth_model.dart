import 'user_model.dart';

class AuthModel {
  final String? accessToken;
  final String? refreshToken;
  final User? user;

  AuthModel({this.accessToken, this.refreshToken, this.user});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      accessToken: json['access'],
      refreshToken: json['refresh'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access': accessToken,
      'refresh': refreshToken,
      'user': user?.toJson(),
    };
  }
}
