"""Checks that control, property and page names agree across the plugin's source files.

Usage: python tests/check_names.py   (also run by run_tests.py)
Names are matched as text, so a control reached through a variable is only seen
if it is passed to ShowText("Name", ...) in runtime.lua.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RESERVED = {"Status"}


def find_problems(files):
    """files maps a source file name to its text. Returns a list of problem strings."""
    runtime = files["runtime.lua"]
    defined = re.findall(r'Name\s*=\s*"([^"]+)"', files["controls.lua"])
    laid_out = set(re.findall(r'layout\["([^"]+)"\]', files["layout.lua"]))
    used = set(re.findall(r'Controls\["([^"]+)"\]', runtime))
    used |= set(re.findall(r'Controls\.(\w+)', runtime))
    used |= set(re.findall(r'ShowText\("([^"]+)"', runtime))

    properties = set(re.findall(r'Name\s*=\s*"([^"]+)"', files["properties.lua"]))
    props_used = set(re.findall(r'Properties\["([^"]+)"\]', runtime))
    props_used |= set(re.findall(r'props\["([^"]+)"\]', files["layout.lua"] + files["controls.lua"]))
    props_used.discard("page_index")  # supplied by Q-SYS

    pages = set(re.findall(r'"([^"]+)"', re.search(r'PageNames\s*=\s*\{([^}]*)\}', files["plugin.lua"]).group(1)))
    pages_laid_out = set(re.findall(r'CurrentPage\s*==\s*"([^"]+)"', files["layout.lua"]))

    problems = []
    for name in sorted(set(n for n in defined if defined.count(n) > 1)):
        problems.append(f"control {name} is defined more than once in controls.lua")
    for name in sorted(used - set(defined)):
        problems.append(f"runtime.lua uses control {name}, which controls.lua does not define")
    for name in sorted(set(defined) - laid_out):
        problems.append(f"control {name} has no layout entry in layout.lua")
    for name in sorted(laid_out - set(defined)):
        problems.append(f"layout.lua places {name}, which controls.lua does not define")
    for name in sorted(set(defined) - used):
        problems.append(f"control {name} is never used in runtime.lua")
    for name in sorted(set(defined) & RESERVED):
        problems.append(f"control name {name} is reserved by Q-SYS")
    for name in sorted(props_used - properties):
        problems.append(f"property {name} is used but properties.lua does not define it")
    for name in sorted(properties - props_used):
        problems.append(f"property {name} is never used")
    for name in sorted(pages ^ pages_laid_out):
        problems.append(f"page {name} is not in both PageNames and layout.lua")
    return problems


def read_sources():
    names = ["plugin.lua", "controls.lua", "layout.lua", "runtime.lua", "properties.lua"]
    return {name: (ROOT / name).read_text(encoding="utf-8") for name in names}


if __name__ == "__main__":
    found = find_problems(read_sources())
    for problem in found:
        print(f"FAIL  {problem}")
    print("names OK" if not found else f"{len(found)} name problems")
    sys.exit(1 if found else 0)
