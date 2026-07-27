class UserModel {
  final String uid;
  final String email;
  final String role;

  UserModel({required this.uid, required this.email, this.role = 'user'});

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(uid: uid, email: data['email'] ?? '', role: data['role'] ?? 'user');
  }
}