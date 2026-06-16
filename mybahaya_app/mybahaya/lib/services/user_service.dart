import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Model representing a user's profile from Firestore.
class UserProfile {
  final String uid;
  final String username;
  final String email;
  final String phone;
  final String? photoUrl;

  const UserProfile({
    required this.uid,
    required this.username,
    required this.email,
    required this.phone,
    this.photoUrl,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
    );
  }
}

/// Service for all user profile operations (Firestore + Storage).
class UserService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  /// Returns the currently signed-in user's UID, or null.
  static String? get currentUid => _auth.currentUser?.uid;

  /// Stream that emits the current user's profile whenever Firestore data
  /// changes. Errors are swallowed and emitted as null so the UI never hangs.
  static Stream<UserProfile?> profileStream() {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map<UserProfile?>((snap) =>
            snap.exists ? UserProfile.fromMap(uid, snap.data()!) : null)
        .handleError((_) => null); // Swallow permission errors gracefully
  }

  /// One-shot fetch of the current user's profile.
  /// Returns null on any error (including permission-denied).
  static Future<UserProfile?> fetchProfile() async {
    final uid = currentUid;
    if (uid == null) return null;
    try {
      final snap = await _firestore.collection('users').doc(uid).get();
      if (!snap.exists) return null;
      return UserProfile.fromMap(uid, snap.data()!);
    } catch (_) {
      // Silently handle permission-denied or network errors
      return null;
    }
  }

  /// Update username in Firestore.
  static Future<void> updateUsername(String username) async {
    final uid = currentUid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'username': username.trim(),
    });
  }

  /// Update phone number in Firestore.
  static Future<void> updatePhone(String phone) async {
    final uid = currentUid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'phone': phone.trim(),
    });
  }

  /// Upload a profile image [file] to Firebase Storage and save the download URL
  /// to Firestore. Returns the download URL on success.
  static Future<String> uploadProfileImage(File file) async {
    final uid = currentUid;
    if (uid == null) throw Exception('No authenticated user');

    final ref = _storage
        .ref()
        .child('profile_images')
        .child('$uid.jpg');

    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final downloadUrl = await uploadTask.ref.getDownloadURL();

    await _firestore.collection('users').doc(uid).update({
      'photoUrl': downloadUrl,
    });

    return downloadUrl;
  }
}
