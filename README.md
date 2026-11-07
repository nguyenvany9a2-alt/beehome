# BeeHome — Phân hệ của Ý

**Flutter Web / Dart / Firebase · Bản mã nguồn 0.1.0**

BeeHome — Chăm nhà gọn, sống thảnh thơi.

Bộ mã nguồn cho phần dịch vụ, hồ sơ, địa chỉ, thông báo, đánh giá và quản trị của Ý trong đồ án “Xây dựng nền tảng đặt dịch vụ giúp việc nhà”. Đây là bản triển khai ban đầu, không phải sản phẩm đã nghiệm thu hoặc đã kết nối với Firebase của nhóm.

## Chạy bản demo trên Windows / VS Code

1. Giải nén và mở thư mục `beehome` chứa `pubspec.yaml` trong VS Code.
2. Mở Terminal và chạy:

```powershell
flutter --version
flutter pub get
flutter run -d chrome
```

Flutter phải có trong PATH. Dự án yêu cầu Dart >=3.4, khuyến nghị dùng Flutter stable đã cài trên máy của nhóm. Khi `flutter pub get` thành công, giữ `pubspec.lock` và commit vào repo để hai máy dùng cùng phiên bản.

Không cần Firebase để xem demo. Dữ liệu giả lập lưu bằng SharedPreferences trên trình duyệt; có nút khôi phục dữ liệu. Menu chuyển ba vai trò chỉ có trong demo. Dữ liệu, giá, tên và địa chỉ minh họa không phải dữ liệu khách hàng thật.

## Chức năng đã có mã

| Khu vực | Phạm vi |
|---|---|
| Dịch vụ | Danh sách, chi tiết, tìm không dấu, lọc loại/đơn vị/giá, sắp xếp trong cùng đơn vị, so sánh tối đa 3 dịch vụ |
| Gợi ý dịch vụ | Chọn theo nhu cầu bằng quy tắc đơn giản; KHÔNG gọi là AI |
| Chuẩn bị đặt dịch vụ | Chọn địa chỉ, thời lượng, xem ước tính và chuyển callback; không tạo đơn |
| Hồ sơ | Chỉnh tên, số điện thoại, URL ảnh HTTPS; hồ sơ kỹ năng/khu vực của người giúp việc và gửi duyệt |
| Địa chỉ | Thêm/sửa/xóa, địa chỉ mặc định; chuyển mặc định khi xóa địa chỉ đang dùng |
| Đánh giá | Chỉ chủ đơn hoàn thành, một đánh giá/đơn, điểm 1–5, cập nhật điểm trung bình |
| Thông báo | Lọc chưa đọc, đánh dấu đã đọc, mở đơn liên quan; mã đăng ký FCM và trigger gửi thông báo |
| Quản trị | Thống kê toàn bộ, quản lý dịch vụ, khóa/mở tài khoản, duyệt/từ chối hồ sơ, tìm và lọc đơn |
| Giao diện | Vàng mật ong / kem / xanh đậm, sidebar desktop, drawer mobile, biểu mẫu kiểm tra dữ liệu, trạng thái rỗng và lỗi |

Các thành phần dùng Material và hình minh họa vector tự vẽ trong Dart. Không dùng hình ảnh hoặc logo của đối thủ. Ảnh người dùng/dịch vụ có thể nhập bằng URL HTTPS; chưa có tải ảnh lên Cloud Storage.

## Hai chế độ dữ liệu

- **Demo (mặc định):** SharedPreferences; chuyển vai trò để thử các màn hình. Không có bảo mật backend vì đây chỉ là dữ liệu cục bộ.
- **Firebase:** Firebase Auth, Firestore, Cloud Functions và FCM; không hiển thị bộ chuyển vai trò. Vai trò quản trị lấy từ custom claims do máy chủ đặt, không lấy từ lựa chọn trên giao diện.

Chế độ Firebase yêu cầu cấu hình project và phiên Firebase Auth của phân hệ Hào. Xem `docs/FIREBASE.md`. Không tự chuyển sang demo khi Firebase lỗi.

## Điểm nối với Hào

`BeeHomeApp(store: store, onBookingRequested: (draft) { ... })` nhận callback gồm `serviceId`, `addressId`, `duration`. Hào mở màn hình chọn lịch, báo giá từ backend và tạo đơn. Chưa tích hợp đăng ký/đăng nhập, nhận/hủy đơn, chống trùng lịch và thanh toán thực tế.

Firestore Rules kèm theo cố ý từ chối client tạo/sửa đơn. Khi ghép hai phần, tích hợp endpoint xử lý đơn đáng tin cậy của Hào; không mở quyền ghi toàn bộ `orders` từ client. Xem `docs/CONTRACT.md`.

## Cấu trúc

- `lib/core/theme.dart`: theme, định dạng tiền, chuẩn hóa tìm kiếm.
- `lib/data/seed.dart`: dữ liệu giả lập.
- `lib/data/bee_store.dart`: dữ liệu demo và lớp truy cập Firebase, theo dõi cập nhật Firestore.
- `lib/features/bee_shell.dart`: các màn hình và biểu mẫu phần Ý.
- `lib/widgets/common.dart`: thành phần giao diện chung, vector minh họa.
- `functions/index.js`: callable functions và trigger đơn hàng.
- `firestore.rules`: quy tắc phân quyền của phân hệ này.
- `web/`: entrypoint Flutter và cấu hình service worker FCM.
- `test/`: kiểm thử Dart/Flutter được chuẩn bị, chưa chạy trong môi trường tạo mã.
- `functions/test/`: kiểm thử callable backend với mock Firebase.

## Kiểm tra và build trên máy nhóm

```powershell
flutter analyze
flutter test
flutter build web --release
node --test functions/test/callables.test.cjs
```

## Trạng thái xác minh thực tế

- Đã chạy Dart formatter/parser: tất cả tệp Dart được phân tích cú pháp và định dạng thành công.
- Đã kiểm tra cú pháp JavaScript backend/service worker.
- Đã chạy 8 kiểm thử backend với mock Firebase: 8/8 thành công. Các test kiểm tra quyền đánh giá, đơn hoàn thành, chống đánh giá lặp, giới hạn điểm, quyền duyệt, lý do từ chối và địa chỉ mặc định.
- **Chưa chạy `flutter analyze`, `flutter test`, `flutter build web` hoặc kiểm tra giao diện trên trình duyệt.** Bước khởi tạo công cụ Flutter bị cơ chế duyệt môi trường chặn do truy cập metadata của cloud. Không coi việc parser thành công là build thành công.
- **Chưa kiểm thử Firebase Emulator/Rules, cạnh tranh giao dịch hoặc deploy lên Firebase thật.** Mock test không thay thế các bước này.
- Chưa có website được triển khai hoặc APK.

## Các phần cần hoàn thiện trước nghiệm thu

1. Chạy analyze/test/build trên máy nhóm, sửa bất kỳ lỗi tương thích dependency nào và kiểm tra giao diện desktop/mobile.
2. Ghép xác thực và luồng đặt đơn của Hào; dùng cùng schema và trạng thái.
3. Cấu hình Firebase, custom claims, Functions, Rules và service worker; kiểm thử bằng nhiều tài khoản thật trong môi trường test.
4. Kiểm thử quyền truy cập, gửi thông báo trình duyệt, token hết hạn và tình huống đồng thời.
5. Bổ sung tải ảnh Cloud Storage, phân trang/giới hạn truy vấn, thống kê theo khoảng thời gian và khả năng truy cập.
6. Thống nhất tính năng AI với nhóm; bản này chưa gọi mô hình AI.

Tham khảo khảo sát sản phẩm và các cải tiến tại `docs/DESIGN.md`.
