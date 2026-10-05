local T = {}

-- Two 200x80 bricks side by side: x 300..500 and x 700..900, y 200..280
local function TwoBrickLevel()
  return {
    W = 1280,
    H = 800,
    Bricks = {
      { x = 300, y = 200, w = 200, h = 80, label = "One", kind = "source", color = "#123456" },
      { x = 700, y = 200, w = 200, h = 80, label = "Two", kind = "source", color = "#123456" }
    }
  }
end

local function NewPlaying(opts)
  local s = Game.New(TwoBrickLevel(), opts or {})
  Game.Launch(s)
  return s
end

-- Sends the ball straight up into the underside of the brick centred on x
local function BreakBrickAt(s, x)
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = x, 295, 0, -400
  Game.Step(s, 0.02, {})
end

local function LoseBall(s)
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 1200, s.h - 5, 0, 400
  for _ = 1, 10 do Game.Step(s, 0.05, {}) end
end

function T.breaking_some_bricks_keeps_the_game_playing()
  local s = NewPlaying()
  BreakBrickAt(s, 400)
  assert(s.mode == "playing", "mode should still be playing, got " .. s.mode)
end

function T.breaking_the_last_brick_wins()
  local s = NewPlaying()
  BreakBrickAt(s, 400)
  BreakBrickAt(s, 800)
  assert(s.mode == "won", "mode should be won, got " .. s.mode)
end

function T.nothing_moves_after_winning()
  local s = NewPlaying()
  BreakBrickAt(s, 400)
  BreakBrickAt(s, 800)
  local x, y, paddleX = s.ball.x, s.ball.y, s.paddle.x
  Game.Step(s, 0.05, { left = true })
  assert(s.ball.x == x and s.ball.y == y, "ball should not move after the win")
  assert(s.paddle.x == paddleX, "paddle should not move after the win")
end

function T.reset_restores_bricks_score_and_lives()
  local s = NewPlaying({ lives = 5 })
  BreakBrickAt(s, 400)
  LoseBall(s)
  assert(s.lives == 4 and s.score == 10, "setup: expected 4 lives and 10 points")
  local version = s.bricksVersion
  Game.Reset(s)
  assert(s.bricks[1].alive and s.bricks[2].alive, "both bricks should be back")
  assert(s.score == 0, "score should be 0, got " .. s.score)
  assert(s.lives == 5, "lives should be back to 5, got " .. s.lives)
  assert(s.mode == "ready", "mode should be ready, got " .. s.mode)
  assert(s.bricksVersion > version, "bricksVersion should move on so the brick layer redraws")
  assert(s.ball.x == s.paddle.x and s.ball.y == s.paddle.y - s.ball.r, "ball should be on the paddle")
end

function T.reset_after_losing_starts_a_playable_game()
  local s = NewPlaying({ lives = 1 })
  LoseBall(s)
  assert(s.mode == "lost", "setup: expected lost")
  Game.Reset(s)
  Game.Launch(s)
  assert(s.mode == "playing", "should be able to launch after a reset")
  BreakBrickAt(s, 400)
  BreakBrickAt(s, 800)
  assert(s.mode == "won", "a reset game should be winnable, got " .. s.mode)
end

function T.high_score_follows_the_score_up()
  local s = NewPlaying()
  assert(s.highScore == 0, "high score should start at 0")
  BreakBrickAt(s, 400)
  assert(s.highScore == 10, "high score should be 10, got " .. s.highScore)
end

function T.high_score_survives_a_reset_and_never_goes_down()
  local s = NewPlaying()
  BreakBrickAt(s, 400)
  BreakBrickAt(s, 800)
  Game.Reset(s)
  assert(s.highScore == 20, "high score should stay 20 after a reset, got " .. s.highScore)
  Game.Launch(s)
  BreakBrickAt(s, 400)
  assert(s.score == 10 and s.highScore == 20, "a lower score should not lower the high score")
end

function T.new_game_can_start_from_a_saved_high_score()
  local s = NewPlaying({ highScore = 500 })
  BreakBrickAt(s, 400)
  assert(s.highScore == 500, "high score should stay 500, got " .. s.highScore)
end

function T.pause_freezes_the_ball_and_paddle()
  local s = NewPlaying()
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 600, 500, 200, -200
  Game.SetPaused(s, true)
  assert(s.mode == "paused", "mode should be paused, got " .. s.mode)
  local paddleX = s.paddle.x
  Game.Step(s, 0.05, { right = true, paddlePos = 0 })
  assert(s.ball.x == 600 and s.ball.y == 500, "ball should not move while paused")
  assert(s.paddle.x == paddleX, "paddle should not move while paused")
end

function T.resume_carries_on_where_it_stopped()
  local s = NewPlaying()
  s.ball.x, s.ball.y, s.ball.vx, s.ball.vy = 600, 500, 200, -200
  Game.SetPaused(s, true)
  Game.SetPaused(s, false)
  assert(s.mode == "playing", "mode should be playing, got " .. s.mode)
  Game.Step(s, 0.05, {})
  assert(s.ball.x == 610 and s.ball.y == 490, "ball should continue on its path")
end

function T.pausing_before_launch_resumes_to_ready()
  local s = Game.New(TwoBrickLevel(), {})
  Game.SetPaused(s, true)
  assert(s.mode == "paused", "mode should be paused")
  Game.Launch(s)
  assert(s.mode == "paused", "launch should do nothing while paused")
  Game.SetPaused(s, false)
  assert(s.mode == "ready", "mode should be back to ready, got " .. s.mode)
end

function T.pause_does_nothing_once_the_game_is_over()
  local s = NewPlaying({ lives = 1 })
  LoseBall(s)
  Game.SetPaused(s, true)
  assert(s.mode == "lost", "mode should stay lost, got " .. s.mode)
  Game.SetPaused(s, false)
  assert(s.mode == "lost", "mode should stay lost, got " .. s.mode)
end

function T.tap_launches_from_ready()
  local s = Game.New(TwoBrickLevel(), {})
  Game.Tap(s)
  assert(s.mode == "playing", "tap should launch, got " .. s.mode)
end

function T.tap_does_nothing_while_playing_or_paused()
  local s = NewPlaying()
  BreakBrickAt(s, 400)
  Game.Tap(s)
  assert(s.mode == "playing" and s.score == 10, "tap while playing should change nothing")
  Game.SetPaused(s, true)
  Game.Tap(s)
  assert(s.mode == "paused" and s.score == 10, "tap while paused should change nothing")
end

function T.tap_starts_a_new_game_after_losing_or_winning()
  local s = NewPlaying({ lives = 1 })
  LoseBall(s)
  Game.Tap(s)
  assert(s.mode == "ready" and s.lives == 1, "tap after losing should reset")
  Game.Launch(s)
  BreakBrickAt(s, 400)
  BreakBrickAt(s, 800)
  Game.Tap(s)
  assert(s.mode == "ready" and s.score == 0 and s.bricks[1].alive, "tap after winning should reset")
end

function T.frame_shows_score_best_and_lives()
  local s = NewPlaying({ lives = 4, highScore = 70 })
  BreakBrickAt(s, 400)
  local svg = Render.Frame(s)
  assert(svg:find(">Score 10<", 1, true), "score not drawn")
  assert(svg:find(">Best 70<", 1, true), "high score not drawn")
  assert(svg:find(">Lives 4<", 1, true), "lives not drawn")
  assert(IsWellFormedXml(svg), "frame is not well-formed XML")
end

function T.ready_frame_shows_the_launch_hint()
  local svg = Render.Frame(Game.New(TwoBrickLevel(), {}))
  assert(svg:find(">Tap to launch<", 1, true), "launch hint not drawn")
end

function T.playing_frame_has_no_overlay()
  local svg = Render.Frame(NewPlaying())
  assert(not svg:find("Tap to launch", 1, true), "launch hint should go once playing")
  assert(not svg:find("PAUSED", 1, true) and not svg:find("GAME OVER", 1, true)
    and not svg:find("YOU WIN", 1, true), "no overlay expected while playing")
end

function T.paused_frame_says_paused()
  local s = NewPlaying()
  Game.SetPaused(s, true)
  local svg = Render.Frame(s)
  assert(svg:find(">PAUSED<", 1, true), "PAUSED not drawn")
  assert(IsWellFormedXml(svg), "frame is not well-formed XML")
end

function T.lost_frame_says_game_over()
  local s = NewPlaying({ lives = 1 })
  LoseBall(s)
  local svg = Render.Frame(s)
  assert(svg:find(">GAME OVER<", 1, true), "GAME OVER not drawn")
  assert(svg:find(">Tap to play again<", 1, true), "replay hint not drawn")
  assert(IsWellFormedXml(svg), "frame is not well-formed XML")
end

function T.won_frame_says_you_win()
  local s = NewPlaying()
  BreakBrickAt(s, 400)
  BreakBrickAt(s, 800)
  local svg = Render.Frame(s)
  assert(svg:find(">YOU WIN<", 1, true), "YOU WIN not drawn")
  assert(svg:find(">Tap to play again<", 1, true), "replay hint not drawn")
  assert(IsWellFormedXml(svg), "frame is not well-formed XML")
end

function T.full_level_frames_stay_under_8_kb_in_every_mode()
  local s = Game.New(Level, {})
  for _, mode in ipairs({ "ready", "playing", "paused", "won", "lost" }) do
    s.mode = mode
    local svg = Render.Frame(s)
    assert(#svg < 8192, mode .. " frame is " .. #svg .. " bytes")
  end
end

return T
