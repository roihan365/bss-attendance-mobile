import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class IAuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Future<UserModel> getUserProfile();
}

class AuthRemoteDataSource implements IAuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSource({required this.dioClient});

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await dioClient.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );

    if (apiResponse.data == null) {
      throw Exception(apiResponse.formattedErrorMessage);
    }

    return apiResponse.data!;
  }

  @override
  Future<void> logout() async {
    await dioClient.post('/auth/logout');
  }

  @override
  Future<UserModel> getUserProfile() async {
    final response = await dioClient.get('/user');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
