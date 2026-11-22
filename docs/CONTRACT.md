# Luồng dữ liệu BeeHome

Firebase Authentication cung cấp UID. Khách vãng lai xem dịch vụ đang mở. Sau khi đăng nhập, ứng dụng nạp hồ sơ theo UID rồi đăng ký luồng cập nhật theo vai trò.

| Dữ liệu | Thao tác của ứng dụng |
|---|---|
| `services/{id}` | Quản trị viên quản lý danh mục. Trang chủ và cửa hàng công khai lọc theo `active == true`. |
| `users/{uid}` | Đăng ký tạo hồ sơ khách hoặc người giúp việc. Vai trò quản trị cần custom claim `role=admin` và tài khoản hoạt động. Chỉnh giao diện lưu vào `appearance`. Ảnh chọn từ thiết bị được thu nhỏ thành PNG 112 × 112 và lưu trong `avatarUrl`. Ảnh HTTPS cũ vẫn hiển thị. |
| `worker_profiles/{uid}` | Người giúp việc gửi hồ sơ nghề nghiệp. Mỗi lần chỉnh sửa sẽ đưa hồ sơ về chờ duyệt. Quản trị viên duyệt hoặc từ chối kèm lý do. |
| `addresses/{id}` | Địa chỉ riêng của khách. Giao dịch cập nhật cả địa chỉ và chỉ mục riêng `users/{uid}/settings/addressBook` để giữ một địa chỉ mặc định khi thêm, đổi hoặc xóa. Lần chỉnh đầu tiên đọc các địa chỉ đã có. |
| `orders/{id}` | Lưu dịch vụ, giá chốt, ngày giờ, địa chỉ và người liên hệ lúc đặt. Khách xem đơn của mình, người giúp việc xem đơn đã nhận, quản trị viên xem danh sách đơn. |
| `job_offers/{orderId}` | Bản rút gọn cho người giúp việc đã duyệt. Có lịch, khu vực, số tiền, mã khách. Địa chỉ chi tiết, tên liên hệ, điện thoại và ghi chú chỉ nằm trong đơn riêng. |
| `work_calendars/{workerId}` | Khoảng thời gian của các việc đang nhận, sắp theo giờ bắt đầu. Giao dịch nhận việc kiểm tra lịch hai bên của khoảng được chèn. Hoàn thành sẽ giải phóng khoảng này. |
| `payments/{orderId}` | Người giúp việc xác nhận số tiền mặt đã thu. Giao dịch hoàn thành tạo một chứng từ với thời điểm máy chủ và đúng tổng tiền của đơn. |
| `reviews/{orderId}`, `rating_totals/{workerId}` | Khách đánh giá đơn đã hoàn thành một lần. Đánh giá và phần cộng vào tổng điểm được ghi nguyên tử. Điểm hiển thị kết hợp tổng mới với điểm và số lượt cũ trên hồ sơ người giúp việc. |
| `notifications/{id}` | Mỗi bước đổi trạng thái tạo một thông báo riêng cho từng người trong đơn. Người nhận đánh dấu đã đọc. Thông báo đẩy ngoài ứng dụng dùng thêm FCM. |

## Vòng đời đơn

Khách xác nhận giá, ngày giờ Việt Nam và địa chỉ. Khi ghi đơn, giao dịch đọc lại giá và địa chỉ để phát hiện thay đổi. Trạng thái đi từ `pending` sang `accepted`, `working`, rồi `completed`. Khách có thể chuyển đơn đang chờ sang `cancelled`. Hai người cùng nhận một đơn sẽ có một giao dịch thành công.

Với đơn chờ tạo từ phiên bản cũ, quản trị viên mở **Quản lý đơn hàng** rồi chọn **Mở nhận việc cho đơn cũ**. Thao tác này tạo thông tin việc đang mở từ đơn đã có. Đơn cũ đã hoàn thành tiếp tục hiển thị trạng thái thanh toán cũ. Chứng từ COD được tạo khi một đơn được xác nhận hoàn thành bằng phiên bản mới.
