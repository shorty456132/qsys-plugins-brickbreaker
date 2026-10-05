-- The playfield: each frame's SVG is drawn onto this button
table.insert(ctrls, {
  Name = "Screen",
  ControlType = "Button",
  ButtonType = "Trigger",
  Count = 1,
  UserPin = false,
  PinStyle = "None"
})

-- Paddle position, 0 (left wall) to 1 (right wall); laid out as a horizontal fader
table.insert(ctrls, {
  Name = "Paddle",
  ControlType = "Knob",
  ControlUnit = "Float",
  Min = 0,
  Max = 1,
  Count = 1,
  UserPin = true,
  PinStyle = "Both"
})

-- Paddle moves while either button is held
table.insert(ctrls, {
  Name = "Left",
  ControlType = "Button",
  ButtonType = "Momentary",
  Count = 1,
  UserPin = true,
  PinStyle = "Both"
})
table.insert(ctrls, {
  Name = "Right",
  ControlType = "Button",
  ButtonType = "Momentary",
  Count = 1,
  UserPin = true,
  PinStyle = "Both"
})

-- New game
table.insert(ctrls, {
  Name = "Start",
  ControlType = "Button",
  ButtonType = "Trigger",
  Count = 1,
  UserPin = true,
  PinStyle = "Both"
})
table.insert(ctrls, {
  Name = "Pause",
  ControlType = "Button",
  ButtonType = "Toggle",
  Count = 1,
  UserPin = true,
  PinStyle = "Both"
})

table.insert(ctrls, {
  Name = "HighScore",
  ControlType = "Indicator",
  IndicatorType = "Text",
  Count = 1,
  UserPin = true,
  PinStyle = "Output"
})

-- Ready, Playing, Paused, You win or Game over
table.insert(ctrls, {
  Name = "GameState",
  ControlType = "Indicator",
  IndicatorType = "Text",
  Count = 1,
  UserPin = true,
  PinStyle = "Output"
})

table.insert(ctrls, {
  Name = "Score",
  ControlType = "Indicator",
  IndicatorType = "Text",
  Count = 1,
  UserPin = true,
  PinStyle = "Output"
})

table.insert(ctrls, {
  Name = "Lives",
  ControlType = "Indicator",
  IndicatorType = "Text",
  Count = 1,
  UserPin = true,
  PinStyle = "Output"
})

-- Measured frame rate and frame size
table.insert(ctrls, {
  Name = "Fps",
  ControlType = "Indicator",
  IndicatorType = "Text",
  Count = 1,
  UserPin = true,
  PinStyle = "Output"
})
