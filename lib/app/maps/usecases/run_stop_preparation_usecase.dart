import 'dart:io';

typedef CaptureMapSnapshot =
    Future<File?> Function({
      required int width,
      required int height,
      required bool addInfo,
      required String fileSuffix,
      bool isTerritory,
    });

class RunStopPreparationResult {
  final DateTime endTime;
  final bool isTerritoryPending;
  final File? storyImagePath;
  final File? mapOnlyImagePath;

  const RunStopPreparationResult({
    required this.endTime,
    required this.isTerritoryPending,
    required this.storyImagePath,
    required this.mapOnlyImagePath,
  });
}

class RunStopPreparationUseCase {
  Future<RunStopPreparationResult> execute({
    required bool hasRawGpsPoints,
    required bool isApplyingMapMatching,
    required bool hasClosedCircuit,
    required bool Function() isClosedCircuit,
    required bool hasRunPath,
    required Future<void> Function() applyMapMatching,
    required CaptureMapSnapshot captureSnapshot,
  }) async {
    DateTime endTime = DateTime.now();
    final isTerritoryPending = hasClosedCircuit || isClosedCircuit();
    File? storyImagePath;
    File? mapOnlyImagePath;

    try {
      if (hasRawGpsPoints && !isApplyingMapMatching) {
        print('🔄 Aplicando Map Matching final antes de mostrar resumo...');
        await applyMapMatching();
        print('✅ Map Matching final concluído');
      }

      if (hasRunPath) {
        storyImagePath = await captureSnapshot(
          width: 540,
          height: 960,
          addInfo: true,
          fileSuffix: 'story',
        );
        mapOnlyImagePath = await captureSnapshot(
          width: 600,
          height: 800,
          addInfo: false,
          fileSuffix: 'map',
          isTerritory: isTerritoryPending,
        );
      }
    } catch (e) {
      print('❌ Erro ao preparar resumo da corrida: $e');
    }

    return RunStopPreparationResult(
      endTime: endTime,
      isTerritoryPending: isTerritoryPending,
      storyImagePath: storyImagePath,
      mapOnlyImagePath: mapOnlyImagePath,
    );
  }
}
