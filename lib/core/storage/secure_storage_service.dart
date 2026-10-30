import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorageService {
  Future<void> guardarTokens({
    required String tokenAcceso,
    required String tokenRenovacion,
    required DateTime tokenAccesoExpiraEn,
    required DateTime tokenRenovacionExpiraEn,
  });

  Future<String?> obtenerTokenAcceso();
  Future<String?> obtenerTokenRenovacion();
  Future<DateTime?> obtenerTokenAccesoExpiraEn();
  Future<DateTime?> obtenerTokenRenovacionExpiraEn();

  Future<void> limpiarSesion();
}

class FlutterSecureStorageService implements SecureStorageService {
  final FlutterSecureStorage _storage;

  static const _keyTokenAcceso = 'upt_token_acceso';
  static const _keyTokenRenovacion = 'upt_token_renovacion';
  static const _keyTokenAccesoExpiraEn = 'upt_token_acceso_expira_en';
  static const _keyTokenRenovacionExpiraEn = 'upt_token_renovacion_expira_en';

  FlutterSecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> guardarTokens({
    required String tokenAcceso,
    required String tokenRenovacion,
    required DateTime tokenAccesoExpiraEn,
    required DateTime tokenRenovacionExpiraEn,
  }) async {
    await _storage.write(key: _keyTokenAcceso, value: tokenAcceso);
    await _storage.write(key: _keyTokenRenovacion, value: tokenRenovacion);
    await _storage.write(
        key: _keyTokenAccesoExpiraEn,
        value: tokenAccesoExpiraEn.toIso8601String());
    await _storage.write(
        key: _keyTokenRenovacionExpiraEn,
        value: tokenRenovacionExpiraEn.toIso8601String());
  }

  @override
  Future<String?> obtenerTokenAcceso() async {
    return await _storage.read(key: _keyTokenAcceso);
  }

  @override
  Future<String?> obtenerTokenRenovacion() async {
    return await _storage.read(key: _keyTokenRenovacion);
  }

  @override
  Future<DateTime?> obtenerTokenAccesoExpiraEn() async {
    final raw = await _storage.read(key: _keyTokenAccesoExpiraEn);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<DateTime?> obtenerTokenRenovacionExpiraEn() async {
    final raw = await _storage.read(key: _keyTokenRenovacionExpiraEn);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> limpiarSesion() async {
    await _storage.delete(key: _keyTokenAcceso);
    await _storage.delete(key: _keyTokenRenovacion);
    await _storage.delete(key: _keyTokenAccesoExpiraEn);
    await _storage.delete(key: _keyTokenRenovacionExpiraEn);
  }
}
