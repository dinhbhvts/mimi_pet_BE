/// Lưu bộ sưu tập sticker của bé và bộ đếm "lượt nhận sao từ minigame" trong
/// ngày - cùng nguyên tắc với [ProgressRepository].
abstract class StickerRepository {
  Future<Set<String>> getOwnedSpecialIds();

  Future<void> setOwnedSpecialIds(Set<String> ids);

  /// Id các sticker bé ĐÃ XEM trong album (để đánh dấu "MỚI" cho phần còn lại).
  Future<Set<String>> getSeenIds();

  Future<void> setSeenIds(Set<String> ids);

  /// Ngày (yyyy-MM-dd) và số lượt đã nhận sao từ minigame trong ngày đó.
  Future<(String?, int)> getGameStarRewards();

  Future<void> setGameStarRewards(String day, int count);
}
