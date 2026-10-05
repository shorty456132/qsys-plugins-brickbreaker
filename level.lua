-- Playfield size and brick table (the touch panel main page elements).
-- Pure Lua: no Q-SYS APIs, so it loads in the test runner.
Level = {
  W = 1280,
  H = 800,
  Bricks = {}
}

function AddBrick(x, y, w, h, label, kind, color)
  table.insert(Level.Bricks, { x = x, y = y, w = w, h = h, label = label, kind = kind, color = color })
end

-- Header row: room name, clock, setup
AddBrick(20, 20, 600, 60, "Conference Room", "header", "#2a3140")
AddBrick(1000, 20, 160, 60, "10:42 AM", "header", "#2a3140")
AddBrick(1180, 20, 80, 60, "Setup", "header", "#4a4f5c")

-- Source row and room row: six 190 px buttons each, 20 px apart
SourceLabels = { "Laptop", "HDMI", "Wireless", "PC", "Camera", "Blu-ray" }
RoomLabels = { "Display On", "Display Off", "Screen Up", "Screen Down", "Lights", "Shades" }
for i = 1, 6 do
  AddBrick(20 + 210 * (i - 1), 110, 190, 90, SourceLabels[i], "source", "#2d5d8c")
  AddBrick(20 + 210 * (i - 1), 220, 190, 90, RoomLabels[i], "room", "#3d4a63")
end

-- Volume strip: down, ten level segments (green, amber, red like a meter), up, mute
AddBrick(20, 340, 100, 60, "Vol -", "volume", "#4a4f5c")
for i = 1, 10 do
  local color = (i == 10) and "#c0392b" or (i >= 8) and "#d4a017" or "#3fae5a"
  AddBrick(135 + 65 * (i - 1), 340, 55, 60, "", "segment", color)
end
AddBrick(790, 340, 100, 60, "Vol +", "volume", "#4a4f5c")
AddBrick(910, 340, 100, 60, "Mute", "mute", "#b0443c")

-- Power: wide enough for its label
AddBrick(1030, 340, 230, 60, "System Off", "power", "#c0392b")
