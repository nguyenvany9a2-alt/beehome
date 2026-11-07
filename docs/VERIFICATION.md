# Kết quả kiểm tra 07/11/2026

| Kiểm tra | Kết quả |
|---|---|
| Dart formatter / parser | Thành công trên các file lib/ và test/ |
| node --check functions/index.js | Thành công |
| node --test functions/test/callables.test.cjs | 8/8 thành công với mock Firebase |
| flutter analyze | Chưa chạy |
| flutter test | Chưa chạy |
| flutter build web | Chưa chạy |
| QA giao diện bằng trình duyệt | Chưa chạy |
| Firebase Rules / Emulator / backend thật | Chưa chạy |
| Push notification trên thiết bị thật | Chưa chạy |

Công cụ Flutter dừng ở bước khởi tạo do tự động duyệt chặn truy cập metadata cloud của tiến trình. Không thử vượt qua chặn. Vì vậy mã nguồn chưa được xác nhận là build thành công. Kiểm tra cú pháp Dart không thay thế kiểm tra kiểu dữ liệu, dependency hay chạy UI.

8 mock tests: quyền chủ đơn, điểm hợp lệ, đánh giá duy nhất và điểm tổng hợp, quyền duyệt, lý do từ chối, một địa chỉ mặc định và chuyển khi xóa, không ghi đè địa chỉ người khác, từ chối tài khoản bị khóa. Các mock tests chạy logic callable thật nhưng thay Admin SDK bằng dữ liệu trong bộ nhớ; không chứng minh Firestore transaction thật hoặc Rules hoạt động đúng.
