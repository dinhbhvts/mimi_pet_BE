"""Gửi email mã đăng nhập qua SMTP thuần (chạy được với Gmail App Password,
miễn phí, không cần đăng ký dịch vụ email thứ 3).

Nếu CHƯA cấu hình SMTP (ví dụ lúc dev cục bộ), in mã ra console thay vì gửi
thật - vẫn test được trọn luồng đăng nhập mà không cần tài khoản email.
"""
import os
import smtplib
from email.mime.text import MIMEText


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

    with smtplib.SMTP(host, port, timeout=10) as server:
        server.starttls()
        server.login(user, password)
        server.sendmail(from_email, [email], msg.as_string())
