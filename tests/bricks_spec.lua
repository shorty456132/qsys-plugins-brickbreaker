local T = {}

-- One 200x80 brick spanning x 500..700, y 200..280
local function OneBrickLevel()
  return {
    W = 1280,
    H = 800,
    Bricks = { { x = 500, y = 200, w = 200, h = 80, label = "Test", kind = "source", color = "#123456" } }
  }
end

local function NewPlaying(level)
  local s = Game.New(level, {})
  Game.Launch(s)
  return s
end

local function Overlaps(a, b)
  return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

function T.level_has_the_main_page_bricks()
  assert(#Level.Bricks >= 25, "expected about 30 bricks, got " .. #Level.Bricks)
  for i, brick in ipairs(Level.Bricks) do
    assert(brick.w > 0 and brick.h > 0, "brick " .. i .. " has no size")
    assert(type(brick.label) == "string", "brick " .. i .. " has no label string")
    assert(type(brick.kind) == "string", "brick " .. i .. " has no kind")
    assert(type(brick.color) == "string" and brick.color:match("^#%x%x%x%x%x%x$"),
      "brick " .. i .. " has no #rrggbb color")
  end
end

function T.level_bricks_sit_inside_the_top_440_px()
  for i, brick in ipairs(Level.Bricks) do
    assert(brick.x >= 0 and brick.x + brick.w <= Level.W, "brick " .. i .. " is outside the side walls")
    assert(brick.y >= 0 and brick.y + brick.h <= 440, "brick " .. i .. " is outside the top 440 px")
  end
end

function T.level_bricks_do_not_overlap()
  for i = 1, #Level.Bricks do
    for j = i + 1, #Level.Bricks do
      assert(not Overlaps(Level.Bricks[i], Level.Bricks[j]), "bricks " .. i .. " and " .. j .. " overlap")
    end
  end
end

function T.new_game_copies_the_level_bricks_alive()
  local level = OneBrickLevel()
  local s = Game.New(level, {})
  assert(#s.bricks == 1, "state should have one brick")
  assert(s.bricks[1].alive == true, "brick should start alive")
  assert(s.bricks[1] ~= level.Bricks[1], "state should own its bricks, not share the level's")
  assert(s.score == 0 and s.bricksVersion == 0, "score and bricksVersion should start at 0")
end

function T.hitting_a_brick_kills_it_scores_and_bumps_the_version()
  local s = NewPlaying(OneBrickLevel())
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 600, 295, 0, -400
  Game.Step(s, 0.02, {})
  assert(s.bricks[1].alive == false, "brick should be dead")
  assert(s.score == 10, "score should be 10, got " .. s.score)
  assert(s.bricksVersion == 1, "bricksVersion should be 1, got " .. s.bricksVersion)
end

function T.the_level_is_untouched_when_a_brick_breaks()
  local level = OneBrickLevel()
  local s = NewPlaying(level)
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 600, 295, 0, -400
  Game.Step(s, 0.02, {})
  assert(level.Bricks[1].alive == nil, "the level table should not be modified")
  assert(Game.New(level, {}).bricks[1].alive == true, "a new game should get the brick back")
end

function T.hit_from_below_sends_the_ball_down()
  local s = NewPlaying(OneBrickLevel())
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 600, 295, 0, -400
  Game.Step(s, 0.02, {})
  assert(s.ball.vy > 0, "vy should flip to downward")
  assert(s.ball.vx == 0, "vx should be unchanged")
end

function T.hit_from_above_sends_the_ball_up()
  local s = NewPlaying(OneBrickLevel())
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 600, 185, 0, 400
  Game.Step(s, 0.02, {})
  assert(s.bricks[1].alive == false, "brick should be dead")
  assert(s.ball.vy < 0, "vy should flip to upward")
end

function T.hit_on_the_left_side_sends_the_ball_left()
  local s = NewPlaying(OneBrickLevel())
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 485, 240, 400, 0
  Game.Step(s, 0.02, {})
  assert(s.bricks[1].alive == false, "brick should be dead")
  assert(s.ball.vx < 0, "vx should flip to leftward")
  assert(s.ball.vy == 0, "vy should be unchanged")
end

function T.hit_on_the_right_side_sends_the_ball_right()
  local s = NewPlaying(OneBrickLevel())
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 715, 240, -400, 0
  Game.Step(s, 0.02, {})
  assert(s.bricks[1].alive == false, "brick should be dead")
  assert(s.ball.vx > 0, "vx should flip to rightward")
end

function T.fast_ball_does_not_tunnel_through_a_brick()
  local s = NewPlaying(OneBrickLevel())
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 600, 330, 0, -3000
  Game.Step(s, 0.05, {})
  assert(s.bricks[1].alive == false, "brick should be dead")
  assert(s.ball.vy > 0, "ball should have bounced back down")
  assert(s.ball.y > 280, "ball should be below the brick, at y " .. s.ball.y)
end

function T.ball_passes_through_a_dead_brick()
  local s = NewPlaying(OneBrickLevel())
  s.bricks[1].alive = false
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 600, 295, 0, -400
  Game.Step(s, 0.02, {})
  assert(s.ball.vy == -400, "ball should keep going")
  assert(s.score == 0, "a dead brick should not score")
end

function T.one_hit_breaks_only_one_brick()
  local level = OneBrickLevel()
  table.insert(level.Bricks, { x = 710, y = 200, w = 200, h = 80, label = "Next", kind = "source", color = "#123456" })
  local s = NewPlaying(level)
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 705, 295, 0, -400
  Game.Step(s, 0.02, {})
  assert(s.score == 10, "one hit should break one brick, score " .. s.score)
end

function T.brick_layer_draws_live_bricks_with_their_labels()
  local s = Game.New(OneBrickLevel(), {})
  local layer = Render.Bricks(s)
  assert(layer:find('<rect x="500" y="200" width="200" height="80"', 1, true), "brick rect not found")
  assert(layer:find('fill="#123456"', 1, true), "brick color not found")
  assert(layer:find(">Test<", 1, true), "brick label not found")
end

function T.dead_bricks_are_absent_from_the_brick_layer()
  local s = NewPlaying(OneBrickLevel())
  assert(Render.Bricks(s):find(">Test<", 1, true), "label should be there before the hit")
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 600, 295, 0, -400
  Game.Step(s, 0.02, {})
  local layer = Render.Bricks(s)
  assert(not layer:find(">Test<", 1, true), "dead brick's label is still drawn")
  assert(not layer:find('x="500" y="200"', 1, true), "dead brick's rect is still drawn")
end

function T.brick_layer_is_not_shared_between_games()
  local a = Game.New(OneBrickLevel(), {})
  local b = Game.New({ W = 1280, H = 800, Bricks = {} }, {})
  assert(Render.Bricks(a):find(">Test<", 1, true), "game a should draw its brick")
  assert(not Render.Bricks(b):find(">Test<", 1, true), "game b has no bricks to draw")
end

function T.full_level_frame_is_well_formed_and_shows_the_panel()
  local svg = Render.Frame(Game.New(Level, {}))
  assert(IsWellFormedXml(svg), "frame is not well-formed XML")
  assert(svg:find(">Laptop<", 1, true), "Laptop button not drawn")
  assert(svg:find(">System Off<", 1, true), "System Off button not drawn")
  assert(#svg < 8192, "frame is " .. #svg .. " bytes")
end

return T
