# Thiết kế BeeHome và phạm vi Ý

## Tham khảo thị trường

Khảo sát nguồn công khai ngày 07/11/2026:
- bTaskee: https://www.btaskee.com/vi-VN/giup-viec-nha-theo-gio/
- bTaskee — quy trình khách đặt và cộng tác viên nhận việc: https://www.btaskee.com/vi-VN/cau-hoi-thuong-gap/
- JupViec: https://jupviec.vn/
- JupViec — trang ứng dụng do đơn vị phát hành cung cấp: https://play.google.com/store/apps/details?id=vn.jupviec.jupviec&hl=vi

Các nguồn mô tả dịch vụ theo giờ, định kỳ, tổng vệ sinh và mô hình kết nối khách với người giúp việc. Đây là tham khảo nghiệp vụ công khai, không phải kiểm toán đầy đủ app hoặc hệ thống quản trị nội bộ của họ. Không suy đoán họ thiếu các tính năng BeeHome bổ sung.

## Hướng riêng của BeeHome

- Vàng mật ong #F4BE43: nhận diện BeeHome, điểm nhấn và lựa chọn.
- Xanh đậm #173A35: chữ, điều hướng, nút chính có độ tương phản tốt.
- Kem #FAF9F4: nền; trắng: thẻ nội dung.
- Bo góc 12–24 px, khoảng cách 8/12/16/24/32 px.
- Biểu tượng nhà, tổ ong; hình minh họa vector riêng, không sao chép logo đối thủ.
- Desktop có thanh bên, mobile dùng menu thu gọn.

## Cải tiến đưa vào bản mã

| Nhu cầu | Thiết kế BeeHome |
|---|---|
| Không rõ nên chọn gì | Ba lựa chọn theo nhu cầu; dẫn đến dịch vụ đang hoạt động |
| Khó so sánh | Chọn tối đa 3 dịch vụ, so sánh phạm vi và đơn vị giá |
| Nhầm giá/giờ với giá/gói | Hiển thị đơn vị; chỉ sắp xếp giá khi đã chọn cùng đơn vị |
| Tìm kiếm tiếng Việt | Tìm cả chữ có dấu và không dấu |
| Mất thời gian nhập địa chỉ | Địa chỉ mặc định, lưu ghi chú tìm nhà |
| Không rõ bao gồm gì | Phần bao gồm và không bao gồm trên chi tiết dịch vụ |
| Đánh giá không đáng tin | Đánh giá gắn đơn đã hoàn thành, mỗi đơn một lượt |
| Quản trị khó theo dõi | Tổng quan, hồ sơ chờ duyệt, phân biệt giá trị đơn với doanh thu |

## Phân công giữ nguyên

Ý: dịch vụ, hồ sơ, địa chỉ, đánh giá, thông báo, quản trị và theme.
Hào: xác thực, phân quyền, tạo/nhận/hủy đơn, tính giá đáng tin cậy, chống trùng lịch và thanh toán.

Mã Functions và Rules của Ý là đề xuất tích hợp chung; cần Hào rà soát khi ghép. Không thay thế backend nhận đơn và thanh toán.

## AI

Trợ lý hiểu yêu cầu bằng tiếng Việt là hướng mở rộng chưa thực hiện. Nút gợi ý hiện dùng điều kiện cố định, không gọi API và không được trình bày là AI. Nếu thêm AI: backend gọi mô hình, kiểm tra kết quả, hỏi thông tin còn thiếu và chỉ điền trước biểu mẫu; không cho AI quyết định giá hoặc tự tạo đơn.
