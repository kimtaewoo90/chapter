#!/usr/bin/env python3
"""App Store Connect용 iPhone 6.7\" (1290×2796) 스크린샷 생성."""

from __future__ import annotations

import math
import random
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = Path(__file__).resolve().parent / "iphone-6.7"
ICON_PATH = ROOT / "assets/images/app_icon.png"

# App Store 6.7" portrait
W, H = 1290, 2796

# AppTheme
PAPER = (245, 240, 232)
PAPER_DARK = (232, 224, 212)
INK = (44, 40, 36)
INK_MUTED = (107, 101, 96)
ACCENT = (139, 115, 85)
ACCENT_LIGHT = (196, 168, 130)
LINE_PINK = (232, 180, 180)
DIARY_INK = (61, 58, 80)
WHITE = (255, 255, 255)
SLAB = (58, 52, 46)


@dataclass
class Shot:
    filename: str
    headline: str
    subhead: str
    screen: str


SHOTS: list[Shot] = [
    Shot(
        "01_feed_book.png",
        "당신의 이야기를,\n한 권의 책으로",
        "옆으로 넘기며 읽는 나만의 일기책",
        "feed",
    ),
    Shot(
        "02_record.png",
        "하루 한 페이지",
        "사진 · 무드 · 한 줄 — 가볍게 기록",
        "record",
    ),
    Shot(
        "03_story_arc.png",
        "Story Arc",
        "AI가 이어 주는 이야기, 조용히 챕터가 완성돼요",
        "chapter",
    ),
    Shot(
        "04_ai_insight.png",
        "AI가 함께",
        "무드 추천 · Daily Insight · 월간 리포트",
        "ai",
    ),
    Shot(
        "05_my_book.png",
        "한 해, 한 권",
        "365일이 모이면 조용히 한 권의 책이 됩니다",
        "book",
    ),
    Shot(
        "06_backup_fonts.png",
        "내 일기, 안전하게",
        "Apple · Google 백업 · 8종 글꼴 커스터마이징",
        "more",
    ),
]


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        ("/System/Library/Fonts/AppleSDGothicNeo.ttc", 6 if bold else 0),
        ("/System/Library/Fonts/Supplemental/AppleGothic.ttf", None),
        ("/Library/Fonts/Arial Unicode.ttf", None),
    ]
    for path, index in candidates:
        p = Path(path)
        if not p.exists():
            continue
        try:
            if index is not None:
                return ImageFont.truetype(str(p), size=size, index=index)
            return ImageFont.truetype(str(p), size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def paper_gradient(size: tuple[int, int]) -> Image.Image:
    img = Image.new("RGB", size)
    px = img.load()
    w, h = size
    for y in range(h):
        t = y / max(h - 1, 1)
        r = lerp(PAPER[0], PAPER_DARK[0], t * 0.55)
        g = lerp(PAPER[1], PAPER_DARK[1], t * 0.55)
        b = lerp(PAPER[2], PAPER_DARK[2], t * 0.55)
        for x in range(w):
            n = random.randint(-3, 3)
            px[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n)), max(0, min(255, b + n)))
    return img.filter(ImageFilter.GaussianBlur(radius=0.6))


def draw_centered_multiline(
    draw: ImageDraw.ImageDraw,
    text: str,
    box: tuple[int, int, int, int],
    font: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int],
    line_gap: int = 12,
) -> None:
    lines = text.split("\n")
    line_heights = []
    line_widths = []
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        line_heights.append(bbox[3] - bbox[1])
        line_widths.append(bbox[2] - bbox[0])
    total_h = sum(line_heights) + line_gap * (len(lines) - 1)
    x0, y0, x1, y1 = box
    y = y0 + (y1 - y0 - total_h) // 2
    for i, line in enumerate(lines):
        x = x0 + (x1 - x0 - line_widths[i]) // 2
        draw.text((x, y), line, font=font, fill=fill)
        y += line_heights[i] + line_gap


def rounded_rect(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int, int, int],
    radius: int,
    fill: tuple[int, int, int] | None = None,
    outline: tuple[int, int, int] | None = None,
    width: int = 1,
) -> None:
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def draw_status_bar(draw: ImageDraw.ImageDraw, x: int, y: int, w: int) -> None:
    draw.text((x + 28, y + 18), "9:41", font=load_font(26), fill=INK)
    cx = x + w - 120
    for i, bw in enumerate((18, 24, 30)):
        draw.rounded_rectangle((cx + i * 34, y + 26, cx + i * 34 + bw, y + 38), radius=4, fill=INK_MUTED)


def draw_bottom_bar(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, selected: int) -> None:
    h = 56
    rounded_rect(draw, (x + 14, y, x + w - 14, y + 48), 14, fill=SLAB)
    labels = [("나의 책", 0), ("더보기", 2)]
    slot_w = (w - 14 * 2 - 52) // 2
    for label, idx in labels:
        lx = x + 14 + (0 if idx == 0 else slot_w + 52)
        color = ACCENT_LIGHT if selected == idx else (180, 175, 168)
        draw.text((lx + slot_w // 2 - 40, y + 14), label, font=load_font(22), fill=color)
    bx = x + w // 2 - 26
    rounded_rect(draw, (bx, y - 18, bx + 52, y + 48), 10, fill=ACCENT)
    draw.text((bx + 10, y + 2), "기록", font=load_font(20, bold=True), fill=WHITE)


def draw_lined_page(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int) -> None:
    rounded_rect(draw, (x, y, x + w, y + h), 8, fill=(250, 246, 238))
    draw.rectangle((x, y, x + 14, y + h), fill=(52, 48, 44))
    for i in range(8):
        ly = y + 80 + i * 46
        draw.line((x + 36, ly, x + w - 24, ly), fill=(*LINE_PINK[:2], 180), width=1)


def draw_feed_screen(draw: ImageDraw.ImageDraw, ox: int, oy: int, ow: int, oh: int) -> None:
    draw.text((ox + 36, oy + 72), "나의 책", font=load_font(38, bold=True), fill=INK)
    draw.text((ox + 36, oy + 118), "옆으로 넘기며 읽어요", font=load_font(24), fill=INK_MUTED)
    draw.text((ox + ow - 100, oy + 88), "3 / 12", font=load_font(24, bold=True), fill=ACCENT)

    whisper_y = oy + 150
    rounded_rect(draw, (ox + 28, whisper_y, ox + ow - 28, whisper_y + 72), 14, fill=WHITE)
    draw.text((ox + 48, whisper_y + 22), "✦  「봄의 시작」이 쓰이고 있어요…", font=load_font(22), fill=ACCENT)

    page_x, page_y = ox + 48, oy + 250
    page_w, page_h = ow - 96, oh - 430
    draw_lined_page(draw, page_x, page_y, page_w, page_h)
    draw.text((page_x + 28, page_y + 28), "2026년 6월 3일 · 화요일", font=load_font(22), fill=INK_MUTED)
    draw.text((page_x + 28, page_y + 68), "☀️  맑음  ·  기분 좋은 화요일", font=load_font(24), fill=INK)
    photo_y = page_y + 110
    rounded_rect(draw, (page_x + 28, photo_y, page_x + page_w - 28, photo_y + 220), 12, fill=ACCENT_LIGHT)
    draw.text((page_x + page_w // 2 - 80, photo_y + 90), "📷  오늘의 사진", font=load_font(26), fill=WHITE)
    diary = "카페 창가에 앉아 책을 읽었다.\n햇살이 종이 위에\n따뜻하게 내려앉았다."
    draw_centered_multiline(
        draw,
        diary,
        (page_x + 20, photo_y + 240, page_x + page_w - 20, page_y + page_h - 20),
        load_font(30),
        DIARY_INK,
        8,
    )
    draw_bottom_bar(draw, ox, oy + oh - 110, ow, 0)


def draw_record_screen(draw: ImageDraw.ImageDraw, ox: int, oy: int, ow: int, oh: int) -> None:
    draw.text((ox + ow // 2 - 50, oy + 72), "기록", font=load_font(34, bold=True), fill=INK)
    draw.text((ox + 36, oy + 130), "6월 3일 · ☀️ 24°  맑음", font=load_font(24), fill=INK_MUTED)

    rounded_rect(draw, (ox + 28, oy + 175, ox + ow - 28, oy + 340), 16, fill=WHITE)
    rounded_rect(draw, (ox + 44, oy + 195, ox + 240, oy + 320), 12, fill=ACCENT_LIGHT)
    draw.text((ox + 260, oy + 210), "사진 추가", font=load_font(26, bold=True), fill=INK)
    draw.text((ox + 260, oy + 252), "오늘의 순간을 담아보세요", font=load_font(22), fill=INK_MUTED)

    draw.text((ox + 36, oy + 365), "오늘의 무드", font=load_font(24, bold=True), fill=INK)
    moods = ["😊", "😌", "🥰", "🤔", "😢"]
    mx = ox + 36
    for m in moods:
        rounded_rect(draw, (mx, oy + 405, mx + 72, oy + 477), 36, fill=WHITE, outline=ACCENT_LIGHT, width=2)
        draw.text((mx + 18, oy + 418), m, font=load_font(34), fill=INK)
        mx += 88
    draw.text((ox + 36, oy + 495), "AI 추천 · 😌 여유로운", font=load_font(20), fill=ACCENT)

    page_y = oy + 540
    draw_lined_page(draw, ox + 28, page_y, ow - 56, oh - page_y + oy - 130)
    sample = "오늘은 조용히\n나만의 속도로\n하루를 마무리했다."
    draw.text((ox + 64, page_y + 40), sample, font=load_font(32), fill=DIARY_INK)

    save_y = oy + oh - 200
    rounded_rect(draw, (ox + 36, save_y, ox + ow - 36, save_y + 64), 16, fill=ACCENT)
    draw.text((ox + ow // 2 - 36, save_y + 18), "저장", font=load_font(28, bold=True), fill=WHITE)
    draw_bottom_bar(draw, ox, oy + oh - 110, ow, 1)


def draw_chapter_screen(draw: ImageDraw.ImageDraw, ox: int, oy: int, ow: int, oh: int) -> None:
    draw.text((ox + 36, oy + 72), "완성된 챕터", font=load_font(36, bold=True), fill=INK)
    card_y = oy + 160
    rounded_rect(draw, (ox + 28, card_y, ox + ow - 28, card_y + 420), 20, fill=WHITE)
    draw.text((ox + 56, card_y + 36), "Chapter 3", font=load_font(24, bold=True), fill=ACCENT)
    draw.text((ox + 56, card_y + 72), "봄의 시작", font=load_font(40, bold=True), fill=INK)
    draw.text((ox + 56, card_y + 130), "3월 12일 — 4월 8일  ·  28일", font=load_font(22), fill=INK_MUTED)
    arc = "카페, 산책, 새로운 취미.\n작은 변화들이 모여\n따뜻한 한 챕터가 되었어요."
    draw_centered_multiline(draw, arc, (ox + 56, card_y + 170, ox + ow - 56, card_y + 320), load_font(28), DIARY_INK, 10)
    rounded_rect(draw, (ox + 56, card_y + 340, ox + ow - 56, card_y + 396), 12, fill=PAPER)
    draw.text((ox + 80, card_y + 356), "✦ Story Arc · 5개의 일기가 이어졌어요", font=load_font(22), fill=ACCENT)

    overlay_y = oy + 620
    rounded_rect(draw, (ox + 20, overlay_y, ox + ow - 20, overlay_y + 520), 24, fill=(44, 40, 36))
    draw.text((ox + 56, overlay_y + 48), "챕터가 완성됐어요", font=load_font(34, bold=True), fill=WHITE)
    draw.text((ox + 56, overlay_y + 110), "「봄의 시작」", font=load_font(42, bold=True), fill=ACCENT_LIGHT)
    draw.text((ox + 56, overlay_y + 180), "당신의 이야기가\n한 권 더 두꺼워졌어요.", font=load_font(28), fill=(220, 215, 208))
    rounded_rect(draw, (ox + 56, overlay_y + 400, ox + ow - 56, overlay_y + 468), 14, fill=ACCENT)
    draw.text((ox + ow // 2 - 60, overlay_y + 418), "챕터 열어보기", font=load_font(26, bold=True), fill=WHITE)
    draw_bottom_bar(draw, ox, oy + oh - 110, ow, 2)


def draw_ai_screen(draw: ImageDraw.ImageDraw, ox: int, oy: int, ow: int, oh: int) -> None:
    draw.text((ox + 36, oy + 72), "Daily Insight", font=load_font(36, bold=True), fill=INK)
    draw.text((ox + 36, oy + 118), "오늘의 일기에서", font=load_font(24), fill=INK_MUTED)

    card1_y = oy + 170
    rounded_rect(draw, (ox + 28, card1_y, ox + ow - 28, card1_y + 280), 18, fill=WHITE)
    draw.text((ox + 56, card1_y + 32), "✨ AI 분석", font=load_font(24, bold=True), fill=ACCENT)
    insight = "최근 기록에서 「여유」와\n「감사」가 자주 보여요.\n스스로를 돌보는 시간이\n늘고 있어요."
    draw.text((ox + 56, card1_y + 80), insight, font=load_font(28), fill=DIARY_INK)

    card2_y = oy + 480
    rounded_rect(draw, (ox + 28, card2_y, ox + ow - 28, card2_y + 320), 18, fill=WHITE)
    draw.text((ox + 56, card2_y + 28), "월간 리포트", font=load_font(28, bold=True), fill=INK)
    draw.text((ox + 56, card2_y + 78), "Story Arc · 4개 주제", font=load_font(22), fill=ACCENT)
    bars = [("일상", 0.85), ("관계", 0.62), ("성장", 0.48), ("휴식", 0.71)]
    by = card2_y + 130
    for label, val in bars:
        draw.text((ox + 56, by), label, font=load_font(22), fill=INK_MUTED)
        bx = ox + 160
        rounded_rect(draw, (bx, by + 6, bx + 420, by + 28), 8, fill=PAPER)
        rounded_rect(draw, (bx, by + 6, bx + int(420 * val), by + 28), 8, fill=ACCENT_LIGHT)
        by += 48

    card3_y = oy + 830
    rounded_rect(draw, (ox + 28, card3_y, ox + ow - 28, card3_y + 200), 18, fill=(255, 255, 255))
    draw.text((ox + 56, card3_y + 36), "사진만 올려도 AI 일기 생성", font=load_font(26, bold=True), fill=INK)
    draw.text((ox + 56, card3_y + 88), "Gemini가 무드와 한 줄을 제안해요", font=load_font(22), fill=INK_MUTED)
    draw_bottom_bar(draw, ox, oy + oh - 110, ow, 2)


def draw_book_screen(draw: ImageDraw.ImageDraw, ox: int, oy: int, ow: int, oh: int) -> None:
    draw.text((ox + 36, oy + 72), "내 책", font=load_font(36, bold=True), fill=INK)
    draw.text((ox + 36, oy + 118), "2026 · 한 해를 책으로", font=load_font(24), fill=INK_MUTED)

    book_x, book_y = ox + ow // 2 - 140, oy + 200
    rounded_rect(draw, (book_x, book_y, book_x + 280, book_y + 380), 8, fill=ACCENT)
    rounded_rect(draw, (book_x + 12, book_y + 12, book_x + 268, book_y + 368), 4, fill=PAPER)
    draw.text((book_x + 48, book_y + 140), "2026", font=load_font(48, bold=True), fill=INK)
    draw.text((book_x + 72, book_y + 200), "나의 책", font=load_font(28), fill=ACCENT)

    draw.text((ox + ow // 2 - 120, oy + 620), "올해 진행률  42%", font=load_font(32, bold=True), fill=INK)
    rounded_rect(draw, (ox + 56, oy + 680, ox + ow - 56, oy + 708), 8, fill=PAPER)
    rounded_rect(draw, (ox + 56, oy + 680, ox + 56 + int((ow - 112) * 0.42), oy + 708), 8, fill=ACCENT)

    stats_y = oy + 760
    for i, (label, val) in enumerate([("기록한 날", "87"), ("사진", "124"), ("챕터", "3")]):
        cx = ox + 56 + i * ((ow - 112) // 3)
        rounded_rect(draw, (cx, stats_y, cx + (ow - 140) // 3, stats_y + 120), 14, fill=WHITE)
        draw.text((cx + 24, stats_y + 24), label, font=load_font(22), fill=INK_MUTED)
        draw.text((cx + 24, stats_y + 58), val, font=load_font(36, bold=True), fill=ACCENT)

    draw.text((ox + 56, oy + 930), "완성된 챕터", font=load_font(26, bold=True), fill=INK)
    chapters = ["따뜻한 겨울", "새 학기", "봄의 시작"]
    cy = oy + 980
    for ch in chapters:
        rounded_rect(draw, (ox + 28, cy, ox + ow - 28, cy + 72), 14, fill=WHITE)
        draw.text((ox + 56, cy + 22), f"📖  {ch}", font=load_font(24), fill=INK)
        cy += 88
    draw_bottom_bar(draw, ox, oy + oh - 110, ow, 2)


def draw_more_screen(draw: ImageDraw.ImageDraw, ox: int, oy: int, ow: int, oh: int) -> None:
    draw.text((ox + ow // 2 - 50, oy + 72), "더보기", font=load_font(34, bold=True), fill=INK)

    rounded_rect(draw, (ox + 28, oy + 130, ox + ow - 28, oy + 280), 18, fill=WHITE)
    draw.text((ox + 56, oy + 158), "87일  ·  124장  ·  챕터 3", font=load_font(24, bold=True), fill=INK)
    draw.text((ox + 56, oy + 200), "한 해 진행률 42%", font=load_font(22), fill=ACCENT)
    rounded_rect(draw, (ox + 56, oy + 238, ox + ow - 56, oy + 258), 6, fill=PAPER)
    rounded_rect(draw, (ox + 56, oy + 238, ox + 56 + int((ow - 112) * 0.42), oy + 258), 6, fill=ACCENT_LIGHT)

    tiles = [
        ("☁️", "백업 · 다른 기기", "Apple · Google 로그인"),
        ("🔤", "글꼴 설정", "앱 UI · 일기 본문 8종"),
        ("🔔", "알림", "매일 일기 리마인더"),
        ("📅", "캘린더", "기록한 날을 한눈에"),
    ]
    ty = oy + 310
    for icon, title, sub in tiles:
        rounded_rect(draw, (ox + 28, ty, ox + ow - 28, ty + 96), 14, fill=WHITE)
        draw.text((ox + 52, ty + 28), icon, font=load_font(28), fill=INK)
        draw.text((ox + 100, ty + 22), title, font=load_font(26, bold=True), fill=INK)
        draw.text((ox + 100, ty + 56), sub, font=load_font(20), fill=INK_MUTED)
        ty += 112

    font_y = oy + 780
    draw.text((ox + 36, font_y), "일기 글꼴 미리보기", font=load_font(24, bold=True), fill=INK)
    samples = [("가게우", "오늘도 수고했어"), ("푸어스토리", "조용한 밤"), ("고운바탕", "한 페이지")]
    sx = ox + 36
    for name, text in samples:
        rounded_rect(draw, (sx, font_y + 44, sx + 200, font_y + 140), 12, fill=PAPER)
        draw.text((sx + 16, font_y + 58), name, font=load_font(18), fill=ACCENT)
        draw.text((sx + 16, font_y + 88), text, font=load_font(22), fill=DIARY_INK)
        sx += 220
    draw_bottom_bar(draw, ox, oy + oh - 110, ow, 2)


SCREEN_DRAWERS = {
    "feed": draw_feed_screen,
    "record": draw_record_screen,
    "chapter": draw_chapter_screen,
    "ai": draw_ai_screen,
    "book": draw_book_screen,
    "more": draw_more_screen,
}


def draw_phone(canvas: ImageDraw.ImageDraw, cx: int, cy: int, pw: int, ph: int, screen: str) -> None:
    frame = 18
    rounded_rect(canvas, (cx, cy, cx + pw, cy + ph), 56, fill=(20, 18, 16), outline=(60, 55, 50), width=3)
    inner = (cx + frame, cy + frame, cx + pw - frame, cy + ph - frame)
    rounded_rect(canvas, inner, 44, fill=PAPER)
    ox, oy, x1, y1 = inner
    ow, oh = x1 - ox, y1 - oy
    draw_status_bar(canvas, ox, oy, ow)
    SCREEN_DRAWERS[screen](canvas, ox, oy, ow, oh)


def compose_shot(shot: Shot) -> Image.Image:
    random.seed(shot.filename)
    img = paper_gradient((W, H))
    draw = ImageDraw.Draw(img)

    if ICON_PATH.exists():
        icon = Image.open(ICON_PATH).convert("RGBA")
        icon = icon.resize((88, 88), Image.Resampling.LANCZOS)
        mask = Image.new("L", (88, 88), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, 88, 88), 20, fill=255)
        icon.putalpha(mask)
        img.paste(icon, (W - 120, 56), icon)

    draw.text((72, 72), "챕터", font=load_font(32, bold=True), fill=ACCENT)
    draw_centered_multiline(draw, shot.headline, (60, 130, W - 60, 380), load_font(58, bold=True), INK, 16)
    draw_centered_multiline(draw, shot.subhead, (80, 390, W - 80, 480), load_font(30), INK_MUTED, 8)

    pw, ph = 920, 1980
    px, py = (W - pw) // 2, 520
    draw_phone(draw, px, py, pw, ph, shot.screen)

    draw.text((W // 2 - 180, H - 72), "Chapter · 내인생의 챕터", font=load_font(24), fill=INK_MUTED)
    return img


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for shot in SHOTS:
        out = OUT_DIR / shot.filename
        img = compose_shot(shot)
        img.save(out, format="PNG", optimize=True)
        print(f"✓ {out} ({W}×{H})")
    print(f"\n완료: {len(SHOTS)}장 → {OUT_DIR}")


if __name__ == "__main__":
    main()
