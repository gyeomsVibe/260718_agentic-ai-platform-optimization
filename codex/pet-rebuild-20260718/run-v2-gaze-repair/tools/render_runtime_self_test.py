"""Render and verify every Codex v2 Pet animation from an installed atlas."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


CELL_W = 192
CELL_H = 208
COLS = 8
ROWS = 11
STEP_MS = 100
LOOP_MS = 6600

STATES = (
    ("idle", 0, (280, 110, 110, 140, 140, 320)),
    ("running-right", 1, (120, 120, 120, 120, 120, 120, 120, 220)),
    ("running-left", 2, (120, 120, 120, 120, 120, 120, 120, 220)),
    ("waving", 3, (140, 140, 140, 280)),
    ("jumping", 4, (140, 140, 140, 140, 280)),
    ("failed", 5, (140, 140, 140, 140, 140, 140, 140, 240)),
    ("waiting", 6, (150, 150, 150, 150, 150, 260)),
    ("running", 7, (120, 120, 120, 120, 120, 220)),
    ("review", 8, (150, 150, 150, 150, 150, 280)),
)

DISPLAY_NAMES = {
    "idle": "idle / basic",
    "running-right": "move-right",
    "running-left": "move-left",
    "waving": "waving",
    "jumping": "jumping",
    "failed": "failed",
    "waiting": "waiting",
    "running": "working (runtime key: running)",
    "review": "review / completed",
}


def crop_cell(atlas: Image.Image, row: int, column: int) -> Image.Image:
    return atlas.crop(
        (column * CELL_W, row * CELL_H, (column + 1) * CELL_W, (row + 1) * CELL_H)
    ).convert("RGBA")


def frame_at(frames: list[Image.Image], durations: tuple[int, ...], time_ms: int) -> Image.Image:
    position = time_ms % sum(durations)
    elapsed = 0
    for frame, duration in zip(frames, durations, strict=True):
        elapsed += duration
        if position < elapsed:
            return frame
    return frames[-1]


def visible_hash(frame: Image.Image) -> str:
    return hashlib.sha256(frame.tobytes()).hexdigest()


def changed_pixels(first: Image.Image, second: Image.Image) -> int:
    diff = ImageChops.difference(first, second)
    return sum(1 for pixel in diff.getdata() if pixel != (0, 0, 0, 0))


def make_standard_apng(atlas: Image.Image, output: Path) -> None:
    card_w, card_h = CELL_W, CELL_H + 24
    gap = 8
    canvas_w = card_w * 3 + gap * 4
    canvas_h = card_h * 3 + gap * 4
    prepared = []
    for name, row, durations in STATES:
        prepared.append((name, durations, [crop_cell(atlas, row, i) for i in range(len(durations))]))

    pages: list[Image.Image] = []
    for time_ms in range(0, LOOP_MS, STEP_MS):
        page = Image.new("RGBA", (canvas_w, canvas_h), (24, 24, 24, 255))
        draw = ImageDraw.Draw(page)
        for index, (name, durations, frames) in enumerate(prepared):
            grid_x, grid_y = index % 3, index // 3
            x = gap + grid_x * (card_w + gap)
            y = gap + grid_y * (card_h + gap)
            draw.rounded_rectangle(
                (x, y, x + card_w - 1, y + card_h - 1),
                radius=8,
                fill=(38, 38, 38, 255),
                outline=(78, 78, 78, 255),
            )
            page.alpha_composite(frame_at(frames, durations, time_ms), (x, y + 24))
            draw.text(
                (x + 7, y + 6),
                f"row {index}  {DISPLAY_NAMES[name]}",
                fill=(240, 240, 240, 255),
            )
        pages.append(page)

    output.parent.mkdir(parents=True, exist_ok=True)
    pages[0].save(
        output,
        save_all=True,
        append_images=pages[1:],
        duration=STEP_MS,
        loop=0,
        disposal=2,
        blend=0,
        optimize=False,
    )


def make_direction_apng(atlas: Image.Image, output: Path) -> None:
    frames = [crop_cell(atlas, 9, column) for column in range(8)]
    frames.extend(crop_cell(atlas, 10, column) for column in range(8))
    labels = (
        "000 up", "022.5", "045", "067.5", "090 right", "112.5", "135", "157.5",
        "180 down", "202.5", "225", "247.5", "270 left", "292.5", "315", "337.5",
    )
    pages: list[Image.Image] = []
    for frame, label in zip(frames, labels, strict=True):
        page = Image.new("RGBA", (CELL_W, CELL_H + 28), (24, 24, 24, 255))
        page.alpha_composite(frame, (0, 28))
        ImageDraw.Draw(page).text((7, 7), f"look {label}", fill=(240, 240, 240, 255))
        pages.append(page)
    output.parent.mkdir(parents=True, exist_ok=True)
    pages[0].save(
        output,
        save_all=True,
        append_images=pages[1:],
        duration=300,
        loop=0,
        disposal=2,
        blend=0,
        optimize=False,
    )


def make_html(output: Path) -> None:
    state_json = json.dumps(
        {
            name: {
                "row": row,
                "durations": durations,
                "label": DISPLAY_NAMES[name],
            }
            for name, row, durations in STATES
        }
    )
    html = f"""<!doctype html>
<html lang=\"ko\"><meta charset=\"utf-8\"><title>Gyeom v2 motion self-test</title>
<style>
body{{margin:0;background:#181818;color:#eee;font:14px system-ui;padding:24px}}
h1{{margin:0 0 8px}}p{{color:#aaa}}.grid{{display:grid;grid-template-columns:repeat(3,220px);gap:14px}}
.card{{background:#262626;border:1px solid #444;border-radius:12px;padding:10px;text-align:center}}
.sprite{{width:192px;height:208px;margin:auto;background-image:url('../../spritesheet.webp');background-size:800% 1100%;image-rendering:auto}}
.name{{font-weight:700;margin-bottom:6px}}.hover-test{{margin-top:24px;width:220px}}
.ok{{color:#73d99a}}button{{background:#3b82f6;color:white;border:0;border-radius:8px;padding:8px 12px;cursor:pointer}}
</style>
<h1>Gyeom v2 — 9 motion live self-test</h1>
<p class=\"ok\">설치본과 동일한 SHA-256 자산 · Codex 앱 행/프레임 타이밍</p>
<button id=\"replay\">모두 처음부터 재생</button><div class=\"grid\" id=\"grid\"></div>
<div class=\"card hover-test\"><div class=\"name\">현재 앱 hover → jumping 트리거</div><div class=\"sprite\" id=\"hoverSprite\"></div><p>캐릭터 위에 마우스를 올려 점프 확인</p></div>
<script>
const states={state_json}; let started=performance.now(); const grid=document.querySelector('#grid');
const pos=(row,col)=>`${{col/7*100}}% ${{row/10*100}}%`;
function frameAt(durations,ms){{let t=ms%durations.reduce((a,b)=>a+b,0);for(let i=0;i<durations.length;i++){{if(t<durations[i])return i;t-=durations[i]}}return durations.length-1}}
for(const [name,cfg] of Object.entries(states)){{const card=document.createElement('div');card.className='card';card.innerHTML=`<div class=\"name\">row ${{cfg.row}} · ${{cfg.label}}</div><div class=\"sprite\"></div>`;grid.append(card);cfg.el=card.querySelector('.sprite')}}
function tick(now){{for(const cfg of Object.values(states))cfg.el.style.backgroundPosition=pos(cfg.row,frameAt(cfg.durations,now-started));requestAnimationFrame(tick)}}requestAnimationFrame(tick);
document.querySelector('#replay').onclick=()=>started=performance.now();
const hover=document.querySelector('#hoverSprite');let hoverStart=0;function hoverTick(now){{const jumping=hover.matches(':hover');if(jumping&&hoverStart===0)hoverStart=now;if(!jumping)hoverStart=0;const cfg=jumping?states.jumping:states.idle;hover.style.backgroundPosition=pos(cfg.row,frameAt(cfg.durations,jumping?now-hoverStart:now));requestAnimationFrame(hoverTick)}}requestAnimationFrame(hoverTick);
</script></html>"""
    output.write_text(html, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("atlas", type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--candidate-atlas", type=Path)
    args = parser.parse_args()

    atlas_bytes = args.atlas.read_bytes()
    atlas = Image.open(args.atlas).convert("RGBA")
    if atlas.size != (CELL_W * COLS, CELL_H * ROWS):
        raise SystemExit(f"invalid atlas size: {atlas.size}")

    state_results = []
    overall_ok = True
    for name, row, durations in STATES:
        frames = [crop_cell(atlas, row, column) for column in range(len(durations))]
        hashes = [visible_hash(frame) for frame in frames]
        nonempty = [frame.getchannel("A").getbbox() is not None for frame in frames]
        transitions = [
            changed_pixels(frames[index], frames[(index + 1) % len(frames)])
            for index in range(len(frames))
        ]
        occupied_extra_cells = [
            column
            for column in range(len(durations), COLS)
            if crop_cell(atlas, row, column).getchannel("A").getbbox() is not None
        ]
        repeated_transitions = [
            index for index, value in enumerate(transitions) if value == 0
        ]
        # A deliberate hold/return frame is valid animation data. Fail only when
        # a required cell is empty or the whole row has no visible motion.
        row_ok = all(nonempty) and len(set(hashes)) >= 2 and any(value > 0 for value in transitions)
        overall_ok &= row_ok
        state_results.append(
            {
                "state": name,
                "row": row,
                "frames": len(frames),
                "all_used_frames_nonempty": all(nonempty),
                "unique_frames": len(set(hashes)),
                "transition_changed_pixels": transitions,
                "occupied_extra_cells": occupied_extra_cells,
                "repeated_transition_indices": repeated_transitions,
                "warnings": [
                    *( [f"intentional/review-needed repeated transitions: {repeated_transitions}"] if repeated_transitions else [] ),
                    *( [f"extra occupied cells outside runtime range: {occupied_extra_cells}"] if occupied_extra_cells else [] ),
                ],
                "ok": row_ok,
            }
        )

    look_frames = [crop_cell(atlas, row, column) for row in (9, 10) for column in range(8)]
    look_hashes = [visible_hash(frame) for frame in look_frames]
    look_transitions = [
        changed_pixels(look_frames[index], look_frames[(index + 1) % len(look_frames)])
        for index in range(len(look_frames))
    ]
    look_ok = all(frame.getchannel("A").getbbox() is not None for frame in look_frames)
    look_ok &= len(set(look_hashes)) == 16 and all(value > 0 for value in look_transitions)
    overall_ok &= look_ok

    args.output_dir.mkdir(parents=True, exist_ok=True)
    standard_apng = args.output_dir / "all-standard-motions.png"
    direction_apng = args.output_dir / "all-look-directions.png"
    html = args.output_dir / "all-motions-live.html"
    make_standard_apng(atlas, standard_apng)
    make_direction_apng(atlas, direction_apng)
    make_html(html)

    source_hash = hashlib.sha256(atlas_bytes).hexdigest().upper()
    candidate_hash = None
    candidate_match = None
    if args.candidate_atlas is not None:
        candidate_hash = hashlib.sha256(args.candidate_atlas.read_bytes()).hexdigest().upper()
        candidate_match = source_hash == candidate_hash
        overall_ok &= candidate_match

    report = {
        "ok": overall_ok,
        "installed_atlas": str(args.atlas.resolve()),
        "installed_sha256": source_hash,
        "candidate_sha256": candidate_hash,
        "installed_matches_candidate": candidate_match,
        "atlas": {"width": atlas.width, "height": atlas.height, "columns": COLS, "rows": ROWS},
        "states": state_results,
        "look_directions": {
            "frames": 16,
            "unique_frames": len(set(look_hashes)),
            "transition_changed_pixels": look_transitions,
            "ok": look_ok,
        },
        "artifacts": {
            "standard_apng": str(standard_apng.resolve()),
            "direction_apng": str(direction_apng.resolve()),
            "interactive_html": str(html.resolve()),
        },
    }
    report_path = args.output_dir / "motion-self-test.json"
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"ok": overall_ok, "report": str(report_path), "states": len(state_results), "look_frames": 16}))
    if not overall_ok:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
