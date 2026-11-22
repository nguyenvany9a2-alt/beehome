# Kiểm tra phiên bản trang chủ và luồng đặt dịch vụ

| Phạm vi | Cách kiểm tra |
|---|---|
| Flutter | Flutter 3.47.6 và Dart 3.13.5. Chạy `flutter analyze`, `flutter test` và `flutter build web --release`. |
| Giao diện | Kiểm thử widget ở kích thước máy tính và điện thoại, gồm logo, cuộn, thu gọn, rê chuột, ghim menu, vai trò, hộp thoại địa chỉ, đặt lịch và lưu tùy chỉnh. |
| Dữ liệu và phân quyền | Firebase Auth và Firestore Emulator chạy Rules của kho. Dùng tài khoản khách, hai người giúp việc và một quản trị viên để kiểm tra truy vấn, duyệt, địa chỉ mặc định, đặt và hủy đơn, nhận đồng thời, trùng lịch, thu tiền, đánh giá, thông báo, khóa tài khoản và quyền đọc chéo. |
| Cloud Functions cũ | `node --test functions/test/callables.test.cjs` kiểm tra logic các callable mà bản trước sử dụng. Luồng nghiệp vụ chính của bản này dùng Firestore. |
| Nghiệm thu thực tế của nhóm | Chạy Chrome hoặc Mobile Preview với cấu hình dự án, xác nhận quyền mới đã triển khai. Nếu sử dụng Web Push, thử nhận tin ngoài tab. Nếu bàn giao APK, dùng cấu hình Firebase Android đúng application ID và nghiệm thu trên thiết bị. |

Các bản ghi dùng trong kiểm thử được tạo trong bộ widget test hoặc trong Firebase Emulator riêng. Không có chức năng nạp dữ liệu thử vào danh mục sản phẩm.
