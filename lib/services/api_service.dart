// // lib/services/api_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// /// Goldfish API client (без records, совместим с Dart 2.x).
// class ApiService {
//   /// Проверь, что совпадает с сервером в Swagger (Servers dropdown).
//   static const String _base = 'https://goldfish-app-3lf7u.ondigitalocean.app';

//   Map<String, String> _headers({String? token}) => {
//         'Content-Type': 'application/json',
//         if (token != null) 'Authorization': 'Bearer $token',
//       };

//   // ========================= AUTH =========================

//   /// GET /api/v1/auth/apple/generate-account
//   /// Возвращает Bearer-токен как строку.
//   Future<String> generateAccountToken() async {
//     final uri = Uri.parse('$_base/api/v1/auth/apple/generate-account');
//     final res = await http.get(uri, headers: _headers());
//     if (res.statusCode < 200 || res.statusCode >= 300) {
//       throw Exception(
//           'generate-account failed: ${res.statusCode}; body=${res.body}');
//     }

//     final body = res.body.trim();
//     Map<String, dynamic>? map;
//     try {
//       map = json.decode(body) as Map<String, dynamic>;
//     } catch (_) {}

//     final token =
//         _extractTokenDeep(map) ?? _extractTokenFromHeaders(res.headers) ?? body;

//     if (token.isEmpty) {
//       throw Exception(
//           'Missing token; bodySample=${body.substring(0, body.length.clamp(0, 300))}');
//     }
//     return token;
//   }

//   /// POST /api/v1/mobile-user/auth/refresh-token
//   Future<String> refreshToken({required String authToken}) async {
//     final uri = Uri.parse('$_base/api/v1/mobile-user/auth/refresh-token');
//     final res = await http.post(uri, headers: _headers(token: authToken));
//     if (res.statusCode < 200 || res.statusCode >= 300) {
//       throw Exception(
//           'refresh-token failed: ${res.statusCode}; body=${res.body}');
//     }

//     final body = res.body.trim();
//     Map<String, dynamic>? map;
//     try {
//       map = json.decode(body) as Map<String, dynamic>;
//     } catch (_) {}

//     final fresh =
//         _extractTokenDeep(map) ?? _extractTokenFromHeaders(res.headers) ?? body;

//     if (fresh.isEmpty) {
//       throw Exception(
//           'refresh-token: Missing token; sample=${body.substring(0, body.length.clamp(0, 300))}');
//     }
//     return fresh;
//   }

//   // =================== BRAINTREE CLIENT TOKEN ===================

//   /// Результат для client token + возможно обновлённый Bearer.

//   /// GET /api/v1/payments/generate-and-save-braintree-client-token
//   /// С авто-ретраем при 401 (expired): refresh -> повторить.
//   Future<ClientTokenResult> getClientTokenWithRefresh(String authToken) async {
//     final uri = Uri.parse(
//         '$_base/api/v1/payments/generate-and-save-braintree-client-token');

//     Future<String> doGet(String bearer) async {
//       final res = await http.get(uri, headers: _headers(token: bearer));
//       if (res.statusCode == 401) throw _AuthExpired();
//       if (res.statusCode < 200 || res.statusCode >= 300) {
//         throw Exception(
//           'generate-and-save-braintree-client-token failed: ${res.statusCode}; body=${res.body}',
//         );
//       }
//       return _parseClientToken(res.body);
//     }

//     try {
//       final ct = await doGet(authToken);
//       return ClientTokenResult(ct, null);
//     } on _AuthExpired {
//       final fresh = await refreshToken(authToken: authToken);
//       final ct = await doGet(fresh);
//       return ClientTokenResult(ct, fresh);
//     }
//   }

//   /// Если не нужен свежий Bearer — можно вызвать это.
//   Future<String> generateBraintreeClientToken(
//       {required String authToken}) async {
//     final r = await getClientTokenWithRefresh(authToken);
//     return r.clientToken;
//   }

//   String _parseClientToken(String body) {
//     final text = body.trim();
//     try {
//       final map = json.decode(text) as Map<String, dynamic>;
//       final direct = (map['clientToken'] ?? map['token'])?.toString();
//       if (direct != null && direct.isNotEmpty) return direct;

//       for (final k in ['data', 'result', 'payload']) {
//         final sub = map[k];
//         if (sub is Map<String, dynamic>) {
//           final t = (sub['clientToken'] ?? sub['token'])?.toString();
//           if (t != null && t.isNotEmpty) return t;
//         }
//       }
//     } catch (_) {
//       if (text.isNotEmpty && !text.startsWith('{')) return text; // сырой токен
//     }
//     throw Exception(
//       'missing clientToken in response: ${text.substring(0, text.length.clamp(0, 300))}',
//     );
//   }

//   // =================== PAYMENT PIPELINE ===================

//  Future<String> addPaymentMethod({
//   required String authToken,
//   required String paymentNonce,        // nonce из Drop-In/ApplePay
//   required String paymentType,         // "CARD" | "APPLE_PAY"
//   String description = 'DropIn payment',
// }) async {
//   final uri = Uri.parse('$_base/api/v1/payments/add-payment-method');

//   final res = await http.post(
//     uri,
//     headers: _headers(token: authToken),
//     body: json.encode({
//       'paymentNonceFromTheClient': paymentNonce,
//       'paymentType': paymentType,
//       'description': description,
//     }),
//   );

//   if (res.statusCode < 200 || res.statusCode >= 300) {
//     throw Exception('add-payment-method failed: ${res.statusCode}; body=${res.body}');
//   }

//   final map = json.decode(res.body) as Map<String, dynamic>;
//   final paymentToken = (map['paymentToken'] ?? map['token'] ?? '').toString();
//   if (paymentToken.isEmpty) {
//     throw Exception('add-payment-method: empty paymentToken; body=${res.body}');
//   }
//   return paymentToken;
// }

//   /// POST /api/v1/payments/subscription/create-subscription-transaction-v2?...
//   Future<void> createSubscriptionTransaction({
//     required String authToken,
//     required bool disableWelcomeDiscount,
//     required int welcomeDiscount,
//     required String paymentToken,
//     String planId = 'tss2',
//   }) async {
//     final uri = Uri.parse(
//       '$_base/api/v1/payments/subscription/create-subscription-transaction-v2'
//       '?disableWelcomeDiscount=$disableWelcomeDiscount'
//       '&welcomeDiscount=$welcomeDiscount',
//     );
//     final res = await http.post(
//       uri,
//       headers: _headers(token: authToken),
//       body: json.encode({'paymentToken': paymentToken, 'thePlanId': planId}),
//     );
//     if (res.statusCode < 200 || res.statusCode >= 300) {
//       throw Exception(
//         'create-subscription-transaction-v2 failed: ${res.statusCode}; body=${res.body}',
//       );
//     }
//   }

//   /// POST /api/v1/payments/rent-power-bank
//   Future<void> rentPowerBank({
//     required String authToken,
//     required String stationId,
//   }) async {
//     final uri = Uri.parse('$_base/api/v1/payments/rent-power-bank');
//     final res = await http.post(
//       uri,
//       headers: _headers(token: authToken),
//       body: json.encode({'stationId': stationId}),
//     );
//     if (res.statusCode < 200 || res.statusCode >= 300) {
//       throw Exception(
//           'rent-power-bank failed: ${res.statusCode}; body=${res.body}');
//     }
//   }

//   // =================== UTIL ===================

//   String? _extractTokenFromHeaders(Map<String, String> h) {
//     final auth = h['authorization'] ?? h['Authorization'];
//     if (auth != null && auth.isNotEmpty) {
//       final parts = auth.split(' ');
//       if (parts.length == 2) return parts.last;
//     }
//     final setCookie = h['set-cookie'] ?? h['Set-Cookie'];
//     if (setCookie != null) {
//       final m = RegExp(r'(token|Authorization)=([^;]+)').firstMatch(setCookie);
//       if (m != null) {
//         final v = m.group(2)!;
//         return v.replaceFirst(RegExp(r'^Bearer\s+'), '');
//       }
//     }
//     return null;
//   }

//   String? _extractTokenDeep(Map<String, dynamic>? m) {
//     if (m == null) return null;
//     const keys = [
//       'token',
//       'accessToken',
//       'authToken',
//       'jwt',
//       'idToken',
//       'bearer'
//     ];
//     for (final k in keys) {
//       final v = m[k];
//       if (v is String && v.isNotEmpty) return v;
//     }
//     for (final k in ['data', 'result', 'payload', 'account', 'user']) {
//       final v = m[k];
//       if (v is Map<String, dynamic>) {
//         final t = _extractTokenDeep(v);
//         if (t != null) return t;
//       }
//     }
//     // последний шанс — что-то похожее на JWT
//     if (m.isNotEmpty) {
//       for (final entry in m.entries) {
//         final v = entry.value;
//         if (v is String &&
//             RegExp(r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$')
//                 .hasMatch(v)) {
//           return v;
//         }
//       }
//     }
//     return null;
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Goldfish API client (Dart 2.x совместим).
class ApiService {
  static const String _base = 'https://goldfish-app-3lf7u.ondigitalocean.app';

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // =============== AUTH ===============
  Future<String> generateAccountToken() async {
    final uri = Uri.parse('$_base/api/v1/auth/apple/generate-account');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'generate-account failed: ${res.statusCode}; body=${res.body}');
    }
    final body = res.body.trim();
    Map<String, dynamic>? map;
    try {
      map = json.decode(body) as Map<String, dynamic>;
    } catch (_) {}
    final token =
        _extractTokenDeep(map) ?? _extractTokenFromHeaders(res.headers) ?? body;
    if (token.isEmpty) {
      throw Exception(
          'Missing token; sample=${body.substring(0, body.length.clamp(0, 300))}');
    }
    return token;
  }

  Future<String> refreshToken({required String authToken}) async {
    final uri = Uri.parse('$_base/api/v1/mobile-user/auth/refresh-token');
    final res = await http.post(uri, headers: _headers(token: authToken));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'refresh-token failed: ${res.statusCode}; body=${res.body}');
    }
    final body = res.body.trim();
    Map<String, dynamic>? map;
    try {
      map = json.decode(body) as Map<String, dynamic>;
    } catch (_) {}
    final fresh =
        _extractTokenDeep(map) ?? _extractTokenFromHeaders(res.headers) ?? body;
    if (fresh.isEmpty) {
      throw Exception(
          'refresh-token: Missing token; sample=${body.substring(0, body.length.clamp(0, 300))}');
    }
    return fresh;
  }

  // ========== BRAINTREE CLIENT TOKEN ==========

  Future<ClientTokenResult> getClientTokenWithRefresh(String authToken) async {
    final uri = Uri.parse(
        '$_base/api/v1/payments/generate-and-save-braintree-client-token');

    Future<String> doGet(String bearer) async {
      final res = await http.get(uri, headers: _headers(token: bearer));
      if (res.statusCode == 401) throw _AuthExpired();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception(
          'generate-and-save-braintree-client-token failed: ${res.statusCode}; body=${res.body}',
        );
      }
      return _parseClientToken(res.body);
    }

    try {
      final ct = await doGet(authToken);
      return ClientTokenResult(ct, null);
    } on _AuthExpired {
      final fresh = await refreshToken(authToken: authToken);
      final ct = await doGet(fresh);
      return ClientTokenResult(ct, fresh);
    }
  }

  Future<String> generateBraintreeClientToken(
      {required String authToken}) async {
    final r = await getClientTokenWithRefresh(authToken);
    return r.clientToken;
  }

  String _parseClientToken(String body) {
    final text = body.trim();
    try {
      final map = json.decode(text) as Map<String, dynamic>;
      final direct = (map['clientToken'] ?? map['token'])?.toString();
      if (direct != null && direct.isNotEmpty) return direct;
      for (final k in ['data', 'result', 'payload']) {
        final sub = map[k];
        if (sub is Map<String, dynamic>) {
          final t = (sub['clientToken'] ?? sub['token'])?.toString();
          if (t != null && t.isNotEmpty) return t;
        }
      }
    } catch (_) {
      if (text.isNotEmpty && !text.startsWith('{')) return text;
    }
    throw Exception(
        'missing clientToken in response: ${text.substring(0, text.length.clamp(0, 300))}');
  }

  // =============== PAYMENT PIPELINE ===============
  Future<String> addPaymentMethod({
    required String authToken,
    required String paymentNonce,
    required String paymentType, // "CARD" | "APPLE_PAY"
    String description = 'Drop-In payment',
  }) async {
    final uri = Uri.parse('$_base/api/v1/payments/add-payment-method');
    final res = await http.post(
      uri,
      headers: _headers(token: authToken),
      body: json.encode({
        'paymentNonceFromTheClient': paymentNonce,
        'paymentType': paymentType,
        'description': description,
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'add-payment-method failed: ${res.statusCode}; body=${res.body}');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    final paymentToken = (map['paymentToken'] ?? map['token'] ?? '').toString();
    if (paymentToken.isEmpty) {
      throw Exception(
          'add-payment-method: empty paymentToken; body=${res.body}');
    }
    return paymentToken;
  }

  Future<void> createSubscriptionTransaction({
    required String authToken,
    required bool disableWelcomeDiscount,
    required int welcomeDiscount,
    required String paymentToken,
    String planId = 'tss2',
  }) async {
    final uri = Uri.parse(
      '$_base/api/v1/payments/subscription/create-subscription-transaction-v2'
      '?disableWelcomeDiscount=$disableWelcomeDiscount'
      '&welcomeDiscount=$welcomeDiscount',
    );
    final res = await http.post(
      uri,
      headers: _headers(token: authToken),
      body: json.encode({'paymentToken': paymentToken, 'thePlanId': planId}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'create-subscription-transaction-v2 failed: ${res.statusCode}; body=${res.body}');
    }
  }

  Future<void> rentPowerBank({
    required String authToken,
    required String stationId,
  }) async {
    final uri = Uri.parse('$_base/api/v1/payments/rent-power-bank');
    final res = await http.post(
      uri,
      headers: _headers(token: authToken),
      body: json.encode({'stationId': stationId}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'rent-power-bank failed: ${res.statusCode}; body=${res.body}');
    }
  }

  // =============== HELPERS ===============
  String? _extractTokenFromHeaders(Map<String, String> h) {
    final auth = h['authorization'] ?? h['Authorization'];
    if (auth != null && auth.isNotEmpty) {
      final parts = auth.split(' ');
      if (parts.length == 2) return parts.last;
    }
    final setCookie = h['set-cookie'] ?? h['Set-Cookie'];
    if (setCookie != null) {
      final m = RegExp(r'(token|Authorization)=([^;]+)').firstMatch(setCookie);
      if (m != null) {
        final v = m.group(2)!;
        return v.replaceFirst(RegExp(r'^Bearer\s+'), '');
      }
    }
    return null;
  }

  String? _extractTokenDeep(Map<String, dynamic>? m) {
    if (m == null) return null;
    const keys = [
      'token',
      'accessToken',
      'authToken',
      'jwt',
      'idToken',
      'bearer'
    ];
    for (final k in keys) {
      final v = m[k];
      if (v is String && v.isNotEmpty) return v;
    }
    for (final k in ['data', 'result', 'payload', 'account', 'user']) {
      final v = m[k];
      if (v is Map<String, dynamic>) {
        final t = _extractTokenDeep(v);
        if (t != null) return t;
      }
    }
    if (m.isNotEmpty) {
      for (final entry in m.entries) {
        final v = entry.value;
        if (v is String &&
            RegExp(r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$')
                .hasMatch(v)) {
          return v;
        }
      }
    }
    return null;
  }
}

class _AuthExpired implements Exception {}

class ClientTokenResult {
  final String clientToken;
  final String? freshBearer;
  const ClientTokenResult(this.clientToken, this.freshBearer);
}
