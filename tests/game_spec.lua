local T = {}

local function NewPlaying()
  local s = Game.New(Level, {})
  Game.Launch(s)
  return s
end

function T.new_game_starts_ready_with_playfield_size()
  local s = Game.New(Level, {})
  assert(s.mode == "ready", "mode should be ready, got " .. tostring(s.mode))
  assert(s.w == 1280 and s.h == 800, "playfield should be 1280x800")
end

function T.ball_does_not_move_until_launched()
  local s = Game.New(Level, {})
  local x, y = s.ball.x, s.ball.y
  Game.Step(s, 0.05, {})
  assert(s.ball.x == x and s.ball.y == y, "ball moved before launch")
end

function T.launch_starts_ball_moving_up()
  local s = NewPlaying()
  assert(s.mode == "playing", "mode should be playing after launch")
  local y = s.ball.y
  Game.Step(s, 0.05, {})
  assert(s.ball.y < y, "ball should travel upward after launch")
end

function T.ball_reflects_off_left_wall()
  local s = NewPlaying()
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = s.ball.r + 1, 400, -300, 0
  Game.Step(s, 0.05, {})
  assert(s.ball.vx > 0, "vx should be positive after left wall")
  assert(s.ball.x >= s.ball.r, "ball should stay inside the left wall")
end

function T.ball_reflects_off_right_wall()
  local s = NewPlaying()
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = s.w - s.ball.r - 1, 400, 300, 0
  Game.Step(s, 0.05, {})
  assert(s.ball.vx < 0, "vx should be negative after right wall")
  assert(s.ball.x <= s.w - s.ball.r, "ball should stay inside the right wall")
end

function T.ball_reflects_off_top_wall()
  local s = NewPlaying()
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 640, s.ball.r + 1, 0, -300
  Game.Step(s, 0.05, {})
  assert(s.ball.vy > 0, "vy should be positive after top wall")
  assert(s.ball.y >= s.ball.r, "ball should stay inside the top wall")
end

function T.fast_ball_stays_inside_playfield()
  local s = NewPlaying()
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 640, 400, 5000, -5000
  for _ = 1, 50 do
    Game.Step(s, 0.1, {})
    assert(s.ball.x >= s.ball.r and s.ball.x <= s.w - s.ball.r, "ball escaped horizontally")
    assert(s.ball.y >= s.ball.r, "ball escaped through the top")
  end
end

return T
