"""Prepend show_bible.md to an output directory's episode_focus.txt.

Usage: python3 merge_show_bible.py output/YYYY-MM-DD

NotebookLM treats uploaded sources as content to discuss, so the show bible
goes through the customization textbox instead. After this runs, the whole
episode_focus.txt can be pasted into that textbox. Safe to run twice.
"""

import sys
from pathlib import Path

MARKER = "TODAY'S EPISODE FOCUS"


def main():
    if len(sys.argv) != 2:
        print("usage: python3 merge_show_bible.py output/YYYY-MM-DD")
        return 2
    bible = Path(__file__).with_name("show_bible.md")
    focus = Path(sys.argv[1]) / "episode_focus.txt"
    if not focus.exists():
        print(f"missing {focus}")
        return 1
    daily = focus.read_text(encoding="utf-8").rstrip()
    if MARKER in daily:
        print("already merged")
        return 0
    combined = bible.read_text(encoding="utf-8").rstrip() + f"\n\n---\n\n{MARKER}\n\n" + daily + "\n"
    focus.write_text(combined, encoding="utf-8")
    print(f"merged show_bible.md into {focus}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
