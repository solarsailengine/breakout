-- Global game state that all scripts can access
local game_state = {
	paddle_script = nil,
	ball_script = nil,
	game_controller_script = nil,
	bricks = {}
}

return game_state