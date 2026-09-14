import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';

import '../../../apis/challenges_api.dart';
import '../../../core/providers/instance_providers.dart';
import '../../../core/utils/cloudinary_service.dart';
import '../../../models/challenge_model.dart';

// ============================================================
// CONTROLLER PROVIDER
//
// UI:
//
// final state = ref.watch(citizenControllerProvider);
//
// state.isLoading
// state.hasError
// state.value
//
// Actions:
//
// ref.read(citizenControllerProvider.notifier).submitChallenge(...)
// ============================================================

final citizenControllerProvider =
    StateNotifierProvider<ChallengeController, AsyncValue<Challenge?>>((ref) {
      return ChallengeController(
        api: ref.watch(challengesApiProvider),
        cloudinary: ref.watch(cloudinaryServiceProvider),
      );
    });

// ============================================================
// GET CURRENT USER'S CHALLENGES
// ============================================================

final myChallengesProvider = StreamProvider.autoDispose<List<Challenge>>((ref) {
  final api = ref.watch(challengesApiProvider);

  return api.watchMyChallenges();
});

final challengeStreamProvider = StreamProvider.autoDispose
    .family<Challenge?, String>((ref, challengeId) {
      final api = ref.watch(challengesApiProvider);

      return api.watchChallenge(challengeId);
    });
// ============================================================
// GET ALL CHALLENGES
//
// Useful for Admin.
// ============================================================

final challengesProvider = StreamProvider.autoDispose<List<Challenge>>((ref) {
  final api = ref.watch(challengesApiProvider);

  return api.watchChallenges();
});

// ============================================================
// GET ONE CHALLENGE
//
// ref.watch(challengeProvider(challengeId))
// ============================================================

final challengeProvider = FutureProvider.autoDispose.family<Challenge?, String>(
  (ref, challengeId) {
    final api = ref.watch(challengesApiProvider);

    return api.getChallenge(challengeId);
  },
);

// ============================================================
// VOICE UPLOAD INPUT
// ============================================================

class VoiceUploadInput {
  const VoiceUploadInput({
    required this.file,
    required this.field,
    required this.transcript,
  });

  final File file;

  /// title / description / additional
  final String field;

  final String transcript;
}

// ============================================================
// CHALLENGE CONTROLLER
// ============================================================

class ChallengeController extends StateNotifier<AsyncValue<Challenge?>> {
  ChallengeController({
    required ChallengesApi api,
    required CloudinaryService cloudinary,
  }) : _api = api,
       _cloudinary = cloudinary,
       super(const AsyncData(null));

  final ChallengesApi _api;

  final CloudinaryService _cloudinary;

  // ============================================================
  // SUBMIT CHALLENGE
  // ============================================================

  Future<Challenge?> submitChallenge({
    required String title,
    required String description,
    required String category,
    required String location,

    String additionalInfo = '',

    double? latitude,
    double? longitude,

    File? mediaFile,

    /// Photo / Video
    String? mediaType,

    List<VoiceUploadInput> voiceFiles = const [],
  }) async {
    // Prevent duplicate submissions.
    if (state.isLoading) {
      return null;
    }

    state = const AsyncLoading();

    try {
      // ========================================================
      // VALIDATION
      // ========================================================

      if (title.trim().isEmpty) {
        throw Exception('Title is required');
      }

      if (description.trim().isEmpty) {
        throw Exception('Description is required');
      }

      if (category.trim().isEmpty) {
        throw Exception('Category is required');
      }

      if (location.trim().isEmpty) {
        throw Exception('Location is required');
      }

      // ========================================================
      // CURRENT USER
      // ========================================================

      final userId = _api.currentUserId;

      final challengeId = _api.generateChallengeId();

      // ========================================================
      // CURRENT GPS LOCATION
      //
      // If the user already pressed "Use Current Location"
      // in the UI, latitude/longitude will already exist.
      //
      // Otherwise capture coordinates at submission time.
      // ========================================================

      double? resolvedLatitude = latitude;

      double? resolvedLongitude = longitude;

      if (resolvedLatitude == null || resolvedLongitude == null) {
        try {
          final position = await _getCurrentPosition();

          resolvedLatitude = position.latitude;

          resolvedLongitude = position.longitude;
        } catch (_) {
          /*
           * Location text was already manually provided.
           *
           * Do not fail the entire submission only because
           * GPS could not be obtained.
           *
           * latitude/longitude can remain null.
           */
        }
      }

      // ========================================================
      // UPLOAD PHOTO / VIDEO
      // ========================================================

      final mediaAssets = <ChallengeMedia>[];

      if (mediaFile != null) {
        if (!await mediaFile.exists()) {
          throw Exception('Selected media file no longer exists.');
        }

        final uploaded = await _cloudinary.uploadFile(
          file: mediaFile,
          folder: 'challenges/$userId/$challengeId/media',
        );

        mediaAssets.add(
          ChallengeMedia(
            url: uploaded.url,
            publicId: uploaded.publicId,
            type: mediaType?.trim().toLowerCase() ?? 'media',
            resourceType: uploaded.resourceType,
            format: uploaded.format,
            bytes: uploaded.bytes,
            duration: uploaded.duration,
          ),
        );
      }

      // ========================================================
      // UPLOAD VOICE RECORDINGS
      // ========================================================

      final voiceNotes = <ChallengeVoiceNote>[];

      if (voiceFiles.isNotEmpty) {
        final uploadedVoice = await Future.wait(
          voiceFiles.map((voice) async {
            if (!await voice.file.exists()) {
              throw Exception('Voice recording no longer exists.');
            }

            final cloudAsset = await _cloudinary.uploadFile(
              file: voice.file,
              folder: 'challenges/$userId/$challengeId/voice',
            );

            return ChallengeVoiceNote(
              url: cloudAsset.url,
              publicId: cloudAsset.publicId,
              field: voice.field,
              transcript: voice.transcript.trim(),
              resourceType: cloudAsset.resourceType,
              format: cloudAsset.format,
              bytes: cloudAsset.bytes,
              duration: cloudAsset.duration,
            );
          }),
        );

        voiceNotes.addAll(uploadedVoice);
      }

      // ========================================================
      // CREATE MODEL
      // ========================================================

      final challenge = Challenge(
        id: challengeId,

        title: title.trim(),

        description: description.trim(),

        category: category.trim(),

        location: location.trim(),

        additionalInfo: additionalInfo.trim(),

        latitude: resolvedLatitude,

        longitude: resolvedLongitude,

        media: mediaAssets,

        voiceNotes: voiceNotes,

        // IMPORTANT:
        status: 'Submitted',

        priority: 'Medium',

        submittedBy: _api.currentUserName,

        submittedById: userId,

        createdAt: DateTime.now(),

        updatedAt: DateTime.now(),
      );

      // ========================================================
      // FIRESTORE
      // ========================================================

      final savedChallenge = await _api.createChallenge(challenge);

      // ========================================================
      // SUCCESS STATE
      // ========================================================

      state = AsyncData(savedChallenge);

      return savedChallenge;
    } catch (error, stackTrace) {
      // ========================================================
      // ERROR STATE
      // ========================================================

      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> updateStatus({
    required String challengeId,
    required String status,
    required String note,
  }) async {
    await _api.updateStatus(
      challengeId: challengeId,
      status: status,
      note: note,
    );
  }

  // ============================================================
  // UPDATE PRIORITY
  // ============================================================

  Future<void> updatePriority({
    required String challengeId,
    required String priority,
  }) async {
    await _api.updatePriority(challengeId: challengeId, priority: priority);
  }

  // ============================================================
  // ASSIGN UNIVERSITY
  // ============================================================

  Future<void> assignUniversity({
    required String challengeId,
    required String universityId,
    required String universityName,
  }) async {
    await _api.assignUniversity(
      challengeId: challengeId,
      universityId: universityId,
      universityName: universityName,
    );
  }

  // ============================================================
  // RESET SUBMISSION STATE
  // ============================================================

  void reset() {
    state = const AsyncData(null);
  }

  // ============================================================
  // GET CURRENT DEVICE POSITION
  // ============================================================

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
