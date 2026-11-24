import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_runtime.dart';

class CloudDataService {
  CloudDataService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  /// The admin email is fixed in the application. Only the password is entered
  /// after the hidden version-tap gesture. Create this account in Firebase Auth.
  static const String adminEmail = 'admin@dfish.live';

  static bool get isReady => FirebaseRuntime.isReady;

  static Future<void> signInAdmin(String password) async {
    if (!isReady) {
      throw StateError('إعداد Firebase غير مكتمل. راجع docs/FIREBASE_SETUP_AR.md.');
    }
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw StateError('تعذر إنشاء جلسة الإدارة.');
      final adminDoc = await _db.collection('admin_users').doc(user.uid).get();
      if (!adminDoc.exists || adminDoc.data()?['enabled'] != true) {
        await _auth.signOut();
        throw StateError('هذا الحساب لا يملك صلاحية إدارة DFISH LIVE.');
      }
    } on FirebaseAuthException catch (error) {
      throw StateError(_authError(error.code));
    }
  }

  static Future<bool> currentUserIsAdmin() async {
    if (!isReady) return false;
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await _db.collection('admin_users').doc(user.uid).get();
      return doc.exists && doc.data()?['enabled'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> signOutAdmin() async {
    if (isReady) await _auth.signOut();
  }

  static Stream<List<Map<String, dynamic>>> watchPublicMatches() {
    if (!isReady) {
      return Stream.error(StateError('خدمة المزامنة غير مضبوطة بعد.'));
    }
    return _db
        .collection('matches')
        .where('enabled', isEqualTo: true)
        .snapshots()
        .map(_sortedRows);
  }

  static Stream<List<Map<String, dynamic>>> watchAdminMatches() {
    if (!isReady) {
      return Stream.error(StateError('خدمة المزامنة غير مضبوطة بعد.'));
    }
    return _db.collection('matches').snapshots().map(_sortedRows);
  }

  static List<Map<String, dynamic>> _sortedRows(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final rows = snapshot.docs
        .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
        .toList();
    rows.sort((a, b) {
      final dateCompare = (a['date']?.toString() ?? '')
          .compareTo(b['date']?.toString() ?? '');
      if (dateCompare != 0) return dateCompare;
      return (a['time']?.toString() ?? '')
          .compareTo(b['time']?.toString() ?? '');
    });
    return rows;
  }

  static Future<void> saveMatch(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    if (!isReady) throw StateError('خدمة Firebase غير متاحة.');
    if (!await currentUserIsAdmin()) {
      throw StateError('انتهت صلاحية الإدارة. سجّل الدخول مجدداً.');
    }
    final collection = _db.collection('matches');
    final reference = id == null || id.isEmpty ? collection.doc() : collection.doc(id);
    final clean = <String, dynamic>{
      ...data,
      'enabled': data['enabled'] == true,
      'sources': (data['sources'] as List?) ?? const [],
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (id == null || id.isEmpty) {
      clean['createdAt'] = FieldValue.serverTimestamp();
    }
    await reference.set(clean, SetOptions(merge: true));
  }

  static Future<void> deleteMatch(String id) async {
    if (!isReady) throw StateError('خدمة Firebase غير متاحة.');
    if (!await currentUserIsAdmin()) {
      throw StateError('انتهت صلاحية الإدارة. سجّل الدخول مجدداً.');
    }
    await _db.collection('matches').doc(id).delete();
  }

  static Future<void> refreshMatches() async {
    if (!isReady) throw StateError('خدمة Firebase غير متاحة.');
    await _db.collection('matches').where('enabled', isEqualTo: true).get(
          const GetOptions(source: Source.server),
        );
  }

  static String _authError(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'كلمة مرور الإدارة غير صحيحة.';
      case 'too-many-requests':
        return 'محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.';
      case 'network-request-failed':
        return 'تعذر الاتصال. تحقق من الإنترنت.';
      case 'user-disabled':
        return 'حساب الإدارة موقوف.';
      case 'invalid-email':
        return 'بريد حساب الإدارة غير صالح. راجع إعدادات المشروع.';
      default:
        return 'تعذر تسجيل الدخول: $code';
    }
  }
}
