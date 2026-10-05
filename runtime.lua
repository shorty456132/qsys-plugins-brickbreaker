-- Brick Breaker
-- Plays Brick Breaker on an SVG that is redrawn onto the Screen button every frame.
-- Dependencies: none

--*** Constants ***
rapidjson = require("rapidjson")
FrameRate = Properties["Frame Rate"].Value
FrameTime = 1 / FrameRate
StartLives = Properties["Lives"].Value
ModeNames = {
  ready = "Ready",
  playing = "Playing",
  paused = "Paused",
  won = "You win",
  lost = "Game over"
}

--[[ #include "level.lua" ]]
--[[ #include "game.lua" ]]
--[[ #include "render.lua" ]]

--*** Globals ***
-- The high score is picked up from its indicator in case the Core kept it from the last run
State = Game.New(Level, {
  lives = StartLives,
  highScore = tonumber(Controls["HighScore"].String) or 0
})
FrameTimer = Timer.New()
FpsTimer = Timer.New()
FrameCount = 0
FrameBytes = 0
PaddleSeen = nil     -- fader position at the last frame, to detect a drag
Shown = {}           -- last text written to each indicator, by control name
Armed = false        -- ignores the handler calls Q-SYS makes while the script loads

--*** Helper Functions ***
-- Renders the current state and pushes it to the Screen button as a base64 SVG
function DrawFrame()
  local svg = Render.Frame(State)
  FrameBytes = #svg
  Controls["Screen"].Legend = rapidjson.encode({
    DrawChrome = false,
    IconData = Crypto.Base64Encode(svg)
  })
end

--[[ Summary:
    Collects this frame's paddle input. The fader is polled rather
    than handled by event so that it only counts as input when its
    position actually changed since the last frame.
    Returns: input (table) - paddlePos (0..1 or nil), left, right
]]
function ReadInput()
  local input = {
    left = Controls["Left"].Boolean,
    right = Controls["Right"].Boolean
  }
  local position = Controls["Paddle"].Position
  if position ~= PaddleSeen then
    PaddleSeen = position
    input.paddlePos = position
  end
  return input
end

-- Moves the fader thumb to match the paddle after the buttons moved it
function SyncPaddleFader()
  Controls["Paddle"].Position = Game.PaddlePos(State)
  PaddleSeen = Controls["Paddle"].Position
end

-- Makes the Pause button show whether the game is actually paused
function SyncPauseButton()
  Controls["Pause"].Boolean = (State.mode == "paused")
end

-- Writes an indicator only when its text changed
function ShowText(name, text)
  if Shown[name] ~= text then
    Shown[name] = text
    Controls[name].String = text
  end
end

function UpdateIndicators()
  ShowText("Lives", tostring(math.floor(State.lives)))
  ShowText("Score", tostring(math.floor(State.score)))
  ShowText("HighScore", tostring(math.floor(State.highScore)))
  ShowText("GameState", ModeNames[State.mode])
end

--*** Event Handlers ***
FrameTimer.EventHandler = function()
  local input = ReadInput()
  Game.Step(State, FrameTime, input)
  if input.left or input.right then SyncPaddleFader() end
  UpdateIndicators()
  DrawFrame()
  FrameCount = FrameCount + 1
end

-- Once a second, report how many frames the Core actually drew
FpsTimer.EventHandler = function()
  Controls["Fps"].String = string.format("%d fps, %.1f KB", FrameCount, FrameBytes / 1024)
  FrameCount = 0
end

-- Launches the ball, or starts a new game once this one is won or lost
Controls["Screen"].EventHandler = function()
  if not Armed then return end
  Game.Tap(State)
  SyncPauseButton()
end

Controls["Start"].EventHandler = function()
  if not Armed then return end
  Game.Reset(State)
  SyncPauseButton()
end

Controls["Pause"].EventHandler = function(ctl)
  Game.SetPaused(State, ctl.Boolean)
  SyncPauseButton()
end

--*** Initialization ***
SyncPaddleFader()
SyncPauseButton()
UpdateIndicators()
DrawFrame()
FrameTimer:Start(FrameTime)
FpsTimer:Start(1)
Timer.CallAfter(function() Armed = true end, 0.5)
