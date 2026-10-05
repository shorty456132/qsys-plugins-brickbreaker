local CurrentPage = PageNames[props["page_index"].Value]

if CurrentPage == "Game" then
  -- Plugin background
  table.insert(graphics, {
    Type = "GroupBox",
    Fill = { 35, 35, 35 },
    StrokeColor = { 35, 35, 35 },
    StrokeWidth = 0,
    CornerRadius = 0,
    Position = { 0, 0 },
    Size = { 680, 685 },
    ZOrder = -10
  })

  -- Playfield section
  table.insert(graphics, {
    Type = "GroupBox",
    Text = "Playfield (tap to launch, drag the strip to move the paddle)",
    Fill = { 55, 55, 55 },
    Color = { 221, 221, 221 },
    StrokeColor = { 80, 80, 80 },
    StrokeWidth = 1,
    CornerRadius = 8,
    Font = "Roboto",
    FontSize = 11,
    Position = { 10, 10 },
    Size = { 660, 475 },
    ZOrder = -5
  })

  -- Half-size view of the 1280x800 playfield; stretch it to full size on a UCI
  layout["Screen"] = {
    PrettyName = "Game~Screen",
    Style = "Button",
    ButtonStyle = "Trigger",
    ButtonVisualStyle = "Flat",
    Position = { 20, 35 },
    Size = { 640, 400 },
    Color = { 27, 31, 39 },
    CornerRadius = 4
  }

  -- Same width as Screen so the fader thumb tracks the paddle
  layout["Paddle"] = {
    PrettyName = "Game~Paddle",
    Style = "Fader",
    Position = { 20, 440 },
    Size = { 640, 36 },
    Color = { 77, 163, 255 },
    ShowTextbox = false
  }

  -- Controls section
  table.insert(graphics, {
    Type = "GroupBox",
    Text = "Controls",
    Fill = { 55, 55, 55 },
    Color = { 221, 221, 221 },
    StrokeColor = { 80, 80, 80 },
    StrokeWidth = 1,
    CornerRadius = 8,
    Font = "Roboto",
    FontSize = 11,
    Position = { 10, 495 },
    Size = { 660, 90 },
    ZOrder = -5
  })

  layout["Left"] = {
    PrettyName = "Game~Paddle Left",
    Style = "Button",
    ButtonStyle = "Momentary",
    ButtonVisualStyle = "Flat",
    Position = { 20, 520 },
    Size = { 80, 24 },
    Color = { 0, 120, 215 },
    OffColor = { 80, 80, 80 },
    UnlinkOffColor = true,
    Legend = "Left",
    FontSize = 12,
    CornerRadius = 4
  }

  layout["Right"] = {
    PrettyName = "Game~Paddle Right",
    Style = "Button",
    ButtonStyle = "Momentary",
    ButtonVisualStyle = "Flat",
    Position = { 105, 520 },
    Size = { 80, 24 },
    Color = { 0, 120, 215 },
    OffColor = { 80, 80, 80 },
    UnlinkOffColor = true,
    Legend = "Right",
    FontSize = 12,
    CornerRadius = 4
  }

  table.insert(graphics, {
    Type = "Label",
    Text = "Score",
    Color = { 200, 200, 200 },
    Font = "Roboto",
    FontSize = 11,
    HTextAlign = "Right",
    Position = { 195, 520 },
    Size = { 50, 24 }
  })

  layout["Score"] = {
    PrettyName = "Game~Score",
    Style = "Text",
    Position = { 250, 520 },
    Size = { 150, 24 },
    FontSize = 11,
    Color = { 255, 255, 255 },
    CornerRadius = 4,
    IsReadOnly = true
  }

  table.insert(graphics, {
    Type = "Label",
    Text = "Lives",
    Color = { 200, 200, 200 },
    Font = "Roboto",
    FontSize = 11,
    HTextAlign = "Right",
    Position = { 450, 520 },
    Size = { 50, 24 }
  })

  layout["Lives"] = {
    PrettyName = "Game~Lives",
    Style = "Text",
    Position = { 505, 520 },
    Size = { 150, 24 },
    FontSize = 11,
    Color = { 255, 255, 255 },
    CornerRadius = 4,
    IsReadOnly = true
  }

  layout["Start"] = {
    PrettyName = "Game~Start",
    Style = "Button",
    ButtonStyle = "Trigger",
    ButtonVisualStyle = "Flat",
    Position = { 20, 550 },
    Size = { 80, 24 },
    Color = { 0, 180, 80 },
    Legend = "New Game",
    FontSize = 12,
    CornerRadius = 4
  }

  layout["Pause"] = {
    PrettyName = "Game~Pause",
    Style = "Button",
    ButtonStyle = "Toggle",
    ButtonVisualStyle = "Flat",
    Position = { 105, 550 },
    Size = { 80, 24 },
    Color = { 230, 160, 0 },
    OffColor = { 80, 80, 80 },
    UnlinkOffColor = true,
    Legend = "Pause",
    FontSize = 12,
    CornerRadius = 4
  }

  table.insert(graphics, {
    Type = "Label",
    Text = "Best",
    Color = { 200, 200, 200 },
    Font = "Roboto",
    FontSize = 11,
    HTextAlign = "Right",
    Position = { 195, 550 },
    Size = { 50, 24 }
  })

  layout["HighScore"] = {
    PrettyName = "Game~High Score",
    Style = "Text",
    Position = { 250, 550 },
    Size = { 150, 24 },
    FontSize = 11,
    Color = { 255, 255, 255 },
    CornerRadius = 4,
    IsReadOnly = true
  }

  table.insert(graphics, {
    Type = "Label",
    Text = "State",
    Color = { 200, 200, 200 },
    Font = "Roboto",
    FontSize = 11,
    HTextAlign = "Right",
    Position = { 450, 550 },
    Size = { 50, 24 }
  })

  layout["GameState"] = {
    PrettyName = "Game~State",
    Style = "Text",
    Position = { 505, 550 },
    Size = { 150, 24 },
    FontSize = 11,
    Color = { 255, 255, 255 },
    CornerRadius = 4,
    IsReadOnly = true
  }

  -- Diagnostics section
  table.insert(graphics, {
    Type = "GroupBox",
    Text = "Diagnostics",
    Fill = { 55, 55, 55 },
    Color = { 221, 221, 221 },
    StrokeColor = { 80, 80, 80 },
    StrokeWidth = 1,
    CornerRadius = 8,
    Font = "Roboto",
    FontSize = 11,
    Position = { 10, 595 },
    Size = { 660, 60 },
    ZOrder = -5
  })

  table.insert(graphics, {
    Type = "Label",
    Text = "Frame rate",
    Color = { 200, 200, 200 },
    Font = "Roboto",
    FontSize = 11,
    HTextAlign = "Right",
    Position = { 20, 620 },
    Size = { 80, 24 }
  })

  layout["Fps"] = {
    PrettyName = "Diagnostics~Frame Rate",
    Style = "Text",
    Position = { 105, 620 },
    Size = { 150, 24 },
    FontSize = 11,
    Color = { 255, 255, 255 },
    CornerRadius = 4,
    IsReadOnly = true
  }

  -- Build version
  table.insert(graphics, {
    Type = "Label",
    Text = "v" .. PluginInfo.BuildVersion,
    Color = { 150, 150, 150 },
    Font = "Roboto",
    FontSize = 10,
    HTextAlign = "Left",
    Position = { 10, 660 },
    Size = { 150, 20 }
  })
end
