#!/usr/bin/env python3
"""همه‌ی تصویرهای وکتور را می‌سازد و در res/drawable می‌گذارد."""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)

import svgkit as k                      # noqa: E402
from mascot import bear, POSES          # noqa: E402

OUT = os.path.join(ROOT, "app", "src", "main", "res", "drawable")


def all_items():
    for pose in POSES:
        yield "mascot_" + pose, bear(pose)


def main():
    only = set(a for a in sys.argv[1:] if not a.startswith("--"))
    preview = "--preview" in sys.argv
    out_dir = os.path.join(ROOT, "build", "art-preview") if preview else OUT

    made = 0
    for name, body in all_items():
        if only and name not in only:
            continue
        p = k.render(name, body, out_dir)
        print(f"✅ {name}.png  {os.path.getsize(p) // 1024} KB")
        made += 1
    print(f"\n{made} تصویر در {os.path.relpath(out_dir, ROOT)}")


if __name__ == "__main__":
    main()
