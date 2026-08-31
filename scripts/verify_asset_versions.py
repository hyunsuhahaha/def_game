"""런타임이 연결한 자산 경로를 검사한다.

같은 대상의 v1/v2/v3가 한 폴더에 공존하고 "가장 큰 숫자가 현역"이라는 보장이 없어서,
에이전트가 grep으로 이름을 찾다가 낡은 버전이나 미채택 시안을 연결하는 사고가 반복됐다.
글로 적힌 규칙은 읽지 않으면 그만이므로 여기서 기계가 막는다.

검사 네 가지:
  1. src/*.lua 와 main.lua 가 문자열로 적은 자산 경로가 실제로 존재하는가
  2. 한 자산군(같은 이름, 다른 버전)에서 두 개 이상의 버전을 동시에 연결하지 않았는가
  3. 더 높은 버전이 아무 데서도 안 쓰이는데 낡은 버전을 연결하지 않았는가
  4. assets/enemies/README.md 가 미채택으로 명시한 자산을 런타임이 연결하지 않았는가

2·3번은 의도된 예외가 있을 수 있으므로 ALLOWED_FAMILIES 에 이유와 함께 등록한다.

동적 경로(문자열 연결)는 여기서 판정할 수 없으므로 폴더 존재만 확인하고 넘어간다.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

# 콘솔이 cp949 여도 한글·기호가 깨지지 않게 한다.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = sorted(ROOT.glob("src/*.lua")) + [ROOT / "main.lua", ROOT / "conf.lua"]

LITERAL = re.compile(r'"(assets/[^"]+\.(?:png|jpg|ttf|txt|glsl|fs|vs))"')
DYNAMIC = re.compile(r'"(assets/[^"]*?)"\s*\.\.')
VERSION = re.compile(r"-?v\d+(?=\.[A-Za-z0-9]+$)")

# -vN 이 버전이 아니라 별개 자산을 뜻하는 경우. 새 항목을 넣을 때는 왜 같은 군이
# 아닌지 이유를 함께 적는다. 이유 없이 늘어나면 검사가 무의미해진다.
ALLOWED_FAMILIES = {
    "assets/turret.png": "turret-v1은 보급 센터 하드포인트 스프라이트, turret-v2는 자동 포탑 선택 아이콘. 서로 다른 자산이다",
}


def family(path: str) -> str:
    """버전 꼬리표를 뗀 자산군 이름. foo-v2.png 와 foo-v3.png 는 같은 군이다.
    ALLOWED_FAMILIES 키와 맞도록 항상 posix 경로로 돌려준다."""
    name = Path(path).name
    return (Path(path).parent / VERSION.sub("", name)).as_posix()


def collect():
    literals: dict[str, list[str]] = {}
    dynamic: dict[str, list[str]] = {}
    for source in RUNTIME:
        if not source.exists():
            continue
        text = source.read_text(encoding="utf-8", errors="ignore")
        for match in LITERAL.finditer(text):
            literals.setdefault(match.group(1), []).append(source.name)
        for match in DYNAMIC.finditer(text):
            dynamic.setdefault(match.group(1), []).append(source.name)
    return literals, dynamic


def rejected() -> set[str]:
    """미채택으로 명시된 자산. 백틱으로 감싼 파일명만 읽는다."""
    readme = ROOT / "assets/enemies/README.md"
    if not readme.exists():
        return set()
    text = readme.read_text(encoding="utf-8", errors="ignore")
    marked = set()
    for line in text.splitlines():
        if "미채택" not in line and "평가받은 실험" not in line and "연결하지 않는다" not in line:
            continue
        for name in re.findall(r"`([^`]+\.png)`", line):
            marked.add(Path(name).name)
    return marked


def main() -> int:
    literals, dynamic = collect()
    failures: list[str] = []

    for path, who in sorted(literals.items()):
        if "%" in path:
            # string.format 패턴은 개별 파일을 지목하지 않으므로 폴더만 확인한다.
            if not (ROOT / path).parent.exists():
                failures.append(f"서식 경로의 폴더가 없다: {path}  ({', '.join(sorted(set(who)))})")
            continue
        if not (ROOT / path).exists():
            failures.append(f"연결한 자산이 없다: {path}  ({', '.join(sorted(set(who)))})")

    families: dict[str, set[str]] = {}
    for path in literals:
        if "%" in path:
            continue
        families.setdefault(family(path), set()).add(path)
    for base, paths in sorted(families.items()):
        if len(paths) > 1 and base not in ALLOWED_FAMILIES:
            listed = "  ".join(sorted(paths))
            failures.append(
                f"한 자산군에서 두 버전을 동시에 연결했다: {listed}"
                f" / 의도한 것이라면 verify_asset_versions.py 의 ALLOWED_FAMILIES 에"
                f" '{base}' 와 이유를 추가한다")

    # 가장 흔한 사고는 "v3가 있는데 v1을 연결"이다. 충돌이 없어 위 검사에 안 걸린다.
    # 같은 폴더에 더 높은 버전이 있는데 그 파일을 아무도 참조하지 않으면 잡는다.
    referenced = {Path(p).name for p in literals}
    for path in sorted(literals):
        if "%" in path:
            continue
        name = Path(path).name
        match = VERSION.search(name)
        # 버전 꼬리표가 없는 파일은 0으로 본다. supply-core.png 를 연결해 두고
        # supply-core-v2.png 가 놀고 있는 상태도 같은 사고이기 때문이다.
        used = int(re.search(r"\d+", match.group(0)).group(0)) if match else 0
        folder = ROOT / Path(path).parent
        if not folder.exists():
            continue
        newer = []
        for sibling in folder.iterdir():
            if not sibling.is_file() or sibling.name == name:
                continue
            if family(str(Path(path).parent / sibling.name)) != family(path):
                continue
            sibling_match = VERSION.search(sibling.name)
            if not sibling_match:
                continue
            if int(re.search(r"\d+", sibling_match.group(0)).group(0)) > used:
                if sibling.name not in referenced:
                    newer.append(sibling.name)
        if newer and family(path) not in ALLOWED_FAMILIES:
            failures.append(
                f"더 높은 버전이 놀고 있는데 낡은 버전을 연결했다: {path}"
                f" / 미사용 상위 버전: {', '.join(sorted(newer))}"
                f" / 의도한 것이라면 ALLOWED_FAMILIES 에 '{family(path)}' 와 이유를 추가한다")

    marked = rejected()
    for path in sorted(literals):
        if Path(path).name in marked:
            failures.append(f"미채택으로 명시된 자산을 런타임이 연결했다: {path}")

    for prefix in sorted(dynamic):
        folder = ROOT / prefix
        if not folder.parent.exists():
            failures.append(f"동적 경로의 폴더가 없다: {prefix}")

    if failures:
        print("ASSET_VERSIONS_FAIL")
        for line in failures:
            print("  " + line)
        return 1

    print(
        "ASSET_VERSIONS_OK literals=%d families=%d dynamic=%d rejected_listed=%d allowed=%d"
        % (len(literals), len(families), len(dynamic), len(marked), len(ALLOWED_FAMILIES))
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
