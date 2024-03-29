import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pet_melody/data/definitions/app_definitions.dart';
import 'package:my_pet_melody/data/model/make_piece_availability.dart';
import 'package:my_pet_melody/data/model/movie_segmentation.dart';
import 'package:my_pet_melody/data/model/preference_key.dart';
import 'package:my_pet_melody/data/model/template.dart';
import 'package:my_pet_melody/data/model/uploaded_media.dart';
import 'package:my_pet_melody/data/repository/settings_repository.dart';
import 'package:my_pet_melody/data/repository/submission_repository.dart';
import 'package:my_pet_melody/data/service/app_service.dart';
import 'package:my_pet_melody/data/service/auth_service.dart';
import 'package:my_pet_melody/data/service/in_app_purchase_service.dart';
import 'package:my_pet_melody/data/service/preference_service.dart';
import 'package:my_pet_melody/data/service/push_notification_service.dart';
import 'package:my_pet_melody/data/service/storage_service_firebase.dart';
import 'package:my_pet_melody/data/usecase/piece_use_case.dart';

final getMakePieceAvailabilityActionProvider = FutureProvider((ref) async {
  final isPremiumPlan = ref.watch(isPremiumPlanProvider);
  final pieces = await ref.watch(piecesProvider.future);
  final preferenceService = ref.watch(preferenceServiceProvider);

  final validPieces = pieces.where(
    (piece) => piece.map(
      generating: (_) => true,
      generated: (_) => true,
      expired: (_) => false,
    ),
  );

  Future<MakePieceAvailability> action() async {
    final userRequestedDoNotShowWarningsAgainForMakingPiece =
        await preferenceService.getBool(
              PreferenceKey.userRequestedDoNotShowWarningsAgainForMakingPiece,
            ) ??
            false;

    if (isPremiumPlan == true) {
      if (validPieces.length < maxPiecesOnPremiumPlan) {
        return MakePieceAvailability.available;
      }

      if (userRequestedDoNotShowWarningsAgainForMakingPiece) {
        return MakePieceAvailability.available;
      }

      return MakePieceAvailability.availableWithWarnings;
    }

    if (validPieces.length < maxPiecesOnFreePlan) {
      return MakePieceAvailability.available;
    }

    return MakePieceAvailability.unavailable;
  }

  return action;
});

final requestDoNotShowWarningsAgainForMakingPieceActionProvider =
    Provider((ref) {
  final preferenceService = ref.watch(preferenceServiceProvider);

  Future<void> action() async {
    await preferenceService.setBool(
      PreferenceKey.userRequestedDoNotShowWarningsAgainForMakingPiece,
      value: true,
    );
  }

  return action;
});

final isAvailableToTrimSoundForGenerationProvider = Provider((ref) {
  final isPremiumPlan = ref.watch(isPremiumPlanProvider);

  return isPremiumPlan == true;
});

final detectActionProvider = FutureProvider((ref) async {
  final session = await ref.watch(sessionStreamProvider.future);
  final storageService = await ref.read(storageServiceProvider.future);
  final repository = ref.read(submissionRepositoryProvider);

  Future<MovieSegmentation?> action(
    File file, {
    required String fileName,
  }) async {
    final uploaded = await storageService.uploadUnedited(
      file,
      fileName: fileName,
    );
    if (uploaded == null) {
      return null;
    }

    return repository.detect(
      from: uploaded,
      token: session.token,
    );
  }

  return action;
});

final uploadActionProvider = FutureProvider((ref) async {
  final storageService = await ref.read(storageServiceProvider.future);

  return storageService.uploadEdited;
});

final getShouldShowRequestPushNotificationPermissionActionProvider =
    Provider((ref) {
  final settingsRepository = ref.read(settingsRepositoryProvider);
  final androidDeviceSdkIntFuture =
      ref.read(androidDeviceSdkIntProvider.future);

  Future<bool> action() async {
    if (Platform.isIOS ||
            (Platform.isAndroid &&
                await androidDeviceSdkIntFuture >= 33) // Android 13 or higher
        ) {
      final hasRequestedPermission = await settingsRepository
          .getHasRequestedPushNotificationPermissionAtLeastOnce();

      return !hasRequestedPermission;
    }

    return false;
  }

  return action;
});

final requestPushNotificationPermissionActionProvider = Provider((ref) {
  final pushNotificationService = ref.read(pushNotificationServiceProvider);
  final settingsRepository = ref.read(settingsRepositoryProvider);

  Future<void> action() async {
    await pushNotificationService.requestPermission();

    await settingsRepository
        .setHasRequestedPushNotificationPermissionAtLeastOnce();
  }

  return action;
});

final submitActionProvider = FutureProvider((ref) async {
  final repository = ref.read(submissionRepositoryProvider);
  final purchaseActions = ref.watch(purchaseActionsProvider);
  final session = await ref.watch(sessionStreamProvider.future);

  Future<void> action({
    required Template template,
    required List<UploadedMedia> sounds,
    required String displayName,
    required UploadedMedia thumbnail,
  }) async {
    final purchaseUserId = await purchaseActions.userId();

    await repository.submit(
      templateId: template.id,
      sounds: sounds,
      displayName: displayName,
      thumbnail: thumbnail,
      token: session.token,
      purchaseUserId: purchaseUserId,
    );
  }

  return action;
});
