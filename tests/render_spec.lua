local T = {}

function T.frame_is_well_formed_xml()
  local svg = Render.Frame(Game.New(Level, {}))
  assert(IsWellFormedXml(svg), "frame is not well-formed XML")
end

function T.frame_uses_the_1280x800_viewbox()
  local svg = Render.Frame(Game.New(Level, {}))
  assert(svg:find('viewBox="0 0 1280 800"', 1, true), "viewBox missing or wrong")
end

function T.frame_is_under_8_kb()
  local svg = Render.Frame(Game.New(Level, {}))
  assert(#svg < 8192, "frame is " .. #svg .. " bytes")
end

function T.frame_draws_the_ball_at_its_position()
  local s = Game.New(Level, {})
  s.ball.x, s.ball.y = 123, 456
  local svg = Render.Frame(s)
  assert(svg:find('cx="123.0" cy="456.0"', 1, true), "ball circle not found at 123,456")
end

return T
