import '../../../shared/data/network/api_client.dart';
import '../../../shared/data/network/result.dart';

class ProfileWebService {
  ProfileWebService(this._api);

  final ApiClient _api;

  static const String _profileBase = '/api/profiles/business';

  Future<Result<dynamic>> createBusinessProfile(Map<String, dynamic> body) =>
      _api.post(_profileBase, body: body);

  Future<Result<dynamic>> getBusinessProfile(String profileId) =>
      _api.get('$_profileBase/$profileId');

  Future<Result<dynamic>> updateBusinessProfile(Map<String, dynamic> body) =>
      _api.put(_profileBase, body: body);

  Future<Result<dynamic>> submitVerification(Map<String, dynamic> body) =>
      _api.post('/api/verification/submit', body: body);

  Future<Result<dynamic>> getUser(String userId) =>
      _api.get('/api/Users/$userId');
}
