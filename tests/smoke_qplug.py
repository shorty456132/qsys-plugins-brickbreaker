"""Smoke-tests the compiled Brick-Breaker.qplug against stubbed Q-SYS APIs.

Usage: python tests/smoke_qplug.py   (compile first)
Checks the design-time functions, that every control has a layout entry, and that
the runtime draws well-formed SVG frames onto Screen when its timers fire.
This is a stand-in for Designer, not a replacement: the stubs only mimic the
handful of Q-SYS calls the plugin makes.
"""
import base64
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

try:
    from lupa import lua53 as lupa  # Q-SYS runs Lua 5.3
except ImportError:
    import lupa

QPLUG = Path(__file__).resolve().parent.parent / "Brick-Breaker.qplug"

STUBS = """
Timers = {}
Timer = {
  New = function()
    local t = { running = false }
    function t:Start(period) self.running = true; self.period = period end
    function t:Stop() self.running = false end
    function t:IsRunning() return self.running end
    table.insert(Timers, t)
    return t
  end,
  CallAfter = function(fn, delay) fn() end
}
Crypto = { Base64Encode = PyBase64Encode }
package.preload["rapidjson"] = function() return { encode = PyJsonEncode } end

function MakeRuntime(ctrlDefs, propDefs)
  Controls = {}
  for _, def in ipairs(ctrlDefs) do
    Controls[def.Name] = { String = "", Value = 0, Position = 0.5, Boolean = false, Legend = "" }
  end
  Properties = {}
  for _, def in ipairs(propDefs) do
    Properties[def.Name] = { Value = def.Value }
  end
end

function FireTimers(times)
  for _ = 1, times do
    for _, t in ipairs(Timers) do
      if t.running and t.EventHandler then t.EventHandler(t) end
    end
  end
end
"""


def fail(message):
    print(f"FAIL  {message}")
    sys.exit(1)


def main():
    if not QPLUG.exists():
        fail(f"{QPLUG.name} not found; compile first")
    source = QPLUG.read_text(encoding="utf-8")

    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    g.PyBase64Encode = lambda s: base64.b64encode(s.encode("utf-8")).decode("ascii")
    g.PyJsonEncode = lambda t: json.dumps(dict(t.items()))
    lua.execute(STUBS)

    # Design time: Controls is nil, so only the Get* functions are defined
    lua.execute(source)
    prop_defs = g.GetProperties()
    props = lua.table_from({d.Name: lua.table_from({"Value": d.Value}) for d in prop_defs.values()})
    props["page_index"] = lua.table_from({"Value": 1})
    for fn in ("GetColor", "GetPrettyName", "GetPages", "GetModel", "GetPins", "GetComponents", "GetWiring"):
        g[fn](props)
    ctrl_defs = g.GetControls(props)
    layout, graphics = g.GetControlLayout(props)

    names = [d.Name for d in ctrl_defs.values()]
    if len(names) != len(set(names)):
        fail("duplicate control names")
    for d in ctrl_defs.values():
        if d.Count != 1:
            fail(f"control {d.Name} has Count {d.Count}")
    missing = [n for n in names if layout[n] is None]
    if missing:
        fail(f"controls with no layout entry: {missing}")
    extra = [n for n in layout.keys() if n not in names]
    if extra:
        fail(f"layout entries with no control: {extra}")

    # Runtime: Controls exists, so the runtime block executes
    g.MakeRuntime(ctrl_defs, prop_defs)
    lua.execute(source)
    controls = g.Controls

    def screen_svg():
        legend = json.loads(controls["Screen"].Legend)
        if legend.get("DrawChrome") is not False:
            fail("Screen legend should set DrawChrome = false")
        svg = base64.b64decode(legend["IconData"]).decode("utf-8")
        try:
            ET.fromstring(svg)
        except ET.ParseError as err:
            fail(f"Screen SVG is not well-formed: {err}")
        return svg

    def ball_y():
        return float(ET.fromstring(screen_svg()).find("{http://www.w3.org/2000/svg}circle").get("cy"))

    g.FireTimers(5)
    if controls["Lives"].String != "3":
        fail(f"Lives should read 3, got '{controls['Lives'].String}'")
    if controls["Score"].String != "0":
        fail(f"Score should read 0, got '{controls['Score'].String}'")
    if controls["HighScore"].String != "0":
        fail(f"HighScore should read 0, got '{controls['HighScore'].String}'")
    if controls["GameState"].String != "Ready":
        fail(f"GameState should read Ready, got '{controls['GameState'].String}'")
    if ">Laptop<" not in screen_svg():
        fail("the panel's Laptop button should be drawn before play starts")

    # Fader drag moves the paddle
    controls["Paddle"].Position = 0
    g.FireTimers(1)
    if '<rect x="0.0" y="740"' not in screen_svg():
        fail("fader at 0 should put the paddle against the left wall")

    # Holding Right moves the paddle and drags the fader along with it
    controls["Right"].Boolean = True
    g.FireTimers(3)
    controls["Right"].Boolean = False
    if not controls["Paddle"].Position > 0:
        fail("holding Right should move the fader off 0")

    # The ball waits on the paddle until Screen is tapped
    parked = ball_y()
    g.FireTimers(3)
    if ball_y() != parked:
        fail("ball should not move before Screen is tapped")
    controls["Screen"].EventHandler(controls["Screen"])
    g.FireTimers(3)
    if not ball_y() < parked:
        fail("tapping Screen should launch the ball")
    if controls["GameState"].String != "Playing":
        fail(f"GameState should read Playing, got '{controls['GameState'].String}'")

    # Pause freezes the ball; releasing it carries on
    def set_pause(on):
        controls["Pause"].Boolean = on
        controls["Pause"].EventHandler(controls["Pause"])

    set_pause(True)
    frozen = ball_y()
    g.FireTimers(3)
    if ball_y() != frozen or controls["GameState"].String != "Paused":
        fail("Pause should freeze the ball and show Paused")
    if ">PAUSED<" not in screen_svg():
        fail("the paused frame should say PAUSED")
    set_pause(False)
    g.FireTimers(3)
    if ball_y() == frozen or controls["GameState"].String != "Playing":
        fail("releasing Pause should carry on")

    # Left alone, the ball breaks bricks on its way up and the score follows
    full = len(screen_svg())
    all_rects = screen_svg().count("<rect")
    g.FireTimers(200)
    svg = screen_svg()
    if not int(controls["Score"].String) > 0:
        fail(f"Score should rise once bricks break, got '{controls['Score'].String}'")
    if not svg.count("<rect") < all_rects:
        fail("broken bricks should drop out of the frame")

    # With nobody moving the paddle the remaining balls are lost and the game ends
    for _ in range(5):
        controls["Screen"].EventHandler(controls["Screen"])
        g.FireTimers(200)
        if controls["GameState"].String == "Game over":
            break
    if controls["GameState"].String != "Game over" or controls["Lives"].String != "0":
        fail(f"game should end, got '{controls['GameState'].String}' with {controls['Lives'].String} lives")
    if ">GAME OVER<" not in screen_svg():
        fail("the last frame should say GAME OVER")
    final = int(controls["Score"].String)
    if int(controls["HighScore"].String) != final:
        fail("HighScore should match the best score so far")

    # Pause does nothing after the game ends, and the button pops back out
    set_pause(True)
    if controls["Pause"].Boolean or controls["GameState"].String != "Game over":
        fail("Pause should be ignored once the game is over")

    # Start gives a fresh game and keeps the high score
    controls["Start"].EventHandler(controls["Start"])
    g.FireTimers(1)
    if (controls["Score"].String, controls["Lives"].String, controls["GameState"].String) != ("0", "3", "Ready"):
        fail("Start should reset score, lives and state")
    if int(controls["HighScore"].String) != final:
        fail("Start should keep the high score")
    if screen_svg().count("<rect") != all_rects:
        fail("Start should bring every brick back")

    print(f"OK    {len(names)} controls, {len(list(graphics.values()))} graphics, "
          f"full frame {full} bytes, high score {final}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
