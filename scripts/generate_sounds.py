#!/usr/bin/env python3
"""Tự tổng hợp các file âm thanh hiệu ứng ngắn (.wav) cho app Mimi Pet.

Toàn bộ âm thanh trong file này là sóng sine do script tự tạo ra bằng thư
viện chuẩn của Python (wave/struct/math) - KHÔNG lấy từ nguồn có bản quyền
nào khác, an toàn để dùng trong app.

Chạy: python3 scripts/generate_sounds.py
Kết quả: assets/sounds/correct.wav, wrong.wav, complete.wav, heart_lost.wav,
streak.wav
"""
import math
import os
import struct
import wave

SAMPLE_RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")


def _envelope(i, n, fade_samples):
    """Fade-in/out tuyến tính ở đầu/cuối để tránh tiếng "click" khi bắt đầu/
    kết thúc mỗi nốt (do biên độ nhảy đột ngột từ/về 0)."""
    if n <= 0:
        return 0.0
    fade = min(fade_samples, n // 2) or 1
    if i < fade:
        return i / fade
    if i > n - fade:
        return max(0.0, (n - i) / fade)
    return 1.0


def _tone(freq_start, freq_end, duration_s, volume=0.35):
    """Sinh 1 nốt sine, có thể trượt tần số (glide) từ freq_start -> freq_end
    (đặt 2 giá trị bằng nhau nếu muốn 1 nốt phẳng không trượt)."""
    n = int(SAMPLE_RATE * duration_s)
    fade_samples = int(SAMPLE_RATE * 0.012)
    samples = []
    phase = 0.0
    for i in range(n):
        t = i / n if n > 1 else 0
        freq = freq_start + (freq_end - freq_start) * t
        phase += 2 * math.pi * freq / SAMPLE_RATE
        amp = volume * _envelope(i, n, fade_samples)
        samples.append(amp * math.sin(phase))
    return samples


def _silence(duration_s):
    return [0.0] * int(SAMPLE_RATE * duration_s)


def _write_wav(filename, samples):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, filename)
    with wave.open(path, "w") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            frames += struct.pack("<h", int(clamped * 32767))
        wav_file.writeframes(bytes(frames))
    print(f"wrote {path} ({len(samples) / SAMPLE_RATE:.3f}s)")


def make_correct():
    # 2 nốt vui, đi lên: C6 -> E6.
    samples = _tone(1046.5, 1046.5, 0.11) + _tone(1318.5, 1318.5, 0.16)
    _write_wav("correct.wav", samples)


def make_wrong():
    # 1 nốt trầm, trượt nhẹ xuống - nhẹ nhàng, không gây sợ cho bé.
    samples = _tone(240, 190, 0.28, volume=0.28)
    _write_wav("wrong.wav", samples)


def make_complete():
    # Hợp âm rải đi lên: C5, E5, G5, C6 - cảm giác chiến thắng nhỏ.
    samples = (
        _tone(523.25, 523.25, 0.10)
        + _tone(659.25, 659.25, 0.10)
        + _tone(783.99, 783.99, 0.10)
        + _tone(1046.5, 1046.5, 0.22)
    )
    _write_wav("complete.wav", samples)


def make_heart_lost():
    # 2 nốt đi xuống nhẹ ("boop") - báo hiệu nhưng không quá tiêu cực.
    samples = _tone(659.25, 659.25, 0.09) + _silence(0.02) + _tone(523.25, 493.88, 0.18, volume=0.3)
    _write_wav("heart_lost.wav", samples)


def make_streak():
    # Hợp âm rải đi lên NHANH + cao hơn "complete" (thêm 1 nốt lấp lánh cuối
    # cùng trượt lên) - dùng riêng cho lúc đạt streak MỚI, cần nổi bật/đặc
    # biệt hơn hẳn hiệu ứng "hoàn thành bài" thông thường.
    samples = (
        _tone(523.25, 523.25, 0.08)
        + _tone(659.25, 659.25, 0.08)
        + _tone(783.99, 783.99, 0.08)
        + _tone(1046.5, 1046.5, 0.08)
        + _tone(1318.5, 1567.98, 0.22, volume=0.3)
    )
    _write_wav("streak.wav", samples)


if __name__ == "__main__":
    make_correct()
    make_wrong()
    make_complete()
    make_heart_lost()
    make_streak()
