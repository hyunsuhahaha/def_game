"""Summarize LAST HAUL's local playtest CSV without third-party packages."""
import argparse
import csv
import os
from collections import Counter, defaultdict
from pathlib import Path


def mean(rows, key):
    values = [float(row.get(key) or 0) for row in rows]
    return sum(values) / len(values) if values else 0


def summarize(rows, key):
    groups = defaultdict(list)
    for row in rows:
        label = row.get(key, "unknown")
        if key == "research_pct":
            label = f"{min(100, int(float(label or 0)) // 10 * 10)}%"
        groups[label].append(row)
    lines = ["| 구간 | 런 | 평균 생존 | 평균 벌목 | 평균 수입 | 평균 최고 단계 | 평균 FPS | 30 FPS 미만 프레임 | 주 사망 원인 |",
             "|---|---:|---:|---:|---:|---:|---:|---:|---|"]
    def order(item):
        return int(item[0][:-1]) if item[0].endswith("%") else item[0]
    for label, group in sorted(groups.items(), key=order):
        reason = Counter(row.get("death_reason") or "unknown" for row in group).most_common(1)[0][0]
        lines.append(f"| {label} | {len(group)} | {mean(group,'duration_sec'):.1f}초 | {mean(group,'trees_felled'):.1f} | "
                     f"{mean(group,'coins'):.1f} | {mean(group,'highest_tier'):.2f} | {mean(group,'avg_fps'):.1f} | "
                     f"{mean(group,'frames_below_30_pct'):.2f}% | {reason} |")
    return "\n".join(lines)


def progression(rows):
    maximum = max((int(float(row.get("highest_tier") or 1)) for row in rows), default=1)
    lines = ["| 재생 단계 | 최초 도달 판 | 도달한 런 |", "|---:|---:|---:|"]
    for tier in range(1, maximum + 1):
        reached = [index for index, row in enumerate(rows, 1) if float(row.get("highest_tier") or 1) >= tier]
        lines.append(f"| {tier} | {reached[0] if reached else '-'} | {len(reached)} |")
    return "\n".join(lines)


def first_thirty_minutes(rows):
    selected, elapsed = [], 0
    for row in rows:
        if elapsed >= 1800:
            break
        selected.append(row)
        elapsed += float(row.get("duration_sec") or 0)
    reasons = Counter(row.get("death_reason") or "unknown" for row in selected)
    return (f"기록 {len(selected)}판 · 플레이 {elapsed / 60:.1f}분 · 최고 재생 단계 "
            f"{max((float(row.get('highest_tier') or 1) for row in selected), default=1):.0f} · "
            f"벌목 {sum(float(row.get('trees_felled') or 0) for row in selected):.0f} · "
            f"수입 {sum(float(row.get('coins') or 0) for row in selected):.0f} · "
            f"사망 {', '.join(f'{key} {value}' for key, value in reasons.most_common())}")


def render(rows, source):
    return ("# 플레이테스트 자동 밸런스 리포트\n\n"
            f"원본: `{source}` · 정상 기록전 {len(rows)}판\n\n"
            "## 첫 30분\n\n" + first_thirty_minutes(rows) +
            "\n\n## 재생 단계 도달 판수\n\n" + progression(rows) +
            "\n\n"
            "## 연구 진척도 10% 구간\n\n" + summarize(rows, "research_pct") +
            "\n\n## 주력 원거리 무기\n\n" + summarize(rows, "build") +
            "\n\n> 좌표나 개인 식별 정보는 기록하지 않습니다. 표본 3판 미만인 구간은 가격 확정 근거로 사용하지 마세요.\n")


def default_input():
    appdata = Path(os.environ.get("APPDATA", "."))
    candidates = [appdata / "LOVE" / "last-haul" / "playtest_runs.csv", appdata / "last-haul" / "playtest_runs.csv"]
    return next((path for path in candidates if path.exists()), candidates[0])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", nargs="?", type=Path, default=default_input())
    parser.add_argument("-o", "--output", type=Path)
    args = parser.parse_args()
    if not args.input.exists():
        raise SystemExit(f"playtest log not found: {args.input}")
    with args.input.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    if not rows:
        raise SystemExit("playtest log contains no completed runs")
    output = args.output or args.input.with_name("playtest_balance_report.md")
    output.write_text(render(rows, args.input), encoding="utf-8")
    print(f"PLAYTEST_REPORT_OK runs={len(rows)} output={output}")


if __name__ == "__main__":
    main()
