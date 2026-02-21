import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../models/missing_person.dart';

class BackendApiService {
  static const String _apiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static Uri _endpoint(String path) => Uri.parse('$_apiBase/$path');

  static String _mediaUrl(String? rawValue) {
    final value = (rawValue ?? '').trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final baseUri = Uri.parse(_apiBase);
    final mediaPath = value.startsWith('/') ? value : '/$value';
    return '${baseUri.scheme}://${baseUri.host}:${baseUri.port}$mediaPath';
  }

  static UrgencyLevel _mapUrgency(String? urgency) {
    switch ((urgency ?? '').toLowerCase()) {
      case 'high':
        return UrgencyLevel.critical;
      case 'medium':
        return UrgencyLevel.high;
      default:
        return UrgencyLevel.normal;
    }
  }

  static String _mapUrgencyToApi(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.critical:
      case UrgencyLevel.high:
        return 'High';
      case UrgencyLevel.normal:
        return 'Low';
    }
  }

  static CaseStatus _mapStatus(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return CaseStatus.active;
      case 'solved':
        return CaseStatus.found;
      case 'rejected':
        return CaseStatus.archived;
      case 'pending':
      default:
        return CaseStatus.submitted;
    }
  }

  static MissingPerson _toMissingPerson(Map<String, dynamic> json) {
    final id = '${json['id'] ?? ''}';
    return MissingPerson(
      id: id,
      name: '${json['name'] ?? 'Unknown'}',
      age: (json['age'] as num?)?.toInt() ?? 0,
      photoUrl: _mediaUrl(json['photo'] as String?),
      lastSeenLocation: '${json['location'] ?? 'Unknown location'}',
      lastSeenTime:
          DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      distanceKm: 0,
      urgency: _mapUrgency(json['urgency'] as String?),
      isVerified:
          '${json['status'] ?? ''}'.toLowerCase() == 'active' ||
          '${json['status'] ?? ''}'.toLowerCase() == 'solved',
      description: '${json['description'] ?? ''}',
      height: 0,
      hairColor: 'Unknown',
      eyeColor: 'Unknown',
      clothing: 'Not specified',
      contactName: 'Not available',
      contactPhone: 'Not available',
      privacyLevel: PrivacyLevel.protected,
      status: _mapStatus(json['status'] as String?),
    );
  }

  static Future<List<MissingPerson>> fetchCases() async {
    final response = await http.get(_endpoint('cases'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch cases (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_toMissingPerson)
        .toList();
  }

  static Future<MissingPerson> createCase({
    required String name,
    required int age,
    required String location,
    required String description,
    required UrgencyLevel urgency,
    XFile? photo,
    int? userId,
  }) async {
    final request = http.MultipartRequest('POST', _endpoint('cases'))
      ..fields['name'] = name
      ..fields['age'] = age.toString()
      ..fields['location'] = location
      ..fields['description'] = description
      ..fields['reliability'] = '70'
      ..fields['urgency'] = _mapUrgencyToApi(urgency)
      ..fields['status'] = 'Pending';

    if (userId != null) {
      request.fields['userId'] = userId.toString();
    }

    if (photo != null) {
      final bytes = await photo.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('photo', bytes, filename: photo.name),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create case (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return _toMissingPerson(decoded);
  }

  static Future<void> submitTip({
    required int caseId,
    required String content,
    required bool isAnonymous,
    required bool shareLocation,
    XFile? attachment,
    String reporter = 'Anonymous',
    int? userId,
  }) async {
    final request = http.MultipartRequest('POST', _endpoint('tips'))
      ..fields['caseId'] = caseId.toString()
      ..fields['content'] = content
      ..fields['isAnonymous'] = isAnonymous.toString()
      ..fields['shareLocation'] = shareLocation.toString()
      ..fields['reporter'] = reporter;

    if (userId != null) {
      request.fields['userId'] = userId.toString();
    }

    if (attachment != null) {
      final bytes = await attachment.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'attachment',
          bytes,
          filename: attachment.name,
        ),
      );
    }

    final streamed = await request.send();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Failed to submit tip (${streamed.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final trimmed = usernameOrEmail.trim();
    final payload = <String, String>{'password': password};
    if (trimmed.contains('@')) {
      payload['email'] = trimmed;
    } else if (RegExp(r'^\d{7,15}$').hasMatch(trimmed)) {
      payload['phone'] = trimmed;
    } else {
      payload['username'] = trimmed;
    }

    final response = await http.post(
      _endpoint('auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractError(response, 'Login failed (${response.statusCode})'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {};
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    String? phone,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await http.post(
      _endpoint('auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractError(response, 'Signup failed (${response.statusCode})'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {};
  }

  static Future<Map<String, dynamic>> parseVoiceReport({
    required String text,
  }) async {
    final response = await http.post(
      _endpoint('voice/parse'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractError(response, 'Voice parse failed (${response.statusCode})'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {};
  }

  static Future<String> aiChat({required String text}) async {
    final response = await http.post(
      _endpoint('ai/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractError(response, 'AI chat failed (${response.statusCode})'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return (decoded['reply'] ?? '').toString();
    }
    return '';
  }

  static String _extractError(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail']?.toString().trim();
        if (detail != null && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {
      // Ignore parsing errors and use fallback.
    }
    return fallback;
  }

  static Future<List<Map<String, dynamic>>> fetchRewards() async {
    final response = await http.get(_endpoint('rewards'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch rewards (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchUserProfile({
    required int userId,
  }) async {
    final response = await http.get(_endpoint('users/$userId'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractError(response, 'Failed to fetch user profile (${response.statusCode})'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {};
  }

  static Future<List<Map<String, dynamic>>> fetchUserCoupons({
    required int userId,
  }) async {
    final response = await http.get(_endpoint('users/$userId/coupons'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractError(response, 'Failed to fetch coupons (${response.statusCode})'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchRewardRedemptions() async {
    final response = await http.get(_endpoint('rewards/redemptions'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch redemptions (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> redeemReward({
    required int rewardId,
    required int userId,
  }) async {
    final response = await http.post(
      _endpoint('rewards/$rewardId/redeem'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractError(response, 'Redeem failed (${response.statusCode})'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {};
  }
}
