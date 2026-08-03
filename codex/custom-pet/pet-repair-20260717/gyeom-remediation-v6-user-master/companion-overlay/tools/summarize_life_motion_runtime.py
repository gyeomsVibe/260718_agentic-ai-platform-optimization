"""Summarize a completed Companion runtime capture using overlay event timestamps."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageDraw


REQUIRED_STATES = (
    "idle-breathe",
    "idle-look",
    "idle-stretch",
    "idle-yawn",
    "waving",
    "review",
)


def parse_time(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(timezone.utc)


def state_at(moment: datetime, events: list[dict[str, object]]) -> str:
    state = "idle-breathe"
    for event in events:
        if parse_time(str(event["atUtc"])) > moment:
            break
        kind = str(event["kind"])
        if kind in {"personality-action", "external-state"}:
            requested = str(event["state"])
            state = "idle-breathe" if requested == "idle" else requested
        elif kind in {"clip-complete", "return-to-idle"}:
            state = "idle-breathe"
    return state


def make_contact_sheet(records: list[dict[str, object]], output: Path) -> None:
    selected: list[dict[str, object]] = []
    for state in REQUIRED_STATES:
        group = [record for record in records if record["state"] == state]
        if not group:
            continue
        indexes = sorted({0, (len(group) - 1) // 2, len(group) - 1})
        selected.extend(group[index] for index in indexes)
    selected.sort(key=lambda record: record["capturedAtUtc"])

    tile_width = max(int(record["width"]) for record in selected)
    tile_height = max(int(record["height"]) for record in selected)
    label_height = 24
    columns = 3
    rows = (len(selected) + columns - 1) // columns
    sheet = Image.new("RGB", (tile_width * columns, (tile_height + label_height) * rows), (34, 34, 34))
    draw = ImageDraw.Draw(sheet)
    started = parse_time(str(records[0]["capturedAtUtc"]))
    for index, record in enumerate(selected):
        column = index % columns
        row = index // columns
        x = column * tile_width
        y = row * (tile_height + label_height)
        elapsed = (parse_time(str(record["capturedAtUtc"])) - started).total_seconds()
        draw.text((x + 5, y + 5), f"{record['state']}  {elapsed:.1f}s", fill=(255, 255, 255))
        with Image.open(str(record["file"])) as opened:
            frame = opened.convert("RGB")
        sheet.paste(frame, (x + (tile_width - frame.width) // 2, y + label_height + tile_height - frame.height))
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)


def make_ab_sheet(baseline: Path, life_sheet: Path, output: Path) -> None:
    with Image.open(baseline) as opened:
        baseline_image = opened.convert("RGB")
    with Image.open(life_sheet) as opened:
        life_image = opened.convert("RGB")
    baseline_idle_height = min(baseline_image.height, 270)
    baseline_idle = baseline_image.crop((0, 0, baseline_image.width, baseline_idle_height))
    width = max(baseline_idle.width, life_image.width)
    heading = 34
    sheet = Image.new("RGB", (width, heading * 2 + baseline_idle.height + life_image.height), (242, 242, 242))
    draw = ImageDraw.Draw(sheet)
    draw.text((8, 10), "A - previous stabilized Companion (idle sample)", fill=(20, 20, 20))
    sheet.paste(baseline_idle, (0, heading))
    life_y = heading + baseline_idle.height
    draw.text((8, life_y + 10), "B - life-motion Companion (60-second runtime samples)", fill=(20, 20, 20))
    sheet.paste(life_image, (0, life_y + heading))
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-root", required=True, type=Path)
    parser.add_argument("--diagnostics", required=True, type=Path)
    parser.add_argument("--baseline-sheet", required=True, type=Path)
    parser.add_argument("--contact-sheet", required=True, type=Path)
    parser.add_argument("--ab-sheet", required=True, type=Path)
    parser.add_argument("--observation", required=True, type=Path)
    args = parser.parse_args()

    diagnostics = json.loads(args.diagnostics.read_text(encoding="utf-8-sig"))
    events = sorted(diagnostics["events"], key=lambda event: parse_time(str(event["atUtc"])))
    records: list[dict[str, object]] = []
    for path in sorted(args.capture_root.glob("capture-*.png")):
        captured = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)
        with Image.open(path) as opened:
            width, height = opened.size
        records.append(
            {
                "file": str(path),
                "capturedAtUtc": captured.isoformat(),
                "state": state_at(captured, events),
                "width": width,
                "height": height,
            }
        )
    if not records:
        raise SystemExit("no runtime captures found")

    state_counts = {state: sum(record["state"] == state for record in records) for state in REQUIRED_STATES}
    missing = [state for state, count in state_counts.items() if count == 0]
    duration = (parse_time(str(records[-1]["capturedAtUtc"])) - parse_time(str(records[0]["capturedAtUtc"]))).total_seconds()
    action_events = [event for event in events if event["kind"] == "personality-action"]
    result = {
        "ok": not missing and duration >= 55 and diagnostics.get("lifeMotionsEnabled") is True,
        "capturedDurationSeconds": round(duration, 3),
        "captureCount": len(records),
        "stateCounts": state_counts,
        "missingRequiredStates": missing,
        "personalityActionCount": len(action_events),
        "personalityActions": [event["state"] for event in action_events],
        "diagnostics": str(args.diagnostics),
        "contactSheet": str(args.contact_sheet),
        "abSheet": str(args.ab_sheet),
    }
    make_contact_sheet(records, args.contact_sheet)
    make_ab_sheet(args.baseline_sheet, args.contact_sheet, args.ab_sheet)
    args.observation.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))
    if not result["ok"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
