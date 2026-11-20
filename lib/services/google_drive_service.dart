import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static final GoogleDriveService _i = GoogleDriveService._();
  factory GoogleDriveService() => _i;
  GoogleDriveService._();

  // serverClientId diambil dari BuildConfig Android (via google-services.json)
  // Format: xxx.apps.googleusercontent.com
  static const MethodChannel _channel = MethodChannel('com.yusup28.note_app/google_sign_in');
  
  String? _serverClientId;
  
  Future<String> _getServerClientId() async {
    if (_serverClientId != null) return _serverClientId!;
    // Prioritas 1: BuildConfig (dari local.properties)
    // Prioritas 2: Native (jika ada)
    try {
      final String clientId = await _channel.invokeMethod('getServerClientId');
      if (clientId.isNotEmpty && clientId != 'YOUR_SERVER_CLIENT_ID.apps.googleusercontent.com') {
        _serverClientId = clientId;
        return _serverClientId!;
      }
    } catch (e) {
      debugPrint('Gagal ambil serverClientId dari native: $e');
    }
    // Fallback
    _serverClientId = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '562065299584-u7o0k643oirgf25ehgf9i0p2tvgnd41.apps.googleusercontent.com',
    );
    return _serverClientId!;
  }

  /// google_sign_in 7.x: [GoogleSignIn.instance] adalah singleton dan
  /// `initialize()` wajib dipanggil tepat sekali sebelum method lain dipakai.
  Future<void>? _initializeFuture;

  Future<void> _ensureInitialized() {
    return _initializeFuture ??= () async {
      final clientId = await _getServerClientId();
      await GoogleSignIn.instance.initialize(serverClientId: clientId);
    }();
  }

  /// Scope Drive yang diminta saat otorisasi client.
  List<String> get _driveScopes => [drive.DriveApi.driveAppdataScope];

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  /// Login Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      await _ensureInitialized();
      try {
        final account = await GoogleSignIn.instance.authenticate(
          scopeHint: _driveScopes,
        );
        _currentUser = account;
        debugPrint('Google signIn OK: ${account.email}');
        return account;
      } on GoogleSignInException catch (e) {
        if (e.code != GoogleSignInExceptionCode.canceled) rethrow;
        debugPrint('Google signIn dibatalkan pengguna, coba silent');
      }
      // v7: pembatalan oleh pengguna melempar exception, jadi fallback ke
      // lightweight authentication di sini.
      final silent = await _tryLightweightSignIn();
      if (silent != null) {
        debugPrint('Google signIn OK (silent fallback): ${silent.email}');
      }
      return silent;
    } catch (e, st) {
      debugPrint('Google signIn error: $e\n$st');
      rethrow;
    }
  }

  /// Logout
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
      _currentUser = null;
      debugPrint('Google signOut OK');
    } catch (e) {
      debugPrint('Google signOut error: $e');
    }
  }

  /// Auto login kalau sudah pernah
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      await _ensureInitialized();
      final account = await _tryLightweightSignIn();
      if (account != null) {
        debugPrint('Google silent signIn OK: ${account.email}');
      }
      return account;
    } catch (e) {
      debugPrint('silent signIn error: $e');
      return null;
    }
  }

  /// v7: `attemptLightweightAuthentication()` bisa mengembalikan `null`
  /// (bukan Future) bila platform tidak mendukung silent sign-in.
  Future<GoogleSignInAccount?> _tryLightweightSignIn() async {
    final future = GoogleSignIn.instance.attemptLightweightAuthentication();
    final account = future == null ? null : await future;
    if (account != null) _currentUser = account;
    return account;
  }

  /// Auth client
  Future<drive.DriveApi> _getDriveApi() async {
    final account = _currentUser ?? await signIn();
    if (account == null) throw Exception('Belum login Google');

    // v7: account.authentication hanya menyediakan idToken. Access token
    // untuk scope Drive diambil lewat authorizationClient.
    final authClient = account.authorizationClient;
    var auth = await authClient.authorizationForScopes(_driveScopes);
    auth ??= await authClient.authorizeScopes(_driveScopes);

    final client = _AuthenticatedClient(
      http.Client(),
      auth.accessToken,
    );
    return drive.DriveApi(client);
  }

  /// Upload file backup ZIP ke Drive (appDataFolder)
  Future<String?> uploadBackup({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final api = await _getDriveApi();

      // Cari file existing
      final list = await api.files.list(
        spaces: 'appDataFolder',
        q: "name='$fileName'",
      );

      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'application/zip',
      );

      final metadata = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder'];

      if (list.files != null && list.files!.isNotEmpty) {
        // Update existing
        final id = list.files!.first.id!;
        final updated =
            await api.files.update(metadata, id, uploadMedia: media);
        debugPrint('Backup updated: ${updated.id}');
        return updated.id;
      } else {
        // Create new
        final created = await api.files.create(metadata, uploadMedia: media);
        debugPrint('Backup created: ${created.id}');
        return created.id;
      }
    } catch (e) {
      debugPrint('uploadBackup error: $e');
      rethrow;
    }
  }

  /// Download file backup dari Drive
  Future<Uint8List?> downloadBackup({required String fileName}) async {
    try {
      final api = await _getDriveApi();

      final list = await api.files.list(
        spaces: 'appDataFolder',
        q: "name='$fileName'",
      );

      if (list.files == null || list.files!.isEmpty) {
        debugPrint('Backup tidak ditemukan');
        return null;
      }

      final fileId = list.files!.first.id!;
      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final chunks = <int>[];
      await for (final chunk in media.stream) {
        chunks.addAll(chunk);
      }
      final bytes = Uint8List.fromList(chunks);
      debugPrint('Download OK: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      debugPrint('downloadBackup error: $e');
      rethrow;
    }
  }

  /// Hapus backup lama, sisakan [keepLast] terbaru.
  Future<int> cleanupOldBackups({int keepLast = 5}) async {
    try {
      final api = await _getDriveApi();
      final list = await api.files.list(
        spaces: 'appDataFolder',
        q: "name contains 'note_app_backup_'",
        orderBy: 'createdTime desc',
      );

      final files = list.files ?? [];
      if (files.length <= keepLast) {
        debugPrint('Cleanup: hanya ${files.length} backup, skip');
        return 0;
      }

      final toDelete = files.skip(keepLast).toList();
      int count = 0;
      for (final f in toDelete) {
        if (f.id != null) {
          try {
            await api.files.delete(f.id!);
            count++;
          } catch (e) {
            debugPrint('Delete ${f.name} gagal: $e');
          }
        }
      }
      debugPrint('Cleanup: $count backup lama dihapus');
      return count;
    } catch (e) {
      debugPrint('cleanupOldBackups error: $e');
      return 0;
    }
  }

  /// List semua backup
  Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      final api = await _getDriveApi();
      final list = await api.files.list(
        spaces: 'appDataFolder',
      );
      return (list.files ?? [])
          .map((f) => {
                'id': f.id,
                'name': f.name,
                'modified': f.modifiedTime?.toIso8601String(),
                'size': f.size,
              })
          .toList();
    } catch (e) {
      debugPrint('listBackups error: $e');
      return [];
    }
  }

  /// Hapus backup
  Future<void> deleteBackup(String fileId) async {
    try {
      final api = await _getDriveApi();
      await api.files.delete(fileId);
      debugPrint('Deleted: $fileId');
    } catch (e) {
      debugPrint('deleteBackup error: $e');
      rethrow;
    }
  }
}

/// HTTP client yang inject auth header
class _AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final String _token;

  _AuthenticatedClient(this._inner, this._token);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }
}
