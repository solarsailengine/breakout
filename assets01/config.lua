-- Breakout Game Configuration
local config = {}

-- Screen boundaries in world coordinates
config.BOUND_X = 1.78  -- 16:9 aspect ratio
config.BOUND_Y = 1.0   -- Normalized height

-- Game area (slightly inset from screen bounds)
config.PLAY_AREA = {
	left = -1.6,
	right = 1.6,
	top = 0.9,
	bottom = -0.9
}

-- Paddle configuration
config.paddle = {
	width = 0.3,
	height = 0.05,
	speed = 2.0,  -- World units per second
	y_position = -0.1  -- Near bottom of screen
}

-- Ball configuration
config.ball = {
	radius = 0.03,
	initial_speed = 1.0,
	max_speed = 2.5,
	speed_increase = 1.05  -- Multiply speed by this on paddle hit
}

-- Brick configuration
config.bricks = {
	rows = 5,
	cols = 10,
	width = 0.15,
	height = 0.06,  -- Taller bricks (4x taller than before)
	spacing = 0.01,  -- Tighter spacing for taller bricks
	start_y = 0.5,  -- Adjusted for tighter spacing
	colors = {
		{1.0, 0.2, 0.2, 1.0},  -- Red (top row, most points)
		{1.0, 0.6, 0.2, 1.0},  -- Orange
		{1.0, 1.0, 0.2, 1.0},  -- Yellow
		{0.2, 1.0, 0.2, 1.0},  -- Green
		{0.2, 0.2, 1.0, 1.0}   -- Blue (bottom row, least points)
	},
	points = {50, 40, 30, 20, 10}  -- Points per row
}

-- Visual configuration
config.visual = {
	paddle_scale = 1.0,
	ball_scale = 1.0,
	brick_scale = 1.0
}

-- Game settings
config.game = {
	lives = 3,
	initial_bricks = config.bricks.rows * config.bricks.cols
}

return config