import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore veritabanı servisi
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Kullanıcı koleksiyonu referansı
  CollectionReference get _usersCollection => _db.collection('users');

  /// Yeni kullanıcı profili oluştur
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    await _usersCollection.doc(uid).set({
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'isPremium': false,
      'premiumExpiry': null,
      'totalScans': 0,
      'badges': <String>[],
    });
  }

  /// Kullanıcı profilini getir
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }

  /// Kullanıcı profilini güncelle
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _usersCollection.doc(uid).update(data);
  }

  /// Premium durumunu test amaçlı güncelle
  Future<void> updatePremiumStatus(String uid, bool isPremium) async {
    await _usersCollection.doc(uid).update({
      'isPremium': isPremium,
    });
  }

  /// Tarama sayısını artır
  Future<void> incrementScanCount(String uid) async {
    await _usersCollection.doc(uid).update({
      'totalScans': FieldValue.increment(1),
    });
  }

  /// Başarım ekle
  Future<void> addBadge(String uid, String badgeId) async {
    await _usersCollection.doc(uid).update({
      'badges': FieldValue.arrayUnion([badgeId]),
    });
  }

  /// Tarama sonucu kaydet
  Future<void> saveScanResult({
    required String uid,
    required Map<String, dynamic> scanData,
  }) async {
    await _usersCollection
        .doc(uid)
        .collection('scans')
        .add({
      ...scanData,
      'scannedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Son taramaları getir
  Future<List<Map<String, dynamic>>> getRecentScans(String uid, {int limit = 3}) async {
    final snapshot = await _usersCollection
        .doc(uid)
        .collection('scans')
        .orderBy('scannedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  /// Speedtest sonucu kaydet
  Future<void> saveSpeedTest({
    required String uid,
    required Map<String, dynamic> speedData,
  }) async {
    await _usersCollection
        .doc(uid)
        .collection('speedTests')
        .add({
      ...speedData,
      'testedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Kullanıcı verilerini sil (hesap silme)
  Future<void> deleteUserData(String uid) async {
    // Alt koleksiyonları sil
    final scans = await _usersCollection.doc(uid).collection('scans').get();
    for (final doc in scans.docs) {
      await doc.reference.delete();
    }

    final speedTests = await _usersCollection.doc(uid).collection('speedTests').get();
    for (final doc in speedTests.docs) {
      await doc.reference.delete();
    }

    // Ana dokümanı sil
    await _usersCollection.doc(uid).delete();
  }
}
