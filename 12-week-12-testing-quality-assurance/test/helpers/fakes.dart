import 'dart:async';

import 'package:campus_notification/core/failures.dart';
import 'package:campus_notification/features/ai/domain/entities/ai_message.dart';
import 'package:campus_notification/features/ai/domain/repositories/ai_repository.dart';
import 'package:campus_notification/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notification/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notification/features/auth/data/datasources/token_store.dart';
import 'package:campus_notification/features/auth/domain/entities/auth_user.dart';
import 'package:campus_notification/features/auth/domain/repositories/auth_repository.dart';

/// Fake repository pengumuman.
///
/// Seluruh perilaku (data, kondisi kosong, kegagalan, exception) dikendalikan
/// dari pengujian sehingga unit test dan widget test tidak membutuhkan
/// koneksi jaringan maupun server sungguhan.
class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({
    this.items = const <Announcement>[],
    this.failure,
    this.throwException = false,
    this.delay = Duration.zero,
  });

  /// Data yang dikembalikan pada skenario sukses.
  final List<Announcement> items;

  /// Failure yang dikembalikan pada skenario gagal.
  final Failure? failure;

  /// Bila true, repository melempar exception (bukan mengembalikan Failure).
  final bool throwException;

  /// Jeda buatan untuk menguji indikator loading.
  final Duration delay;

  int getListCallCount = 0;
  int getByIdCallCount = 0;
  String? lastRequestedId;

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  getAnnouncements() async {
    getListCallCount++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (throwException) {
      throw Exception('Koneksi ke server terputus');
    }
    if (failure != null) {
      return (announcements: const <Announcement>[], failure: failure);
    }
    return (announcements: items, failure: null);
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    getByIdCallCount++;
    lastRequestedId = id;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (throwException) {
      throw Exception('Koneksi ke server terputus');
    }
    if (failure != null) {
      return (announcement: null, failure: failure);
    }
    for (final item in items) {
      if (item.id == id) {
        return (announcement: item, failure: null);
      }
    }
    return (
      announcement: null,
      failure: NotFoundFailure('Pengumuman dengan ID $id tidak ditemukan'),
    );
  }
}

/// Fake penyimpanan token berbasis memori (tanpa FlutterSecureStorage asli).
class FakeTokenStore extends TokenStore {
  FakeTokenStore({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;

  int saveCallCount = 0;
  int clearCallCount = 0;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    saveCallCount++;
    accessToken = accessToken;
    refreshToken = refreshToken;
  }

  @override
  Future<String?> readAccess() async => accessToken;

  @override
  Future<String?> readRefresh() async => refreshToken;

  @override
  Future<void> clear() async {
    clearCallCount++;
    accessToken = null;
    refreshToken = null;
  }
}

/// Fake repository autentikasi yang mencatat setiap pemanggilan.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.loginFailure,
    this.loginUser = const AuthUser(
      email: 'mahasiswa@kampus.ac.id',
      accessToken: 'fake_access_token',
    ),
    bool initialLoggedIn = false,
    this.loginGate,
  }) : _isLoggedIn = initialLoggedIn;

  final Failure? loginFailure;
  final AuthUser loginUser;
  final Future<void>? loginGate;

  bool _isLoggedIn;

  int loginCallCount = 0;
  int logoutCallCount = 0;
  int sessionCheckCallCount = 0;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<({AuthUser? user, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    loginCallCount++;
    lastEmail = email;
    lastPassword = password;

    if (loginGate != null) await loginGate;

    if (loginFailure != null) {
      return (user: null, failure: loginFailure);
    }
    _isLoggedIn = true;
    return (user: loginUser, failure: null);
  }

  @override
  Future<({bool success, Failure? failure})> logout() async {
    logoutCallCount++;
    _isLoggedIn = false;
    return (success: true, failure: null);
  }

  @override
  Future<({bool isLoggedIn, Failure? failure})> isLoggedIn() async {
    sessionCheckCallCount++;
    return (isLoggedIn: _isLoggedIn, failure: null);
  }

  @override
  Future<({bool refreshed, Failure? failure})> refreshToken() async {
    _isLoggedIn = true;
    return (refreshed: true, failure: null);
  }
}

/// Fake repository AI dengan respons dan kegagalan yang dapat diatur.
class FakeAIRepository implements AIRepository {
  FakeAIRepository({
    this.responseText = 'Jawaban simulasi dari AI.',
    this.failure,
    this.gate,
  });

  final String responseText;
  final Failure? failure;

  /// Completer untuk menahan respons agar state loading dapat diuji.
  final Completer<void>? gate;

  int sendPromptCallCount = 0;
  String? lastPrompt;

  @override
  Future<AIMessage> sendPrompt(String prompt) async {
    sendPromptCallCount++;
    lastPrompt = prompt;

    if (gate != null) await gate!.future;
    if (failure != null) throw failure!;

    return AIMessage(
      id: 'fake-ai-message',
      text: responseText,
      isUser: false,
      timestamp: DateTime(2026, 11, 18, 10, 30),
    );
  }
}
