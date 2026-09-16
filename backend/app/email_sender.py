"""Gửi email mã đăng nhập qua SMTP thuần (chạy được với Gmail App Password,
miễn phí, không cần đăng ký dịch vụ email thứ 3).

Nếu CHƯA cấu hình SMTP (ví dụ lúc dev cục bộ), in mã ra console thay vì gửi
thật - vẫn test được trọn luồng đăng nhập mà không cần tài khoản email.
"""
import os
import smtplib
import socket
from contextlib import contextmanager
from email.mime.text import MIMEText


@contextmanager
def _force_ipv4_dns():
    """Gói Free của Render không route ra ngoài được qua IPv6, nhưng DNS của
    smtp.gmail.com vẫn trả về cả bản ghi IPv6 - `socket.create_connection`
    (bên trong `smtplib.SMTP.connect`) thử theo thứ tự DNS trả về, thường ưu
    tiên IPv6 trước, rơi trúng địa chỉ không route được -> "OSError: Network
    is unreachable" (Errno 101) dù host/user/password đều đúng. Ép tạm
    `socket.getaddrinfo` chỉ trả về IPv4 trong lúc gửi email - không ảnh
    hưởng các kết nối khác của app (NeonDB/HTTP) vì chỉ patch trong scope
    `with` này rồi khôi phục lại ngay."""
    original = socket.getaddrinfo

    def _ipv4_only(host, port, family=0, type=0, proto=0, flags=0):
        return original(host, port, socket.AF_INET, type, proto, flags)

    socket.getaddrinfo = _ipv4_only
    try:
        yield
    finally:
        socket.getaddrinfo = original


def send_login_code(email: str, code: str) -> None:
    host = os.environ.get("SMTP_HOST")
    user = os.environ.get("SMTP_USER")
    password = os.environ.get("SMTP_PASSWORD")

    if not host or not user or not password:
        print(f"[email_sender] Chưa cấu hình SMTP - mã đăng nhập cho {email}: {code}")
        return

    port = int(os.environ.get("SMTP_PORT", "587"))
    from_email = os.environ.get("FROM_EMAIL", user)

    subject = "Mã đăng nhập Mimi English Pet"
    body = (
        f"Mã đăng nhập của bạn là: {code}\n\n"
        "Mã có hiệu lực trong 10 phút. Nếu bạn không yêu cầu mã này, "
        "hãy bỏ qua email này."
    )

    msg = MIMEText(body, "plain", "utf-8")
    msg["Subject"] = subject
    msg["From"] = from_email
    msg["To"] = email

    with _force_ipv4_dns(), smtplib.SMTP(host, port, timeout=10) as server:
        server.starttls()
        server.login(user, password)
        server.sendmail(from_email, [email], msg.as_string())
