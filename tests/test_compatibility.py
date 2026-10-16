"""Run with Python and lupa installed; no WoW client required.

These tests model API contracts, not Blizzard's rendering or secure execution.
"""
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
MODULES = [line.strip() for line in (ROOT / "EasySell.toc").read_text().splitlines()
           if line.strip().endswith(".lua")]

for client in ("retail", "classic"):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().TEST_CLIENT = client
    lua.execute((ROOT / "tests/wow_mock.lua").read_text())
    for module in MODULES:
        lua.execute((ROOT / module).read_text(), name=module)
    lua.execute((ROOT / "tests/scenarios.lua").read_text())
    print(f"PASS: {client}: all {len(MODULES)} modules and compatibility scenarios (Lua 5.1)")
