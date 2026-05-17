# FoxClean

FoxClean là một công cụ dọn dẹp và tối ưu hóa macOS mạnh mẽ, miễn phí và mã nguồn mở. Nó kết hợp một ứng dụng SwiftUI gốc (native) tuyệt đẹp với lõi Swift dùng chung và giao diện dòng lệnh (CLI) `fox` linh hoạt. Được thiết kế cho những người dùng muốn kiểm soát hoàn toàn hiệu suất máy Mac của mình mà không bị theo dõi (telemetry), không có phí đăng ký, hay bất kỳ chi phí ẩn nào.

![Home](screenshot/home.png)
*Giao diện SwiftUI gốc bóng bẩy giúp giữ cho máy Mac của bạn luôn sạch sẽ và tối ưu.*

## 🚀 Tính Năng Chính

### 🖥️ Ứng dụng SwiftUI Gốc
FoxClean đi kèm với một giao diện ứng dụng macOS gốc, hiện đại, nhanh chóng dựa trên PureMac.
- **Trình Quét Ứng dụng**: Nhanh chóng tìm và quản lý các ứng dụng đã cài đặt.
- **Trình Quét Rác**: Xác định và dọn dẹp các tệp, bộ đệm và nhật ký không cần thiết để giải phóng dung lượng.
- **Phát hiện Tệp Bị Bỏ Rơi**: Phát hiện các tệp còn sót lại từ các ứng dụng đã được gỡ cài đặt trước đó.
- **Trạng thái Hệ thống & Phân tích Ổ đĩa**: Theo dõi sức khỏe máy Mac của bạn và trực quan hóa việc sử dụng ổ đĩa trong thời gian thực.

![Clean](screenshot/clean.png)
*Quét hệ thống sâu và dọn dẹp rác.*

### 🛠️ Lõi `FoxCleanCore` Dùng Chung
Trọng tâm của FoxClean là một lõi dùng chung mạnh mẽ đảm bảo tính nhất quán giữa ứng dụng và CLI.
- **Dọn dẹp Chạy thử (Dry-run)**: Xem những gì sẽ bị xóa trước khi thực hiện bất kỳ thay đổi nào.
- **Ưu tiên Thùng Rác**: Chuyển các tệp vào Thùng rác một cách an toàn theo mặc định, ngăn ngừa mất dữ liệu do vô tình.
- **Nhật ký Hoạt động & Khôi phục**: Duy trì nhật ký hoạt động JSONL, cho phép bạn hoàn tác (rollback) các thay đổi nếu cần.
- **Dọn dẹp Dự án & Trình Cài đặt**: Nhanh chóng xóa các thư mục dự án nặng (như `node_modules` hoặc `.build`) và các tệp cài đặt còn sót lại.

![Uninstall](screenshot/uninstall.png)
*Gỡ cài đặt hoàn toàn các ứng dụng và dữ liệu liên quan một cách an toàn.*

### 💻 CLI `fox` Mạnh mẽ
Đối với người dùng chuyên nghiệp và nhà phát triển, CLI `fox` cung cấp quyền kiểm soát toàn diện đối với hệ thống của bạn:
- Các lệnh khả dụng: `scan`, `clean`, `uninstall`, `log`, `analyze`, `status`, `purge`, `installer`, `optimize`, `open`, `touchid`, và `completion`.

![Options](screenshot/options.png)
*Các tùy chọn bổ sung và cài đặt để dọn dẹp tùy chỉnh.*

## 🔒 An Toàn Là Trên Hết

Chúng tôi ưu tiên sự an toàn cho dữ liệu của bạn.
- **Mặc định là chạy thử (Dry-run)**: Tất cả các hành động CLI mang tính phá hủy đều mặc định ở chế độ chạy thử.
- **Chuyển vào Thùng rác**: Sử dụng cờ `--confirm` để di chuyển các mục vào Thùng rác.
- **Xóa Vĩnh viễn**: Xóa vĩnh viễn thực sự yêu cầu cả hai cờ `--permanent` và `--confirm-permanent`, ngăn ngừa những thảm họa vô tình.

## 💡 Động lực Phát triển & Bài toán "Vibe Coding"

**Tại sao lại tạo ra một công cụ dọn dẹp Mac khác?**
Hệ sinh thái macOS đã có rất nhiều ứng dụng dọn dẹp (như CleanMyMac, Onyx, Pearcleaner...), nhưng hầu hết đều có những "pain points" (điểm yếu) sau:
- **Thương mại & Mã nguồn kín:** Quá nặng nề, yêu cầu trả phí đăng ký (subscription), chứa nhiều telemetry theo dõi người dùng hoặc quảng cáo.
- **Hạn chế của Mã nguồn mở:** Thường thiếu giao diện người dùng (UI) hiện đại, được trau chuốt, hoặc chỉ là những tập lệnh (script) đơn giản không khai thác hết sức mạnh của hệ thống gốc.

**Vấn đề của "Vibe Coding"**
Trong kỷ nguyên phát triển phần mềm với sự hỗ trợ của AI ("vibe coding"), việc xây dựng một ứng dụng macOS hoàn chỉnh với quyền truy cập hệ thống và quản lý state phức tạp của SwiftUI từ đầu là một cơn ác mộng. AI thường xuyên gặp khó khăn và nhầm lẫn với các tệp `project.pbxproj` khổng lồ, dễ gây conflict và các kiến trúc source code liên kết quá chặt chẽ. Các source gốc không đáp ứng được nhu cầu của quy trình làm việc hướng AI hiện đại vì chúng dựa vào cấu trúc dự án Xcode truyền thống, khó bảo trì.

**Giải pháp của FoxClean**
FoxClean giải quyết vấn đề này bằng cách kết hợp trải nghiệm người dùng SwiftUI gốc tuyệt đẹp từ **PureMac** với các bộ quy tắc dọn dẹp mạnh mẽ được lấy cảm hứng từ **Mole**.
Bằng cách sử dụng `XcodeGen` (`project.yml`), FoxClean tách biệt hoàn toàn phần lõi (`FoxCleanCore`), công cụ dòng lệnh (`FoxCleanCLI`) và giao diện (`FoxCleanApp`). Kiến trúc này cực kỳ thân thiện với "vibe coding" — AI chỉ cần sửa đổi các tệp Swift rõ ràng và một tệp YAML đơn giản, loại bỏ hoàn toàn rủi ro conflict tệp `pbxproj`.

## 🙏 Lời Cảm Ơn

FoxClean được xây dựng dựa trên nền tảng của những dự án tuyệt vời. Xin gửi lời cảm ơn chân thành đến các tác giả:
- **momenbasel** - tác giả của [PureMac](https://github.com/momenbasel/PureMac): Đã cung cấp nền tảng giao diện SwiftUI gốc tuyệt đẹp và kiến trúc engine quét hệ thống.
- **tw93** - tác giả của [Mole](https://github.com/tw93/mole): Đã truyền cảm hứng cho các quy tắc dọn dẹp mạnh mẽ và luồng công việc CLI.
- Cộng đồng mã nguồn mở với các công cụ như `XcodeGen` đã giúp hiện thực hóa kiến trúc hiện đại này.

## 🗑️ Gỡ cài đặt FoxClean

Nếu bạn cần gỡ bỏ FoxClean khỏi hệ thống, bạn có hai lựa chọn:

**1. Cách thông thường trên macOS:**
- Mở `Finder` và đi đến thư mục `Applications` (Ứng dụng).
- Kéo `FoxClean.app` vào Thùng rác (hoặc nhấp chuột phải và chọn "Move to Trash").
- Làm trống Thùng rác.

**2. Xóa triệt để qua CLI:**
Để gỡ bỏ hoàn toàn FoxClean và tất cả dữ liệu liên quan (bộ nhớ cache, tùy chọn, nhật ký, v.v.), bạn có thể sử dụng chính CLI của nó trước khi xóa ứng dụng:
```sh
fox uninstall dev.foxclean.app --confirm
```

## 🏗️ Hướng dẫn Xây dựng (Build)

Để xây dựng ứng dụng FoxClean và CLI từ mã nguồn:

```sh
# Cài đặt các phụ thuộc bằng Homebrew
brew bundle

# Tạo dự án Xcode
xcodegen generate

# Build ứng dụng macOS
xcodebuild -scheme FoxCleanApp -destination 'platform=macOS' build

# Chạy kiểm thử Swift
swift test

# Kiểm tra công cụ CLI
swift run fox --version
```

## 📜 Giấy phép & Quyền riêng tư

- **Không theo dõi (No Telemetry)**: FoxClean không theo dõi bạn, không thu thập dữ liệu hoặc gửi bất kỳ thông tin nào đến các máy chủ từ xa.
- **Không phí đăng ký (No Subscription)**: 100% miễn phí vĩnh viễn.
- **Giấy phép MIT**: Mã nguồn mở và do cộng đồng phát triển. Xem tệp [LICENSE](LICENSE) để biết thêm chi tiết.

---

*Giữ cho máy Mac của bạn luôn chạy như mới với FoxClean!*
