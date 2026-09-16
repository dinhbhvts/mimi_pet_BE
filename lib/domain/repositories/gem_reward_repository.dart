/// Interface (tầng domain) mô tả cách app lưu/đọc số "viên ngọc" bé ĐÃ NHẬN
/// THƯỞNG (bố mẹ đã trả tiền thật ngoài app) - xem [PetAccessoryInfo] cho mô
/// hình tương tự nhưng dùng cho phụ kiện đeo. Cùng nguyên tắc với
/// [ProgressRepository]/[HeartsRepository].
///
/// LƯU Ý: chỉ lưu số ĐÃ NHẬN (claimed) - số ĐÃ ĐẠT MỐC (earned) không cần lưu
/// riêng vì luôn tính được từ [ProgressController.stars] hiện có
/// (`earned = stars ~/ starsPerGem`, xem `GemRewardController`).
abstract class GemRewardRepository {
  Future<int> getClaimedGemCount();

  Future<void> setClaimedGemCount(int count);
}
