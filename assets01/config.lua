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
	y_position = -0.7  -- Lower on screen for more gameplay area
}

-- Ball configuration
config.ball = {
	radius = 0.03,
	initial_speed = 2.0,  -- Increased from 1.0 to test high-speed collision
	max_speed = 4.0,      -- Increased from 2.5 to test max speed scenarios
	speed_increase = 1.1  -- Increased from 1.05 for more aggressive speed increase
}

-- Brick configuration
config.bricks = {
	rows = 5,
	cols = 10,
	width = 0.15,
	height = 0.06,  -- Taller bricks (4x taller than before)
	spacing = 0.005,  -- Even tighter spacing to test collision accuracy
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