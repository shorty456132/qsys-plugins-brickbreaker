"""Runs tests/*_spec.lua against the pure-Lua game files (no Q-SYS needed),
then the name check in check_names.py.

Usage: python tests/run_tests.py
Each spec file returns a table of name -> test function; a test fails by raising an error.
"""
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

try:
    from lupa import lua53 as lupa  # Q-SYS runs Lua 5.3
except ImportError:
    import lupa

import check_names

ROOT = Path(__file__).resolve().parent.parent
SOURCES = ["level.lua", "game.lua", "render.lua"]


def is_well_formed_xml(text):
    try:
        ET.fromstring(text)
        return True
    except ET.ParseError:
        return False


def main():
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.globals().IsWellFormedXml = is_well_formed_xml
    run = lua.eval("function(f) local ok, err = xpcall(f, debug.traceback) return ok, err or '' end")

    for name in SOURCES:
        path = ROOT / name
        if not path.exists():
            print(f"FAIL  missing source file: {name}")
            return 1
        lua.execute(path.read_text(encoding="utf-8"))

    passed = failed = 0
    for spec in sorted((ROOT / "tests").glob("*_spec.lua")):
        tests = lua.execute(spec.read_text(encoding="utf-8"))
        for test_name in sorted(tests.keys()):
            ok, err = run(tests[test_name])
            if ok:
                passed += 1
            else:
                failed += 1
                print(f"FAIL  {spec.name}: {test_name}\n      {err}")

    # Control, property and page names must agree across the source files
    problems = check_names.find_problems(check_names.read_sources())
    if problems:
        failed += 1
        for problem in problems:
            print(f"FAIL  check_names: {problem}")
    else:
        passed += 1

    print(f"{passed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
