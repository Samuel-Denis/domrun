import 'dart:io';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:nur_app/app/battles/controller/battle_controller.dart';
import 'package:nur_app/app/maps/models/run_model.dart';
import 'package:nur_app/app/maps/service/territory_service.dart';

enum RunSaveAction {
  battleHandled,
  territorySaved,
  territoryFailed,
  simpleRunSaved,
  simpleRunFailed,
  unavailable,
}

class RunSaveInput {
  final DateTime stopTime;
  final DateTime? startTime;
  final List<mb.Position> runPath;
  final double distance;
  final Duration duration;
  final bool isTerritoryPending;
  final bool isSavingTerritory;
  final String? caption;
  final File? mapImagePath;
  final File? mapImageCleanPath;
  final BattleController? battleController;

  const RunSaveInput({
    required this.stopTime,
    required this.startTime,
    required this.runPath,
    required this.distance,
    required this.duration,
    required this.isTerritoryPending,
    required this.isSavingTerritory,
    required this.caption,
    required this.mapImagePath,
    required this.mapImageCleanPath,
    required this.battleController,
  });
}

class RunSaveResult {
  final RunSaveAction action;
  final Object? error;
  final bool shouldClearCapturedImages;

  const RunSaveResult({
    required this.action,
    this.error,
    this.shouldClearCapturedImages = false,
  });
}

class RunSaveUseCase {
  final TerritoryService _territoryService;

  RunSaveUseCase(this._territoryService);

  Future<RunSaveResult> execute({
    required RunSaveInput input,
    required Future<void> Function() saveTerritoryCapture,
  }) async {
    final battleController = input.battleController;

    if (battleController != null &&
        battleController.isInBattle.value &&
        input.runPath.isNotEmpty &&
        input.startTime != null) {
      try {
        final durationSeconds = input.stopTime
            .difference(input.startTime!)
            .inSeconds;
        final pathPoints = _buildPathPoints(
          runPath: input.runPath,
          baseTimestamp: input.startTime!,
          stopTime: input.stopTime,
        );

        await battleController.submitBattleResult(
          distance: input.distance,
          duration: durationSeconds,
          path: pathPoints,
        );
        print('✅ [BATALHA] Resultado submetido com sucesso');
        return const RunSaveResult(action: RunSaveAction.battleHandled);
      } catch (e) {
        print('⚠️ [BATALHA] Erro ao verificar batalha ativa: $e');
        return RunSaveResult(action: RunSaveAction.simpleRunFailed, error: e);
      }
    }

    if (input.isTerritoryPending) {
      try {
        await saveTerritoryCapture();
        return const RunSaveResult(action: RunSaveAction.territorySaved);
      } catch (e) {
        print('❌ [TERRITÓRIO] Erro ao salvar manualmente: $e');
        return RunSaveResult(action: RunSaveAction.territoryFailed, error: e);
      }
    }

    if (!input.isSavingTerritory &&
        input.runPath.isNotEmpty &&
        input.startTime != null) {
      try {
        print('🏃 [CORRIDA] Salvando corrida simples no servidor...');

        final pathPoints = _buildPathPoints(
          runPath: input.runPath,
          baseTimestamp: input.startTime!,
          stopTime: input.stopTime,
        );
        final run = RunModel(
          id: '',
          startTime: input.startTime!,
          endTime: input.stopTime,
          path: pathPoints,
          distance: input.distance,
          duration: input.duration,
          caption: input.caption?.isNotEmpty == true ? input.caption : null,
        );

        await _territoryService.saveSimpleRun(
          run,
          mapImagePath: input.mapImagePath,
          mapImageCleanPath: input.mapImageCleanPath,
        );

        final shouldClearImages =
            input.mapImagePath != null || input.mapImageCleanPath != null;
        print('✅ [CORRIDA] Corrida simples salva com sucesso!');
        return RunSaveResult(
          action: RunSaveAction.simpleRunSaved,
          shouldClearCapturedImages: shouldClearImages,
        );
      } catch (e) {
        print('❌ [CORRIDA] Erro ao salvar corrida simples: $e');
        return RunSaveResult(action: RunSaveAction.simpleRunFailed, error: e);
      }
    }

    return const RunSaveResult(action: RunSaveAction.unavailable);
  }

  List<PositionPoint> _buildPathPoints({
    required List<mb.Position> runPath,
    required DateTime baseTimestamp,
    required DateTime stopTime,
  }) {
    final pathPoints = <PositionPoint>[];
    final totalSeconds = stopTime.difference(baseTimestamp).inSeconds;
    final intervalPerPoint = runPath.length > 1
        ? totalSeconds / (runPath.length - 1)
        : 0.0;

    for (int i = 0; i < runPath.length; i++) {
      final pos = runPath[i];
      final timestamp = baseTimestamp.add(
        Duration(seconds: (i * intervalPerPoint).round()),
      );
      pathPoints.add(
        PositionPoint(
          latitude: pos.lat.toDouble(),
          longitude: pos.lng.toDouble(),
          timestamp: timestamp,
        ),
      );
    }

    return pathPoints;
  }
}
