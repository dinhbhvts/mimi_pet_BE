/// Địa chỉ backend (FastAPI, xem thư mục `backend/`) - lấy qua build-time
/// define thay vì hard-code, để CÙNG 1 codebase build ra được cả bản dev
/// (trỏ localhost) và bản production (trỏ Render) mà không cần sửa code:
///
///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
///   flutter build web --dart-define=API_BASE_URL=https://<ten-app>.onrender.com
///   flutter build apk --dart-define=API_BASE_URL=https://<ten-app>.onrender.com
///
/// Xem `deployment.md` để biết cách deploy backend lên Render và lấy đúng
/// URL cần điền vào đây.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
