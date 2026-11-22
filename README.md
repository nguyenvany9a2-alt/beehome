# BeeHome

Ứng dụng Flutter Web đặt dịch vụ giúp việc nhà của Ý và Hào. Khách hàng chọn dịch vụ và địa chỉ, đặt lịch, theo dõi đơn và đánh giá. Người giúp việc xem công việc và cập nhật tiến độ. Quản trị viên quản lý người dùng, dịch vụ, đơn và hồ sơ chờ duyệt.

## Chạy trong VS Code trên Windows

Mở thư mục BeeHome có cả `pubspec.yaml` và `firebase.local.json`. Bản giao diện đã được kiểm tra bằng Flutter 3.47.6 và Dart 3.13.5.

```console
flutter pub get
firebase deploy --only firestore:rules --project beehome-efadc
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8000 --dart-define-from-file=firebase.local.json
```

Giữ Terminal đang chạy. Trong Mobile Preview mở [http://127.0.0.1:8000](http://127.0.0.1:8000). Với Chrome, dùng `flutter run -d chrome --dart-define-from-file=firebase.local.json`. Tệp cấu hình của nhóm cần có `BEE_FIREBASE` bằng `true` và các thông số Web App của đúng Firebase project. Dùng `firebase.example.json` để đối chiếu tên trường.

## Chức năng

| Khu vực | Thao tác |
|---|---|
| Dịch vụ | Tìm không dấu, lọc theo danh mục, đơn vị, giá và công việc bao gồm, so sánh tối đa ba dịch vụ |
| Đặt lịch | Chọn địa chỉ, thời lượng, ngày và giờ, kiểm tra tổng tiền rồi gửi đơn |
| Đơn, hồ sơ và địa chỉ | Xem lịch và trạng thái, thực hiện thao tác theo vai trò, sửa hồ sơ và quản lý địa chỉ |
| Đánh giá và thông báo | Đánh giá đơn đã hoàn thành, đọc cập nhật và bật thông báo trình duyệt khi dự án đã cấu hình FCM |
| Quản trị | Xem thống kê, quản lý dịch vụ, tài khoản, đơn và duyệt hồ sơ người giúp việc |

## Cấu trúc

- `lib/main.dart` khởi tạo Firebase. `lib/features/auth/` quản lý màn hình đăng nhập, đăng ký và phiên làm việc.
- `lib/features/bee_shell.dart` chứa điều hướng và các màn hình theo vai trò. `lib/features/services/service_catalog.dart` hiển thị danh mục từ Firestore.
- `lib/features/booking/` và `lib/data/order_actions.dart` xử lý chọn lịch và thao tác trên đơn.
- `lib/core/`, `lib/widgets/` và `assets/` chứa giao diện, ảnh bìa và phông chữ tiếng Việt. `lib/data/bee_store.dart` kết nối dữ liệu với Firebase.
- `functions/`, `firestore.rules` và `docs/` chứa backend và tài liệu thiết kế của nhóm. Cách chạy hiện tại nằm ở đầu README này.
- `test/fixtures/` chỉ phục vụ kiểm thử tự động. Khi danh mục thật đang trống, ứng dụng hiển thị trạng thái trống.

## Kiểm tra

```console
flutter analyze
flutter test
flutter build web --release --dart-define-from-file=firebase.local.json
```

Khách vãng lai và người đã đăng nhập bắt đầu ở trang chủ. Nhấn logo để về trang này. Trên máy tính, nút mũi tên thu gọn hoặc ghim thanh công cụ. Trên điện thoại, mở danh sách chức năng bằng nút menu. Trong hồ sơ, người dùng có thể chọn ảnh, nền, tông màu, cỡ chữ và giảm chuyển động.

Chi tiết các collection và chuyển trạng thái nằm trong [hợp đồng dữ liệu](docs/CONTRACT.md). Các bước cấu hình Firebase, thông báo đẩy và chạy Emulator có trong [hướng dẫn Firebase](docs/FIREBASE.md).
