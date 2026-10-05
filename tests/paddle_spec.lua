local T = {}

local function NewPlaying()
  local s = Game.New(Level, {})
  Game.Launch(s)
  return s
end

-- Puts the ball just above the paddle, falling straight down, offset from the paddle centre
local function DropOnPaddle(s, offset)
  s.ball.x = s.paddle.x + offset
  s.ball.y = s.paddle.y - s.ball.r - 2
  s.ball.vx, s.ball.vy = 0, 400
  Game.Step(s, 0.02, {})
end

function T.fader_at_zero_puts_paddle_against_left_wall()
  local s = Game.New(Level, {})
  Game.Step(s, 0.05, { paddlePos = 0 })
  assert(s.paddle.x == s.paddle.w / 2, "paddle left edge should be at 0")
end

function T.fader_at_one_puts_paddle_against_right_wall()
  local s = Game.New(Level, {})
  Game.Step(s, 0.05, { paddlePos = 1 })
  assert(s.paddle.x == s.w - s.paddle.w / 2, "paddle right edge should be at the wall")
end

function T.fader_out_of_range_is_clamped()
  local s = Game.New(Level, {})
  Game.Step(s, 0.05, { paddlePos = 1.7 })
  assert(s.paddle.x == s.w - s.paddle.w / 2, "paddle should clamp at the right wall")
  Game.Step(s, 0.05, { paddlePos = -3 })
  assert(s.paddle.x == s.paddle.w / 2, "paddle should clamp at the left wall")
end

function T.paddle_pos_round_trips_through_the_fader_mapping()
  local s = Game.New(Level, {})
  Game.Step(s, 0.05, { paddlePos = 0.25 })
  assert(math.abs(Game.PaddlePos(s) - 0.25) < 1e-9, "PaddlePos should return 0.25")
end

function T.left_and_right_buttons_move_paddle_at_fixed_speed()
  local s = Game.New(Level, {})
  local x = s.paddle.x
  Game.Step(s, 0.1, { left = true })
  local moved = x - s.paddle.x
  assert(moved > 0, "left should move the paddle left")
  Game.Step(s, 0.1, { right = true })
  assert(math.abs(s.paddle.x - x) < 1e-9, "right should move it back by the same amount")
  Game.Step(s, 0.2, { right = true })
  assert(math.abs((s.paddle.x - x) - 2 * moved) < 1e-9, "distance should scale with time")
end

function T.buttons_cannot_push_paddle_through_a_wall()
  local s = Game.New(Level, {})
  for _ = 1, 100 do Game.Step(s, 0.1, { left = true }) end
  assert(s.paddle.x == s.paddle.w / 2, "paddle should stop at the left wall")
end

function T.ball_rides_the_paddle_while_ready()
  local s = Game.New(Level, {})
  Game.Step(s, 0.05, { paddlePos = 0 })
  assert(s.ball.x == s.paddle.x, "ball should follow the paddle before launch")
  assert(s.ball.y == s.paddle.y - s.ball.r, "ball should sit on top of the paddle")
end

function T.ball_bounces_up_off_the_paddle()
  local s = NewPlaying()
  DropOnPaddle(s, 0)
  assert(s.ball.vy < 0, "ball should travel up after hitting the paddle")
  assert(s.lives == 3, "no life should be lost")
end

function T.bounce_angle_depends_on_where_the_ball_hits()
  local s = NewPlaying()
  DropOnPaddle(s, -60)
  local leftVx = s.ball.vx
  s = NewPlaying()
  DropOnPaddle(s, 60)
  local rightVx = s.ball.vx
  s = NewPlaying()
  DropOnPaddle(s, 20)
  local nearVx = s.ball.vx
  assert(leftVx < 0, "a hit left of centre should send the ball left")
  assert(rightVx > 0, "a hit right of centre should send the ball right")
  assert(nearVx > 0 and nearVx < rightVx, "a hit nearer the centre should be steeper")
end

function T.paddle_bounce_keeps_ball_speed()
  local s = NewPlaying()
  DropOnPaddle(s, 45)
  local speed = math.sqrt(s.ball.vx ^ 2 + s.ball.vy ^ 2)
  assert(math.abs(speed - 400) < 1e-6, "speed should stay 400, got " .. speed)
end

function T.missing_the_paddle_costs_a_life_and_returns_to_ready()
  local s = NewPlaying()
  Game.Step(s, 0.05, { paddlePos = 0 })
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 1000, s.h - 20, 0, 400
  for _ = 1, 10 do Game.Step(s, 0.05, {}) end
  assert(s.lives == 2, "lives should drop to 2, got " .. s.lives)
  assert(s.mode == "ready", "mode should be ready, got " .. s.mode)
  assert(s.ball.x == s.paddle.x, "ball should be back on the paddle")
end

function T.losing_the_last_life_ends_the_game()
  local s = Game.New(Level, { lives = 1 })
  Game.Launch(s)
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 1000, s.h - 20, 0, 400
  for _ = 1, 10 do Game.Step(s, 0.05, {}) end
  assert(s.lives == 0, "lives should be 0")
  assert(s.mode == "lost", "mode should be lost, got " .. s.mode)
end

function T.launch_only_works_from_ready()
  local s = NewPlaying()
  s.ball.vx, s.ball.vy = 111, 222
  Game.Launch(s)
  assert(s.ball.vx == 111 and s.ball.vy == 222, "launch while playing should do nothing")
  s.mode = "lost"
  Game.Launch(s)
  assert(s.mode == "lost", "launch after losing should do nothing")
end

function T.frame_draws_the_paddle()
  local s = Game.New(Level, {})
  Game.Step(s, 0.05, { paddlePos = 0 })
  local svg = Render.Frame(s)
  assert(svg:find('<rect x="0.0" y="740" width="180" height="20"', 1, true), "paddle rect not found")
  assert(IsWellFormedXml(svg), "frame is not well-formed XML")
end

return T
