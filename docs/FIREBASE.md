# Kết nối Firebase của nhóm

## Trước khi bật chế độ thật

- Phân hệ đăng nhập của Hào phải tạo Firebase Auth user và document `users/{uid}` bằng backend đáng tin cậy.
- User document có `name`, `email`, `phone`, `avatarUrl`, `role`, `status: active`.
- Custom claim `role` là `customer`, `worker` hoặc `admin`. Quyền admin phải được đặt bằng Admin SDK từ môi trường quản trị, không từ Flutter.
- Tạo `worker_profiles/{uid}` riêng cho dữ liệu hồ sơ nghề nghiệp công khai; email/số điện thoại riêng vẫn ở `users`.
- Mở Firebase Authentication bằng phương thức nhóm chọn, tạo Firestore và thêm domain chạy web vào Authorized domains.
- Dùng project thử nghiệm trước khi triển khai dữ liệu thật.

Tham khảo chính thức: https://firebase.google.com/docs/flutter/setup

## Cấu hình Flutter

Sao chép `firebase.example.json` thành `firebase.local.json`, điền các giá trị cấu hình Web App từ Firebase Console. Đây là cấu hình client công khai, KHÔNG phải private key của Admin SDK.

```powershell
flutter pub get
flutter run -d chrome --dart-define-from-file=firebase.local.json
```

`main.dart` dùng FirebaseOptions từ các giá trị dart-define. Nếu nhóm đã dùng `flutterfire configure`, thay phần FirebaseOptions đó bằng `DefaultFirebaseOptions.currentPlatform` của cấu hình được tạo. Không khởi tạo Firebase hai lần khi nhúng vào ứng dụng chung.

Ứng dụng chờ trạng thái xác thực đầu tiên. Nếu chưa đăng nhập, nó hiển thị thông báo yêu cầu ghép màn hình Auth. Để ghép đúng: khởi tạo Firebase → hiện màn hình đăng nhập của Hào → tạo `BeeStore(live:true)` → `await store.init()` → hiện `BeeHomeApp` hoặc `BeeShell` trong router của nhóm.

## Cloud Functions

```powershell
cd functions
npm install
node --test test/callables.test.cjs
cd ..
firebase use --add
firebase deploy --only functions,firestore:rules
```

Không chạy deploy vào project đang hoạt động trước khi ghép Rules của Hào. Rules trong gói này KHÔNG cho tạo hoặc đổi trạng thái đơn từ client. Các callable Functions mặc định ở `us-central1`; nếu đổi vùng, phải đổi FirebaseFunctions.instanceFor(region: ...) phía Dart tương ứng.

| Endpoint | Người gọi | Chức năng |
|---|---|---|
| submitReview | Chủ đơn hoàn thành | Lưu một review/đơn và cập nhật điểm người giúp việc trong transaction |
| saveAddress | Chủ tài khoản | Lưu địa chỉ, tối đa 20 địa chỉ, duy trì một mặc định |
| deleteAddress | Chủ địa chỉ | Xóa, chuyển mặc định nếu cần |
| approveWorker | Admin claim | Duyệt hoặc từ chối có lý do |
| setUserStatus | Admin claim | Khóa/mở user, đồng bộ Firebase Auth và trạng thái Firestore |
| orderNotifications | Trigger trên orders | Tạo thông báo theo thay đổi trạng thái và thử gửi FCM |

Khóa Auth và cập nhật Firestore thuộc hai dịch vụ, không phải transaction xuyên dịch vụ. Cần kiểm thử lỗi giữa chừng và cơ chế đối soát khi nâng cấp production.

## FCM cho web

1. Bật Cloud Messaging và tạo Web Push certificate (VAPID public key).
2. Điền `FIREBASE_VAPID_KEY` trong file cấu hình Dart.
3. Điền `self.BEEHOME_FIREBASE_CONFIG` trong `web/firebase-web-config.js` bằng cùng cấu hình Firebase Web App, ví dụ:

```js
self.BEEHOME_FIREBASE_CONFIG = {
 apiKey: 'PUBLIC_WEB_API_KEY',
 authDomain: 'YOUR_PROJECT.firebaseapp.com',
 projectId: 'YOUR_PROJECT',
 messagingSenderId: 'YOUR_SENDER_ID',
 appId: 'YOUR_WEB_APP_ID'
};
```

4. Đảm bảo `firebase-messaging-sw.js` được phục vụ ở gốc website qua HTTPS (hoặc localhost khi thử).
5. Đăng nhập rồi nhấn “Bật thông báo trình duyệt”.
6. Thử thay đổi trạng thái đơn bằng backend của Hào và kiểm tra thông báo trong app lẫn FCM.

Có code đăng ký token và trigger gửi push; chưa xác minh bằng project thật. Không khẳng định thông báo luôn tới: phụ thuộc trình duyệt, quyền người dùng, thiết bị và dịch vụ FCM. Trigger dùng định danh sự kiện để tránh tạo lặp notification khi retry; thất bại gửi push sau khi tạo notification cần cơ chế retry riêng nếu muốn độ tin cậy production.

Khi tích hợp đăng xuất, Hào phải xóa token của thiết bị khỏi user cũ trước khi đăng xuất trên máy dùng chung. Cần đăng ký lại khi token thay đổi hoặc người dùng đăng nhập lại. Dữ liệu thông báo trong ứng dụng vẫn là nơi xem cập nhật chính.

## Kiểm thử thật cần làm

- Khách A không đọc/sửa địa chỉ, đơn và thông báo của khách B.
- Khách không đổi role/status/approval/rating từ client.
- Hai yêu cầu review cùng lúc chỉ lưu một review.
- Hai yêu cầu đặt mặc định đồng thời vẫn chỉ có một mặc định.
- Người bị khóa không gọi được callable/đọc dữ liệu riêng bằng token cũ.
- Thay giá dịch vụ không làm thay đổi giá đơn cũ.
- FCM foreground/background, từ chối quyền và token hết hạn.
- Chạy Firebase Emulator Suite và kiểm thử Rules trước deploy.

## Deploy web sau khi kiểm thử

```powershell
flutter build web --release --dart-define-from-file=firebase.local.json
firebase deploy --only hosting
```
