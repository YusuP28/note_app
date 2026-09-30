import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'dart:io' show HttpClient, SecurityContext;


class GoogleDriveService {
  static final GoogleDriveService _i = GoogleDriveService._();
  factory GoogleDriveService() => _i;
  GoogleDriveService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope, // appDataFolder (tersembunyi)
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  /// Login Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        _currentUser = account;
        debugPrint('Google signIn OK: ${account.email}');
      }
      return account;
    } catch (e) {
      debugPrint('Google signIn error: $e');
      rethrow;
    }
  }

  /// Logout
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      debugPrint('Google signOut OK');
    } catch (e) {
      debugPrint('Google signOut error: $e');
    }
  }

  /// Auto login kalau sudah pernah
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) _currentUser = account;
      return account;
    } catch (e) {
      debugPrint('silent signIn error: $e');
      return null;
    }
  }

  /// Auth client
  Future<drive.DriveApi> _getDriveApi() async {
    final account = _currentUser ?? await signIn();
    if (account == null) throw Exception('Belum login Google');

    final auth = await account.authentication;
    final client = _AuthenticatedClient(
      http.Client(),
      auth.accessToken ?? '',
    );
    return drive.DriveApi(client);
  }

  /// Upload file JSON ke Drive (appDataFolder)
  Future<String?> uploadBackup({
    required String fileName,
    required String jsonContent,
  }) async {
    try {
      final api = await _getDriveApi();

      // Cari file existing
      final list = await api.files.list(
        spaces: 'appDataFolder',
        q: "name='$fileName'",
        $fields: 'files(id, name)',
      );

      final bytes = utf8.encode(jsonContent);
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'application/json',
      );

      final metadata = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder'];

      if (list.files != null && list.files!.isNotEmpty) {
        // Update existing
        final id = list.files!.first.id!;
        final updated = await api.files.update(metadata, id, uploadMedia: media);
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

  /// Download file JSON dari Drive
  Future<String?> downloadBackup({required String fileName}) async {
    try {
      final api = await _getDriveApi();

      final list = await api.files.list(
        spaces: 'appDataFolder',
        q: "name='$fileName'",
        $fields: 'files(id, name, modifiedTime)',
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
      final content = utf8.decode(chunks);
      debugPrint('Download OK: ${content.length} char');
      return content;
    } catch (e) {
      debugPrint('downloadBackup error: $e');
      rethrow;
    }
  }

  /// List semua backup
  Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      final api = await _getDriveApi();
      final list = await api.files.list(
        spaces: 'appDataFolder',
        $fields: 'files(id, name, modifiedTime, size)',
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
