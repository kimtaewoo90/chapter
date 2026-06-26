#!/usr/bin/env python3
"""CHAPTER 온보딩 — 책장 넘김 Lottie JSON 생성 (Goodreads #3 스타일 참고)."""

from __future__ import annotations

import json
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets/animations/book_page_flip.json"

W, H = 360, 220
FR = 30
DURATION = 150  # 5s loop

PAPER = "#FAF7F2"
PAPER_DARK = "#E8E0D4"
SPINE = "#8B7355"
COVER = "#6E5F52"
INK_MUTED = "#6B6560"
SHADOW = "#2C2824"


def rgba(hex_color: str, alpha: float = 1.0) -> list[float]:
    h = hex_color.lstrip("#")
    return [
        int(h[0:2], 16) / 255,
        int(h[2:4], 16) / 255,
        int(h[4:6], 16) / 255,
        alpha,
    ]


def static_prop(value) -> dict:
    return {"a": 0, "k": value, "ix": 1}


def rect_shape(name: str, width: float, height: float, color: str, radius: float = 3) -> dict:
    return {
        "ty": "gr",
        "nm": name,
        "it": [
            {
                "ty": "rc",
                "d": 1,
                "s": static_prop([width, height]),
                "p": static_prop([width / 2, height / 2]),
                "r": static_prop(radius),
                "nm": f"{name} rect",
            },
            {
                "ty": "fl",
                "c": static_prop(rgba(color)),
                "o": static_prop(100),
                "r": 1,
                "nm": f"{name} fill",
            },
            {"ty": "tr", "p": static_prop([0, 0]), "a": static_prop([0, 0]), "s": static_prop([100, 100]), "r": static_prop(0), "o": static_prop(100)},
        ],
    }


def line_shape(name: str, x: float, y: float, width: float, color: str) -> dict:
    return {
        "ty": "gr",
        "nm": name,
        "it": [
            {
                "ty": "rc",
                "d": 1,
                "s": static_prop([width, 2]),
                "p": static_prop([x + width / 2, y]),
                "r": static_prop(1),
                "nm": name,
            },
            {"ty": "fl", "c": static_prop(rgba(color, 0.35)), "o": static_prop(100), "r": 1, "nm": "fill"},
            {"ty": "tr", "p": static_prop([0, 0]), "a": static_prop([0, 0]), "s": static_prop([100, 100]), "r": static_prop(0), "o": static_prop(100)},
        ],
    }


def shape_layer(
    index: int,
    name: str,
    shapes: list[dict],
    pos: list[float],
    anchor: list[float],
    scale_kf: dict | None = None,
    opacity_kf: dict | None = None,
    rotation_kf: dict | None = None,
) -> dict:
    ks = {
        "o": opacity_kf or static_prop(100),
        "r": rotation_kf or static_prop(0),
        "p": static_prop(pos),
        "a": static_prop(anchor),
        "s": scale_kf or static_prop([100, 100, 100]),
    }
    return {
        "ddd": 0,
        "ind": index,
        "ty": 4,
        "nm": name,
        "sr": 1,
        "ks": ks,
        "ao": 0,
        "shapes": shapes,
        "ip": 0,
        "op": DURATION,
        "st": 0,
        "bm": 0,
    }


def flip_scale_keyframes(start: int, end: int) -> dict:
    mid = start + int((end - start) * 0.48)
    curl = start + int((end - start) * 0.72)
    return {
        "a": 1,
        "k": [
            {"t": start, "s": [100, 100, 100], "i": {"x": [0.35, 0.35, 0.35], "y": [1, 1, 1]}, "o": {"x": [0.65, 0.65, 0.65], "y": [0, 0, 0]}},
            {"t": mid, "s": [12, 102, 100], "i": {"x": [0.35, 0.35, 0.35], "y": [1, 1, 1]}, "o": {"x": [0.65, 0.65, 0.65], "y": [0, 0, 0]}},
            {"t": curl, "s": [-88, 98, 100], "i": {"x": [0.35, 0.35, 0.35], "y": [1, 1, 1]}, "o": {"x": [0.65, 0.65, 0.65], "y": [0, 0, 0]}},
            {"t": end, "s": [-100, 100, 100], "i": {"x": [0.35, 0.35, 0.35], "y": [1, 1, 1]}, "o": {"x": [0.65, 0.65, 0.65], "y": [0, 0, 0]}},
        ],
        "ix": 6,
    }


def flip_lift_keyframes(start: int, end: int, base_y: float) -> dict:
    mid = start + int((end - start) * 0.5)
    return {
        "a": 1,
        "k": [
            {"t": start, "s": [0, base_y, 0], "i": {"x": 0.42, "y": 1}, "o": {"x": 0.58, "y": 0}},
            {"t": mid, "s": [0, base_y - 8, 0], "i": {"x": 0.42, "y": 1}, "o": {"x": 0.58, "y": 0}},
            {"t": end, "s": [0, base_y, 0], "i": {"x": 0.42, "y": 1}, "o": {"x": 0.58, "y": 0}},
        ],
        "ix": 2,
    }


def flip_opacity_keyframes(start: int, end: int, fade_out: int) -> dict:
    return {
        "a": 1,
        "k": [
            {"t": start, "s": 100, "i": {"x": [0.667], "y": [1]}, "o": {"x": [0.333], "y": [0]}},
            {"t": end, "s": 100, "i": {"x": [0.667], "y": [1]}, "o": {"x": [0.333], "y": [0]}},
            {"t": fade_out, "s": 0, "i": {"x": [0.667], "y": [1]}, "o": {"x": [0.333], "y": [0]}},
        ],
        "ix": 11,
    }


def page_shapes(page_w: float, page_h: float, with_lines: bool = True) -> list[dict]:
    shapes = [rect_shape("page", page_w, page_h, PAPER, 4)]
    if with_lines:
        for i in range(4):
            shapes.append(line_shape(f"line{i}", 16, 28 + i * 14, page_w - 32 - i * 8, INK_MUTED))
    # 넘김 그림자 (페이지 오른쪽 가장자리)
    shapes.append(
        {
            "ty": "gr",
            "nm": "edge shade",
            "it": [
                {
                    "ty": "rc",
                    "d": 1,
                    "s": static_prop([18, page_h]),
                    "p": static_prop([page_w - 9, page_h / 2]),
                    "r": static_prop(2),
                    "nm": "shade",
                },
                {"ty": "fl", "c": static_prop(rgba(SPINE, 0.18)), "o": static_prop(100), "r": 1, "nm": "fill"},
                {"ty": "tr", "p": static_prop([0, 0]), "a": static_prop([0, 0]), "s": static_prop([100, 100]), "r": static_prop(0), "o": static_prop(100)},
            ],
        }
    )
    return shapes


def build() -> dict:
    spine_x = 72
    page_w, page_h = 148, 168
    base_y = 108

    layers: list[dict] = []

    # 그림자
    layers.append(
        shape_layer(
            1,
            "shadow",
            [rect_shape("shadow", 200, 14, SHADOW, 7)],
            [spine_x + 96, base_y + page_h / 2 + 10, 0],
            [100, 7, 0],
            opacity_kf=static_prop(14),
        )
    )

    # 등뼈
    layers.append(
        shape_layer(
            2,
            "spine",
            [rect_shape("spine", 10, page_h + 6, SPINE, 2)],
            [spine_x, base_y, 0],
            [5, (page_h + 6) / 2, 0],
        )
    )

    # 왼쪽 쌓인 페이지 (넘긴 뒤)
    for i, (sx, op) in enumerate([(0.92, 55), (0.96, 40)]):
        layers.append(
            shape_layer(
                3 + i,
                f"stack_left_{i}",
                [rect_shape("stack", page_w * 0.48, page_h, PAPER_DARK, 3)],
                [spine_x - 8 - i * 3, base_y + 1, 0],
                [page_w * 0.24, page_h / 2, 0],
                opacity_kf=static_prop(op),
            )
        )

    # 표지 (닫힌 책 느낌)
    layers.append(
        shape_layer(
            5,
            "cover",
            [rect_shape("cover", page_w, page_h, COVER, 4)],
            [spine_x + page_w / 2 + 4, base_y, 0],
            [page_w / 2, page_h / 2, 0],
        )
    )

    # 오른쪽 대기 페이지들
    for i in range(2):
        layers.append(
            shape_layer(
                6 + i,
                f"stack_right_{i}",
                page_shapes(page_w - 4, page_h - 2, with_lines=i == 1),
                [spine_x + page_w / 2 + 6 + i * 2, base_y - i, 0],
                [0, page_h / 2, 0],
            )
        )

    # 넘어가는 페이지 3장 — 순차적으로
    flip_windows = [(8, 48), (52, 92), (96, 136)]
    for idx, (start, end) in enumerate(flip_windows):
        y_off = idx * 1.5
        pos = [spine_x, base_y - y_off, 0]
        anchor = [0, page_h / 2, 0]
        layer = shape_layer(
            8 + idx,
            f"flip_page_{idx}",
            page_shapes(page_w, page_h, with_lines=True),
            pos,
            anchor,
            scale_kf=flip_scale_keyframes(start, end),
            opacity_kf=flip_opacity_keyframes(start, end - 4, end),
        )
        # lift via position keyframes merged into p
        lift = flip_lift_keyframes(start, end, base_y - y_off)
        base_x = spine_x
        lift["k"] = [
            {**kf, "s": [base_x, kf["s"][1], 0]} for kf in lift["k"]
        ]
        layer["ks"]["p"] = lift
        layers.append(layer)

    # curl 하이라이트 (넘김 중에만)
    layers.append(
        shape_layer(
            11,
            "curl_highlight",
            [rect_shape("curl", 6, page_h * 0.82, "#FFFFFF", 2)],
            [spine_x + page_w * 0.55, base_y, 0],
            [3, page_h * 0.41, 0],
            opacity_kf={
                "a": 1,
                "k": [
                    {"t": 8, "s": 0, "i": {"x": [0.667], "y": [1]}, "o": {"x": [0.333], "y": [0]}},
                    {"t": 24, "s": 28, "i": {"x": [0.667], "y": [1]}, "o": {"x": [0.333], "y": [0]}},
                    {"t": 40, "s": 0, "i": {"x": [0.667], "y": [1]}, "o": {"x": [0.333], "y": [0]}},
                    {"t": 52, "s": 0, "i": {"x": [0.667], "y": [1]}, "o": {"x": [0.333], "y": [0]}},
                    {"t": 68, "s": 28, "i": {"x": [0.667], "y": [1]}, "o": {"x": [0.333], "y": [0]}},
                    {"t": 84, "s": 0, "i": {"x": [0.667], "y": [1]}, "o": {"x": [0.333], "y": [0]}},
                    {"t": 96, "s": 0, "i": {"x": [0.667], "y": [1]}, "o": {"x": [0.333], "y": [0]}},
                    {"t": 112, "s": 28, "i": {"x": [0.667], "y": [1]}, "o": {"x": [0.333], "y": [0]}},
                    {"t": 128, "s": 0, "i": {"x": [0.667], "y": [1]}, "o": {"x": [0.333], "y": [0]}},
                ],
                "ix": 11,
            },
        )
    )

    layers.reverse()  # lottie: top layer first

    return {
        "v": "5.7.4",
        "fr": FR,
        "ip": 0,
        "op": DURATION,
        "w": W,
        "h": H,
        "nm": "CHAPTER Book Page Flip",
        "ddd": 0,
        "assets": [],
        "layers": layers,
    }


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    data = build()
    OUT.write_text(json.dumps(data, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
