#!/usr/bin/env python3
"""
统一的 Agent Adapter（v1）。
目标：屏蔽 Claude/Codex 差异，统一暴露 plan/act/review/memory 四类能力入口。
"""

import argparse
import json
from datetime import datetime, UTC

VALID_ACTIONS = {"plan", "act", "review", "memory"}
VALID_ENGINES = {"claude", "codex"}


def main() -> int:
    parser = argparse.ArgumentParser(description="Agent adapter gateway")
    parser.add_argument("--engine", required=True, choices=sorted(VALID_ENGINES))
    parser.add_argument("--action", required=True, choices=sorted(VALID_ACTIONS))
    parser.add_argument("--input-file", required=True, help="JSON 输入文件路径")
    parser.add_argument("--out-file", required=True, help="JSON 输出文件路径")
    parser.add_argument("--route-reason", required=True, help="为何选择该 engine")
    args = parser.parse_args()

    with open(args.input_file, "r", encoding="utf-8") as f:
        payload = json.load(f)

    out = {
        "generated_at": datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "engine": args.engine,
        "action": args.action,
        "route_reason": args.route_reason,
        "status": "stubbed",
        "input": payload,
        "result": {
            "summary": "adapter v1 已接入；当前为统一契约桩实现，待接真实 SDK。",
            "next_step": "在 scripts/adapters/ 下分别补 claude/codex provider 实现。",
        },
    }

    with open(args.out_file, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
