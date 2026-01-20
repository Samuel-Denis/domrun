import 'package:get/get.dart';
import 'package:nur_app/app/ranking/models/trophy_ranking_entry.dart';
import 'package:nur_app/app/ranking/service/ranking_service.dart';

class RankingController extends GetxController {
  final RankingService _service;
  RankingController(this._service);

  final RxList<TrophyRankingEntry> users = <TrophyRankingEntry>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load({int limit = 10}) async {
    try {
      isLoading.value = true;
      error.value = null;

      final data = await _service.getTrophyRanking(limit: limit);

      // Garante ordenação (desc)
      final sorted = [...data]
        ..sort((a, b) => b.trophies.compareTo(a.trophies));

      // Recalcula posição (1..N) para não depender do backend
      final normalized = <TrophyRankingEntry>[
        for (int i = 0; i < sorted.length; i++)
          sorted[i].copyWith(position: i + 1),
      ];

      users.assignAll(normalized);
    } catch (e) {
      // evita printar exceção gigante pro usuário final
      error.value = 'Falha ao carregar o ranking. Tente novamente.';
    } finally {
      isLoading.value = false;
    }
  }
}
