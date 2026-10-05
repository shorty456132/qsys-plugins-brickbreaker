-- Frames drawn per second; the Core's control engine tops out at 30
table.insert(props, {
  Name = "Frame Rate",
  Type = "integer",
  Min = 10,
  Max = 30,
  Value = 20
})

-- Balls per game
table.insert(props, {
  Name = "Lives",
  Type = "integer",
  Min = 1,
  Max = 9,
  Value = 3
})
