# assets/images

**Cập nhật:** kể từ khi chuyển sang vẽ Mimi bằng vector (Canvas, xem
`lib/presentation/widgets/mimi_painter.dart`), `PetAvatar` **không còn dùng**
6 file PNG dưới đây nữa (không còn `Image.asset(...)` trong code). Lý do đổi:
vector luôn nét ở mọi kích thước, không tốn dung lượng, và animate mượt hơn
nhiều theo từng bộ phận (tai, mắt, miệng...) so với xoay/co giãn cả tấm ảnh
tĩnh. Các file PNG này được **giữ lại** để tham khảo/lịch sử, hoặc phòng khi
sau này muốn quay lại dùng ảnh thật (chỉ cần sửa `PetAvatar` dùng lại
`Image.asset` như bản cũ, không ảnh hưởng phần còn lại của app).

Trước đây, 6 ảnh nhân vật Mimi thật này được tách ra từ character sheet mà
bạn tạo cùng ChatGPT (cuộc trò chuyện "Tạo ứng dụng Buddy mini" - ảnh "Mimi
thỏ tím: Bộ biểu cảm 3D"), khớp với `PetMood` trong
`lib/domain/entities/pet_mood.dart`:

- `mimi_idle.png` - pose "Idle" trong character sheet
- `mimi_listening.png` - pose "Listening"
- `mimi_thinking.png` - pose "Thinking"
- `mimi_talking.png` - pose "Talking"
- `mimi_happy.png` - pose "Excited" (dùng cho lúc bé trả lời đúng, ăn mừng)
- `mimi_encourage.png` - dùng lại pose "Idle" (bình tĩnh) cho lúc bé trả lời
  chưa đúng - cố tình KHÔNG dùng pose "Sad" có sẵn trong character sheet, để
  không tạo cảm giác tiêu cực cho bé.

## Lưu ý chất lượng ảnh hiện tại

6 ảnh này được cắt ra bằng cách chụp lại màn hình cuộc trò chuyện ChatGPT
(trình duyệt không cho tải trực tiếp file gốc trong môi trường này), rồi tự
động xoá nền trắng để có PNG trong suốt. Chất lượng vì vậy **chỉ ở mức khá**
(hơi mềm/nhoè viền khi phóng to), đủ dùng tốt cho MVP nhưng chưa phải chất
lượng cuối cùng.

**Để có chất lượng cao nhất**, bạn có thể tự thay thế: mở lại cuộc trò
chuyện ChatGPT, bấm vào ảnh "Mimi thỏ tím: Bộ biểu cảm 3D" để mở toàn màn
hình, bấm nút Tải xuống (⬇) ở góc trên bên phải để lưu file gốc (độ phân
giải cao, không nén mất chi tiết) về máy, sau đó tự cắt riêng từng pose
(hoặc nhờ ChatGPT xuất riêng từng ảnh idle/happy/listening/thinking/talking
nền trong suốt như kế hoạch ban đầu) và ghi đè vào đúng tên file ở trên -
không cần sửa code gì thêm.

## Nếu muốn đổi nhân vật/pose khác

Chỉ cần thay file PNG cùng tên (nền trong suốt, vuông, nhìn chính diện,
không chữ/không UI) - `PetAvatar` và toàn bộ app không cần đổi gì.
