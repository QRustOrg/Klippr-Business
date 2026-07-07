import '../../../shared/data/network/api_client.dart';
import '../../../shared/data/network/result.dart';

class AdminProfileWebService {
  AdminProfileWebService(this._api);

  final ApiClient _api;

  static const String _base = '/api/admin/profiles';

  Future<Result<dynamic>> getPendingVerifications({
    int pageNumber = 1,
    int pageSize = 10,
  }) =>
      _api.get(
        '$_base/pending-verification',
        query: {'pageNumber': pageNumber, 'pageSize': pageSize},
      );

  Future<Result<dynamic>> getProfileByUser(String userId) =>
      _api.get('$_base/by-user/$userId');

  Future<Result<dynamic>> approveVerification(String profileId) =>
      _api.post('/api/verification/approve', body: {'profileId': profileId});

  Future<Result<dynamic>> rejectVerification(String profileId) =>
      _api.post('/api/verification/reject', body: {'profileId': profileId});

  Future<Result<dynamic>> deactivateProfile(String profileId) =>
      _api.post('$_base/$profileId/deactivate');

  Future<Result<dynamic>> reactivateProfile(String profileId) =>
      _api.post('$_base/$profileId/reactivate');
}
