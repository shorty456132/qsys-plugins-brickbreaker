-- Game logic: ball, paddle and brick physics and the game state machine.
-- Pure Lua: no Q-SYS APIs, so it loads in the test runner.
Game = {}

BallRadius = 12
LaunchVx = 300
LaunchVy = -380
PaddleSpeed = 900                 -- px per second while Left or Right is held
MaxBounceAngle = math.rad(60)     -- from vertical, for a hit at the paddle's edge
BrickPoints = 10
BaseSpeed = math.sqrt(LaunchVx ^ 2 + LaunchVy ^ 2)   -- px per second with every brick standing
MaxSpeedUp = 0.5                  -- extra speed, as a fraction, once the last brick is gone

function Clamp(value, low, high)
  return math.max(low, math.min(high, value))
end

-- Sits the ball on top of the paddle, at rest
function ParkBall(state)
  local ball = state.ball
  ball.x = state.paddle.x
  ball.y = state.paddle.y - ball.r
  ball.vx = 0
  ball.vy = 0
end

--[[ Summary:
    Creates a new game state in "ready" mode with the ball parked
    on the paddle. paddle.x is the paddle's centre and paddle.y its
    top edge.
    Params:  level (table) - Level table with W, H and Bricks
             opts (table)  - optional settings: lives, highScore (number)
    Returns: state (table)
]]
function Game.New(level, opts)
  opts = opts or {}
  local state = {
    w = level.W,
    h = level.H,
    ball = { x = 0, y = 0, vx = 0, vy = 0, r = BallRadius },
    paddle = { x = level.W / 2, y = level.H - 60, w = 180, h = 20 },
    bricks = {},
    bricksLeft = #level.Bricks,
    brickBottom = 0,              -- lowest brick edge; below it there is nothing to hit
    score = 0,
    highScore = opts.highScore or 0,
    lives = opts.lives or 3,
    startLives = opts.lives or 3,
    mode = "ready",
    resumeMode = "ready",         -- mode to return to when a pause ends
    bricksVersion = 0
  }
  for i, brick in ipairs(level.Bricks) do
    state.bricks[i] = {
      x = brick.x, y = brick.y, w = brick.w, h = brick.h,
      label = brick.label, kind = brick.kind, color = brick.color,
      alive = true
    }
    state.brickBottom = math.max(state.brickBottom, brick.y + brick.h)
  end
  ParkBall(state)
  return state
end

--[[ Summary:
    The speed the ball should travel at right now. It rises in a
    straight line from BaseSpeed on a full panel to BaseSpeed *
    (1 + MaxSpeedUp) when the last brick breaks.
    Params:  state (table) - game state
    Returns: speed (number) - px per second
]]
function Game.BallSpeed(state)
  local broken = #state.bricks - state.bricksLeft
  local progress = (#state.bricks > 0) and (broken / #state.bricks) or 0
  return BaseSpeed * (1 + MaxSpeedUp * progress)
end

-- Rescales the ball's velocity to the current target speed, keeping its direction
function ApplyBallSpeed(state)
  local ball = state.ball
  local speed = math.sqrt(ball.vx ^ 2 + ball.vy ^ 2)
  if speed == 0 then return end
  local scale = Game.BallSpeed(state) / speed
  ball.vx = ball.vx * scale
  ball.vy = ball.vy * scale
end

function Game.Launch(state)
  if state.mode ~= "ready" then return end
  state.ball.vx = LaunchVx
  state.ball.vy = LaunchVy
  ApplyBallSpeed(state)
  state.mode = "playing"
end

-- Starts a new game: all bricks back, score cleared, lives refilled. The high score stays.
function Game.Reset(state)
  for _, brick in ipairs(state.bricks) do
    brick.alive = true
  end
  state.bricksLeft = #state.bricks
  state.bricksVersion = state.bricksVersion + 1
  state.score = 0
  state.lives = state.startLives
  state.mode = "ready"
  ParkBall(state)
end

-- Pauses a game in progress, or resumes it; ignored once the game is won or lost
function Game.SetPaused(state, paused)
  if paused and (state.mode == "ready" or state.mode == "playing") then
    state.resumeMode = state.mode
    state.mode = "paused"
  elseif not paused and state.mode == "paused" then
    state.mode = state.resumeMode
  end
end

-- A tap on the playfield: launches the ball, or starts a new game once this one is over
function Game.Tap(state)
  if state.mode == "ready" then
    Game.Launch(state)
  elseif state.mode == "won" or state.mode == "lost" then
    Game.Reset(state)
  end
end

-- Paddle position as a 0..1 fader position (the inverse of input.paddlePos)
function Game.PaddlePos(state)
  local paddle = state.paddle
  return (paddle.x - paddle.w / 2) / (state.w - paddle.w)
end

-- Applies fader and button input to the paddle, keeping it inside the walls
function MovePaddle(state, dt, input)
  local paddle = state.paddle
  local half = paddle.w / 2
  if input.paddlePos then
    paddle.x = half + Clamp(input.paddlePos, 0, 1) * (state.w - paddle.w)
  end
  if input.left then paddle.x = paddle.x - PaddleSpeed * dt end
  if input.right then paddle.x = paddle.x + PaddleSpeed * dt end
  paddle.x = Clamp(paddle.x, half, state.w - half)
end

-- Reflects the ball off the left, right and top walls; the bottom is open
function BounceOffWalls(state)
  local ball = state.ball
  if ball.x < ball.r then
    ball.x = ball.r
    ball.vx = math.abs(ball.vx)
  elseif ball.x > state.w - ball.r then
    ball.x = state.w - ball.r
    ball.vx = -math.abs(ball.vx)
  end
  if ball.y < ball.r then
    ball.y = ball.r
    ball.vy = math.abs(ball.vy)
  end
end

--[[ Summary:
    Bounces a falling ball off the paddle. The outgoing angle depends
    on where the ball lands: straight up from the centre, up to
    MaxBounceAngle from vertical at either edge. Speed is unchanged.
    Params:  state (table) - game state
    Returns: nil
]]
function BounceOffPaddle(state)
  local ball, paddle = state.ball, state.paddle
  local half = paddle.w / 2
  if ball.vy <= 0 then return end
  if ball.y + ball.r < paddle.y or ball.y > paddle.y + paddle.h then return end
  if math.abs(ball.x - paddle.x) > half + ball.r then return end
  local offset = Clamp((ball.x - paddle.x) / half, -1, 1)
  local speed = math.sqrt(ball.vx ^ 2 + ball.vy ^ 2)
  ball.vx = speed * math.sin(offset * MaxBounceAngle)
  ball.vy = -speed * math.cos(offset * MaxBounceAngle)
  ball.y = paddle.y - ball.r
end

--[[ Summary:
    Breaks the first live brick the ball overlaps and bounces the
    ball off it. The face that was hit is the axis with the smaller
    overlap: a side hit reverses vx, a top or bottom hit reverses vy.
    At most one brick breaks per call, and the ball speeds up a
    little each time.
    Params:  state (table) - game state
    Returns: broke (boolean) - true if a brick was broken
]]
function BounceOffBricks(state)
  local ball = state.ball
  local r = ball.r
  if ball.y - r > state.brickBottom then return end
  for _, brick in ipairs(state.bricks) do
    if brick.alive then
      local dx = ball.x - Clamp(ball.x, brick.x, brick.x + brick.w)
      local dy = ball.y - Clamp(ball.y, brick.y, brick.y + brick.h)
      if dx * dx + dy * dy < r * r then
        local centreX = brick.x + brick.w / 2
        local centreY = brick.y + brick.h / 2
        local overlapX = brick.w / 2 + r - math.abs(ball.x - centreX)
        local overlapY = brick.h / 2 + r - math.abs(ball.y - centreY)
        if overlapX < overlapY then
          local side = (ball.x < centreX) and -1 or 1
          ball.vx = side * math.abs(ball.vx)
          ball.x = ball.x + side * overlapX
        else
          local side = (ball.y < centreY) and -1 or 1
          ball.vy = side * math.abs(ball.vy)
          ball.y = ball.y + side * overlapY
        end
        brick.alive = false
        state.bricksLeft = state.bricksLeft - 1
        state.score = state.score + BrickPoints
        state.highScore = math.max(state.highScore, state.score)
        state.bricksVersion = state.bricksVersion + 1
        ApplyBallSpeed(state)
        return true
      end
    end
  end
  return false
end

function LoseLife(state)
  state.lives = state.lives - 1
  ParkBall(state)
  state.mode = (state.lives > 0) and "ready" or "lost"
end

--[[ Summary:
    Advances the game by dt seconds. The ball's move is split into
    sub-steps no longer than its radius so a fast ball cannot skip
    past whatever it should hit.
    Params:  state (table) - game state from Game.New
             dt (number)   - seconds since the last step
             input (table) - paddlePos (0..1 or nil), left, right (boolean)
    Returns: nil
]]
function Game.Step(state, dt, input)
  if state.mode ~= "ready" and state.mode ~= "playing" then return end
  MovePaddle(state, dt, input)
  if state.mode == "ready" then
    ParkBall(state)
    return
  end
  local ball = state.ball
  local distance = math.max(math.abs(ball.vx), math.abs(ball.vy)) * dt
  local steps = math.max(1, math.ceil(distance / ball.r))
  local stepDt = dt / steps
  for _ = 1, steps do
    ball.x = ball.x + ball.vx * stepDt
    ball.y = ball.y + ball.vy * stepDt
    BounceOffWalls(state)
    if BounceOffBricks(state) and state.bricksLeft == 0 then
      state.mode = "won"
      return
    end
    BounceOffPaddle(state)
    if ball.y - ball.r > state.h then
      LoseLife(state)
      return
    end
  end
end
