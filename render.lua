-- Renderer: turns a game state into an SVG document string.
-- Pure Lua: no Q-SYS APIs, so it loads in the test runner.
Render = {}

SvgOpen = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1280 800" width="1280" height="800">'
  .. '<rect width="1280" height="800" fill="#1b1f27"/>'
SvgClose = '</svg>'

BrickCache = { state = nil, version = nil, svg = "" }

--[[ Summary:
    Builds the brick layer: a rounded rect and a centred label for
    every live brick. The result is cached and only rebuilt when a
    brick breaks (state.bricksVersion changes) or the state changes.
    Params:  state (table) - game state
    Returns: layer (string) - SVG fragment
]]
function Render.Bricks(state)
  if BrickCache.state == state and BrickCache.version == state.bricksVersion then
    return BrickCache.svg
  end
  local parts = { '<g font-family="sans-serif" font-size="24" fill="#ffffff" text-anchor="middle">' }
  for _, brick in ipairs(state.bricks) do
    if brick.alive then
      parts[#parts + 1] = string.format('<rect x="%d" y="%d" width="%d" height="%d" rx="8" fill="%s"/>',
        brick.x, brick.y, brick.w, brick.h, brick.color)
      if brick.label ~= "" then
        parts[#parts + 1] = string.format('<text x="%d" y="%d">%s</text>',
          math.floor(brick.x + brick.w / 2), math.floor(brick.y + brick.h / 2 + 8), brick.label)
      end
    end
  end
  parts[#parts + 1] = '</g>'
  BrickCache.state = state
  BrickCache.version = state.bricksVersion
  BrickCache.svg = table.concat(parts)
  return BrickCache.svg
end

-- Score, high score and lives along the bottom edge, under the paddle
function Render.Hud(state)
  return string.format('<g font-family="sans-serif" font-size="22" fill="#9aa4b5">'
    .. '<text x="20" y="790">Score %d</text>'
    .. '<text x="640" y="790" text-anchor="middle">Best %d</text>'
    .. '<text x="1260" y="790" text-anchor="end">Lives %d</text></g>',
    math.floor(state.score), math.floor(state.highScore), math.floor(state.lives))
end

OverlayText = {
  paused = { "PAUSED", "Press Pause to carry on" },
  won = { "YOU WIN", "Tap to play again" },
  lost = { "GAME OVER", "Tap to play again" }
}

--[[ Summary:
    Builds the text drawn over the playfield: a launch hint while the
    ball waits on the paddle, or a dimmed screen with a title when the
    game is paused, won or lost. Empty while playing.
    Params:  state (table) - game state
    Returns: overlay (string) - SVG fragment
]]
function Render.Overlay(state)
  if state.mode == "ready" then
    return '<text x="640" y="600" font-family="sans-serif" font-size="32" fill="#9aa4b5"'
      .. ' text-anchor="middle">Tap to launch</text>'
  end
  local text = OverlayText[state.mode]
  if not text then return "" end
  return '<rect width="1280" height="800" fill="#000000" fill-opacity="0.6"/>'
    .. '<g font-family="sans-serif" fill="#ffffff" text-anchor="middle">'
    .. '<text x="640" y="400" font-size="110">' .. text[1] .. '</text>'
    .. '<text x="640" y="470" font-size="36">' .. text[2] .. '</text></g>'
end

function Render.Frame(state)
  local ball, paddle = state.ball, state.paddle
  return table.concat({
    SvgOpen,
    Render.Bricks(state),
    Render.Hud(state),
    string.format('<rect x="%.1f" y="%d" width="%d" height="%d" rx="6" fill="#4da3ff"/>',
      paddle.x - paddle.w / 2, paddle.y, paddle.w, paddle.h),
    string.format('<circle cx="%.1f" cy="%.1f" r="%d" fill="#ffffff"/>', ball.x, ball.y, ball.r),
    Render.Overlay(state),
    SvgClose
  })
end
