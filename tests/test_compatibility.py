"""Run with Python and lupa installed; no WoW client required.

These tests model API contracts, not Blizzard's rendering or secure execution.
"""
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
TOC = (ROOT / "EasySell.toc").read_text().splitlines()
MODULES = [line.strip() for line in TOC
           if line.strip().endswith(".lua")]
interfaces = next(line.split(":", 1)[1] for line in TOC if line.startswith("## Interface:"))
assert {120105, 16001} <= {int(version) for version in interfaces.split(",")}

for client in ("retail", "forever", "classic"):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().TEST_CLIENT = client
    lua.execute((ROOT / "tests/wow_mock.lua").read_text())
    for module in MODULES:
        lua.execute((ROOT / module).read_text(), "EasySell", name=module)
    lua.execute((ROOT / "tests/scenarios.lua").read_text())
    lua.execute((ROOT / "tests/restrictions.lua").read_text())
    print(f"PASS: {client}: all {len(MODULES)} modules and compatibility scenarios (Lua 5.1)")
