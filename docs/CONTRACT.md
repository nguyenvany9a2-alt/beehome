# Hợp đồng tích hợp Ý — Hào

## Nguồn dữ liệu

| Collection | Quyền sở hữu nghiệp vụ | Trường mà giao diện phần Ý dùng |
|---|---|---|
| services | Ý | name, category, price (number), unit (giờ/gói), duration (int), active (bool), icon, tag, description, includes (list), excludes (list), imageUrl |
| addresses | Ý | userId, label, contact, phone, detail, area, note, default (bool) |
| reviews | Ý | orderId, customerId, workerId, stars (int), comment, createdAt |
| notifications | Ý | userId, title, body, orderId, read (bool), createdAt |
| users | Hào + hồ sơ Ý | name, email, phone, avatarUrl, role, status |
| worker_profiles | Ý, bổ sung để tách hồ sơ công khai | name, skills, area, experience, bio, approval, reason, rating, reviewCount, ratingSum |
| orders | Hào | customerId, workerId, serviceId, serviceName, workerName, date, status, total, addressSnapshot, paymentStatus |
| payments | Hào | Chưa đọc trực tiếp trong giao diện phần Ý; Hào đồng bộ paymentStatus lên orders |

ID được lấy từ document.id; phía Dart thêm trường `id` trong bộ nhớ, không ghi trường đó vào document. Demo dùng ID cố định cho tình huống thử.

Phiên bản này dùng `createdAt` là chuỗi ISO-8601 theo backend, `date` là chuỗi YYYY-MM-DD. Nếu Hào dùng Timestamp phải bổ sung chuyển đổi trong repository trước khi ghép; không trộn hai kiểu âm thầm. `addressSnapshot` hiện là chuỗi hiển thị địa chỉ tại lúc đặt; Hào có thể lưu thêm bản sao có cấu trúc.

## Trạng thái

- Đơn: pending → accepted → working → completed; cancelled theo chính sách hủy của nhóm.
- Hồ sơ nghề nghiệp: pending / approved / rejected.
- Tài khoản: active / blocked.
- Thanh toán: paid / unpaid trong giao diện minh họa; Hào bổ sung trạng thái nếu nghiệp vụ cần.

Backend của Hào là nơi kiểm tra chuyển trạng thái hợp lệ, giữ lịch và xử lý cạnh tranh. Không cho phép admin chọn một trạng thái bất kỳ trên giao diện này.

## Callback đặt dịch vụ

```dart
BeeHomeApp(
  store: store,
  onBookingRequested: (draft) {
    // draft['serviceId'], draft['addressId'], draft['duration']
    // Điều hướng đến màn hình đặt lịch của Hào.
  },
)
```

Callback không truyền giá đáng tin cậy, không tạo đơn và không thanh toán. Backend phải đọc lại dịch vụ còn hoạt động, địa chỉ đúng chủ sở hữu, thời lượng hợp lệ và tính lại giá; lưu bản sao tên, giá, địa chỉ vào đơn. Khi ghép router chung, có thể dùng trực tiếp BeeShell thay vì tạo MaterialApp lồng nhau.

## Tạo tài khoản và phân quyền

Firebase Auth UID là khóa `users`. Backend đặt custom claims; không dùng thao tác client tự ghi role để cấp admin. Giao diện lấy claim sau đăng nhập. Khi đổi tài khoản, hủy BeeStore cũ và tạo store mới, không dùng lại bộ dữ liệu của người trước.

Khóa tài khoản cần đồng bộ Auth và Firestore. Hồ sơ người giúp việc đã duyệt mà sửa thông tin nghề nghiệp sẽ chuyển về chờ duyệt; backend nhận đơn của Hào phải kiểm tra approval tại thời điểm nhận.

## Trách nhiệm chưa nằm trong bản này

- Màn hình đăng ký/đăng nhập/quên mật khẩu, đăng xuất và vòng đời phiên của Hào.
- Luồng đặt lịch, tạo/nhận/hủy đơn, chống trùng lịch.
- Tính giá chính thức và xử lý thanh toán.
- AI thật; cần giao nhiệm vụ riêng.

## Checklist nghiệm thu giao diện

1. Chạy ở 1440 px, 1024 px và 390 px; kiểm tra menu không tràn ngang.
2. Tìm “don nha” ra dịch vụ “Dọn nhà theo giờ”.
3. Lọc giờ/gói rồi sắp xếp giá; không so sánh giá/giờ với giá/gói như cùng đơn vị.
4. Chọn ba dịch vụ để so sánh; không chọn thêm dịch vụ thứ tư.
5. Thêm hai địa chỉ, đổi mặc định, xóa mặc định, tải lại trang.
6. Đánh giá BH1001; không đánh giá lần hai, không đánh giá BH1002 chưa hoàn thành.
7. Đọc thông báo và mở đúng đơn; kiểm tra trạng thái sau tải lại.
8. Chuyển demo admin, sửa dịch vụ, tạm ngừng và kiểm tra danh sách khách.
9. Từ chối hồ sơ phải nhập lý do; duyệt hồ sơ rồi kiểm tra danh sách công khai.
10. Mọi kết quả demo chỉ là minh họa; dùng project test thật để kiểm tra bảo mật.
