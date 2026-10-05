local T = {}

-- Four 200x80 bricks in a row, y 200..280, at x 100, 400, 700 and 1000
local function FourBrickLevel()
  local bricks = {}
  for i = 1, 4 do
    bricks[i] = { x = 100 + 300 * (i - 1), y = 200, w = 200, h = 80, label = "B" .. i, kind = "source", color = "#123456" }
  end
  return { W = 1280, H = 800, Bricks = bricks }
end

local function NewPlaying()
  local s = Game.New(FourBrickLevel(), {})
  Game.Launch(s)
  return s
end

local function Speed(s)
  return math.sqrt(s.ball.vx ^ 2 + s.ball.vy ^ 2)
end

local function Near(a, b)
  return math.abs(a - b) < 1e-6
end

-- Sends the ball up into the underside of brick i at its current speed
local function BreakBrick(s, i)
  local speed = Speed(s)
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 200 + 300 * (i - 1), 295, 0, -speed
  Game.Step(s, 0.02, {})
  assert(not s.bricks[i].alive, "setup: brick " .. i .. " should have broken")
end

function T.launch_speed_on_a_full_panel_is_the_base_speed()
  local s = NewPlaying()
  assert(Near(Speed(s), BaseSpeed), "expected " .. BaseSpeed .. ", got " .. Speed(s))
  assert(Near(Game.BallSpeed(s), BaseSpeed), "BallSpeed should report the base speed")
end

function T.launch_still_heads_up_and_to_the_right()
  local s = NewPlaying()
  assert(s.ball.vx > 0 and s.ball.vy < 0, "ball should launch up and to the right")
end

function T.each_broken_brick_makes_the_ball_faster()
  local s = NewPlaying()
  local last = Speed(s)
  for i = 1, 3 do
    BreakBrick(s, i)
    assert(Speed(s) > last, "ball should speed up after brick " .. i)
    last = Speed(s)
  end
end

function T.speed_rises_in_proportion_to_bricks_broken()
  local s = NewPlaying()
  BreakBrick(s, 1)
  BreakBrick(s, 2)
  local expected = BaseSpeed * (1 + MaxSpeedUp * 0.5)
  assert(Near(Speed(s), expected), "half the bricks gone: expected " .. expected .. ", got " .. Speed(s))
end

function T.speed_never_passes_the_cap()
  local s = NewPlaying()
  for i = 1, 4 do BreakBrick(s, i) end
  assert(Speed(s) <= BaseSpeed * (1 + MaxSpeedUp) + 1e-6, "speed went past the cap: " .. Speed(s))
end

function T.speeding_up_keeps_the_bounce_direction()
  local s = NewPlaying()
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 200, 295, 0, -400
  Game.Step(s, 0.02, {})
  assert(s.ball.vx == 0, "a straight-up hit should come straight back down")
  assert(s.ball.vy > 0, "ball should be heading down")
end

function T.relaunch_after_losing_a_life_keeps_the_faster_speed()
  local s = NewPlaying()
  BreakBrick(s, 1)
  BreakBrick(s, 2)
  local fast = Speed(s)
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 1200, s.h - 5, 0, 400
  for _ = 1, 10 do Game.Step(s, 0.05, {}) end
  assert(s.mode == "ready", "setup: a life should have been lost")
  Game.Launch(s)
  assert(Near(Speed(s), fast), "relaunch should be at " .. fast .. ", got " .. Speed(s))
end

function T.reset_returns_to_the_base_speed()
  local s = NewPlaying()
  BreakBrick(s, 1)
  BreakBrick(s, 2)
  Game.Reset(s)
  Game.Launch(s)
  assert(Near(Speed(s), BaseSpeed), "new game should launch at the base speed, got " .. Speed(s))
end

function T.fastest_ball_still_cannot_tunnel_through_a_brick()
  local s = NewPlaying()
  local top = BaseSpeed * (1 + MaxSpeedUp)
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 200, 330, 0, -top
  Game.Step(s, 0.1, {})
  assert(not s.bricks[1].alive, "the brick in the ball's path should have broken")
end

return T
