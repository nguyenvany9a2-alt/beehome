# Kết nối Firebase của nhóm

Chạy lệnh trong thư mục BeeHome có `pubspec.yaml`, `firebase.json` và `firestore.rules`. Dùng tài khoản nhóm có quyền quản lý dự án `beehome-efadc`.

## Chạy bản web với dữ liệu thật

1. Trong Firebase Console, mở **Authentication → Sign-in method** và bật **Email/Password**. Mở **Firestore Database → Data** để xác nhận đang ở cơ sở dữ liệu `(default)` của đúng dự án.
2. Giữ tệp `firebase.local.json` của dự án ở cùng cấp với `pubspec.yaml`. Nếu cài trên máy khác, sao chép mẫu `firebase.example.json` và điền cấu hình **Project settings → Your apps → Web app**. Giữ `BEE_FIREBASE` bằng `true`.
3. Nếu nhóm có chỉnh quy tắc trực tiếp trên Console sau khi đóng ZIP, đối chiếu phiên bản ở **Firestore Database → Rules** với file đi kèm. Bước triển khai thay bộ quy tắc đang có hiệu lực cho cả nhóm. Xem lại phiên bản trước trong lịch sử Rules nếu cần khôi phục quyền cũ.
4. Chạy trong CMD.

```bat
flutter pub get
firebase deploy --only firestore:rules --project beehome-efadc
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8000 --dart-define-from-file=firebase.local.json
```

Mở `http://127.0.0.1:8000` trong Mobile Preview của VS Code và giữ Terminal đang chạy. Nếu cổng đang có BeeHome cũ, dừng phiên Flutter cũ bằng `q`, rồi chạy lại. Dùng `flutter run -d chrome --dart-define-from-file=firebase.local.json` nếu muốn mở Chrome riêng.

Trang chủ đọc các tài liệu dịch vụ đang mở. Danh mục chưa có dữ liệu sẽ hiển thị trạng thái trống. Quản trị viên có thể thêm dịch vụ hoặc tiếp tục dùng bộ nhập CSV trước đây của nhóm. Chỉ triển khai Rules sẽ không nhập lại danh mục hay xóa tài liệu.

## Tài khoản

Khách hàng và người giúp việc tự chọn vai trò khi đăng ký. Hồ sơ người giúp việc mới ở trạng thái chờ duyệt. Tài khoản quản trị đã cấp trước đây tiếp tục dùng UID cũ và custom claim `role=admin`. Sau khi cấp quyền, đăng xuất và đăng nhập lại.

Khóa tài khoản trong BeeHome chuyển `users/{uid}.status` sang `blocked` và Rules chặn dữ liệu riêng. Nếu tài khoản từng bị vô hiệu hóa tại **Authentication → Users** hoặc bằng công cụ quản lý cũ, người quản trị cũng cần bật lại tài khoản ở Authentication khi mở khóa.

## Thông báo đẩy trình duyệt

Chuông trong ứng dụng đọc Firestore. Nếu nhóm muốn nhận thông báo khi chuyển sang tab khác hoặc đóng BeeHome, phần bổ sung này cần Web Push và trigger gửi tin.

1. Trong Project settings → Cloud Messaging → Web Push certificates, lấy public VAPID key và điền `FIREBASE_VAPID_KEY` trong `firebase.local.json`.
2. Chạy `node tool/configure_web_push.cjs` ở gốc dự án để tạo file cấu hình web công khai cho service worker. Xây dựng hoặc khởi động lại bản web.
3. Nếu nhóm chọn triển khai Cloud Functions trên gói Blaze, dùng Node 22 và chạy hai lệnh dưới đây. Nếu nhóm đã triển khai trigger phiên bản cũ, cập nhật trigger cùng phiên bản giao diện để tránh thông báo trong ứng dụng bị lặp.

```bat
npm --prefix functions install
firebase deploy --only functions:orderNotifications --project beehome-efadc
```

4. Trên HTTPS hoặc localhost, đăng nhập và vào **Thông báo → Bật thông báo trình duyệt**. Cho phép thông báo, chuyển sang tab khác rồi thử đổi trạng thái đơn từ tài khoản thứ hai. Mobile Preview có thể giới hạn thông báo của trình duyệt nhúng.

## Kiểm thử riêng với Emulator

Có thể chạy suite hợp đồng bằng Firebase CLI, Java và Node 22 từ thư mục gốc. Suite chỉ ghi vào dự án kiểm thử có tiền tố `demo-` và các địa chỉ loopback của Emulator.

```bat
npm --prefix functions install
firebase emulators:exec --only auth,firestore --project demo-beehome-refit "node --test functions/test/workflow.emulator.cjs"
```

Nếu muốn thử giao diện bằng Emulator, mở thêm một Terminal chạy bản web với `--dart-define=BEE_EMULATORS=true` và tệp dart-define riêng có project ID trùng với Emulator. Bản chạy từ `firebase.local.json` của nhóm ở mục đầu dùng Firebase thật.

## Tài liệu nền tảng

- [Quản lý và triển khai Firestore Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Triển khai Cloud Functions](https://firebase.google.com/docs/functions/get-started)
- [Nhận thông báo FCM trên web](https://firebase.google.com/docs/cloud-messaging/js/receive)
