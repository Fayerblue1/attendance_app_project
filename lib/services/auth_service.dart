import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'student' or 'teacher' (atau 'siswa' / 'guru')
  final String nis;
  final String classId;
  final String photoUrl;
  final String whatsapp;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.nis,
    required this.classId,
    this.photoUrl = '',
    this.whatsapp = '',
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawCreatedAt = map['createdAt'];
    DateTime? parsedCreatedAt;
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    }

    return UserModel(
      uid: (map['uid'] as String?)?.isNotEmpty == true ? map['uid'] : docId,
      email: (map['email'] as String?) ?? '',
      name: (map['name'] as String?) ?? (map['fullName'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'student',
      nis: (map['nis'] as String?) ?? (map['studentId'] as String?) ?? '',
      classId:
          (map['classId'] as String?) ?? (map['className'] as String?) ?? '',
      photoUrl: (map['photoUrl'] as String?) ?? '',
      whatsapp: (map['whatsapp'] as String?) ?? '',
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'nis': nis,
      'classId': classId,
      'photoUrl': photoUrl,
      'whatsapp': whatsapp,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    };
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register user with Firebase Auth & Cloud Firestore
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String studentId,
    required String className,
    required String whatsapp,
  }) async {
    final cleanNis = studentId.trim();
    final cleanEmail = email.trim().toLowerCase();

    // 1. Cek dokumen whitelist berdasarkan NIS/NIP (Doc ID = cleanNis)
    final allowedDocRef = _firestore.collection('allowed_users').doc(cleanNis);
    final allowedDoc = await allowedDocRef.get();

    if (!allowedDoc.exists || allowedDoc.data() == null) {
      throw FirebaseAuthException(
        code: 'nis-not-registered',
        message:
            'NIS/NIP ($cleanNis) tidak terdaftar di database sekolah. Hubungi Operator/TU.',
      );
    }

    final allowedData = allowedDoc.data()!;
    if (allowedData['isRegistered'] == true) {
      throw FirebaseAuthException(
        code: 'nis-already-registered',
        message: 'NIS/NIP ($cleanNis) sudah digunakan untuk mendaftar akun.',
      );
    }

    // 2. Buat akun di Firebase Auth setelah lolos pengecekan
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) {
      throw Exception('Gagal membuat akun pengguna.');
    }

    await user.updateDisplayName(fullName.trim());

    final userModel = UserModel(
      uid: user.uid,
      email: cleanEmail,
      name: fullName.trim(),
      role: role,
      nis: cleanNis,
      classId: className.trim(),
      whatsapp: whatsapp.trim(),
      createdAt: DateTime.now(),
    );

    // 3. Simpan profil user ke koleksi 'users'
    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

    // 4. Tandai NIS/NIP sudah terdaftar di 'allowed_users'
    await allowedDocRef.update({'isRegistered': true, 'uid': user.uid});

    return userModel;
  }

  /// Manually save or sync user profile to Firestore
  Future<void> saveUserProfile(UserModel profile) async {
    await _firestore
        .collection('users')
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  /// Sign in with Email or NIS/NIP
  Future<UserCredential> signIn({
    required String identifier,
    required String password,
    required String role,
  }) async {
    String resolvedEmail = identifier.trim();

    // Jika identifier tidak mengandung '@', anggap sebagai NIS / NIP
    if (!resolvedEmail.contains('@')) {
      // 1. Cari berdasarkan field 'nis'
      var querySnapshot = await _firestore
          .collection('users')
          .where('nis', isEqualTo: resolvedEmail)
          .limit(1)
          .get();

      // 2. Jika tidak ditemukan, fallback ke field 'studentId'
      if (querySnapshot.docs.isEmpty) {
        querySnapshot = await _firestore
            .collection('users')
            .where('studentId', isEqualTo: resolvedEmail)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message:
              'Nomor Induk ($resolvedEmail) belum terdaftar di PresensiKu.',
        );
      }

      final data = querySnapshot.docs.first.data();
      resolvedEmail = (data['email'] as String? ?? '').trim();

      if (resolvedEmail.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Email terkait Nomor Induk ini tidak valid.',
        );
      }
    }

    // Lanjutkan autentikasi menggunakan email dan password
    final credential = await _auth.signInWithEmailAndPassword(
      email: resolvedEmail,
      password: password,
    );

    // Validasi peran akun (opsional & direkomendasikan)
    final uid = credential.user?.uid;
    if (uid != null) {
      final profile = await getUserProfile(uid);
      if (profile != null) {
        final expectedRole = _normalizeRole(role);
        final actualRole = _normalizeRole(profile.role);
        if (actualRole.isNotEmpty && actualRole != expectedRole) {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'wrong-role',
            message: 'Akun ini terdaftar sebagai ${profile.role}, bukan $role.',
          );
        }
      }
    }

    return credential;
  }

  /// Normalize role string for comparison
  String _normalizeRole(String rawRole) {
    final value = rawRole.trim().toLowerCase();
    if (value == 'student' || value == 'siswa') return 'siswa';
    if (value == 'teacher' ||
        value == 'guru' ||
        value == 'staff' ||
        value == 'staf') {
      return 'guru';
    }
    return value;
  }

  /// Fetch user profile from Cloud Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('FIRESTORE READ ERROR [${e.code}]: ${e.message}');
    } catch (e) {
      // ignore: avoid_print
      print('FIRESTORE UNKNOWN READ ERROR: $e');
    }
    return null;
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
