import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  static const _userKey = 'logged_in_user';
  static const _biometricEnabledKey = 'biometric_enabled';

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<AppUser?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return AppUser.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? true;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to unlock PanicButton',
        biometricOnly: false,
      );
    } on PlatformException {
      return false;
    }
  }

  /// Authenticates either the default User, default Member, or any added FamilyMember.
  Future<AppUser?> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Default User account
    if (normalizedEmail == 'user@panicbutton.app' && password == '123456') {
      const user = AppUser(
        id: 'default_user',
        name: 'Primary User',
        email: 'user@panicbutton.app',
        role: UserRole.user,
      );
      await saveUser(user);
      return user;
    }

    // Default Member account
    if (normalizedEmail == 'member@panicbutton.app' && password == '123456') {
      const member = AppUser(
        id: 'default_member',
        name: 'Family Member',
        email: 'member@panicbutton.app',
        role: UserRole.member,
      );
      await saveUser(member);
      return member;
    }

    // Check added family members in local SQLite database
    final member = await DatabaseService.instance.findMemberByCredentials(
      normalizedEmail,
      password,
    );
    if (member != null) {
      final appUser = AppUser(
        id: member.id,
        name: member.name,
        email: member.email,
        role: UserRole.member,
        phone: member.phone,
      );
      await saveUser(appUser);
      return appUser;
    }

    return null;
  }
}
